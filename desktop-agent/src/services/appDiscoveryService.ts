import { exec } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import { logger } from '../core/logger/winston';
import { AppRegistryService } from './appRegistryService';

export interface DiscoveredApp {
  name: string;
  executablePath: string;
  icon: string | null;
  category: string;
}

export class AppDiscoveryService {
  /**
   * Discovers currently running applications with window titles
   */
  public static async getRunningApps(): Promise<DiscoveredApp[]> {
    return new Promise((resolve) => {
      // Query processes that have a main window title
      const psCommand = `Get-Process | Where-Object { $_.MainWindowTitle } | Select-Object ProcessName, Path | ConvertTo-Json -Compress`;
      const fullCmd = `powershell -NoProfile -ExecutionPolicy Bypass -Command "${psCommand.replace(/"/g, '\\"')}"`;

      exec(fullCmd, { maxBuffer: 1024 * 1024 * 10 }, (error, stdout) => {
        if (error || !stdout) {
          logger.error('Failed to query running processes:', error);
          return resolve([]);
        }
        try {
          const parsed = JSON.parse(stdout.trim());
          const list = Array.isArray(parsed) ? parsed : [parsed];
          const runningApps: DiscoveredApp[] = [];

          for (const proc of list) {
            if (proc.Path && fs.existsSync(proc.Path)) {
              // Exclude duplicate paths, explorer, host processes, or this agent itself
              const lowerPath = proc.Path.toLowerCase();
              if (
                lowerPath.includes('explorer.exe') || 
                lowerPath.includes('devdeck') || 
                runningApps.some(app => app.executablePath.toLowerCase() === lowerPath)
              ) {
                continue;
              }

              // Extract native icon if available, else null
              const icon = AppRegistryService.extractExeIcon(proc.Path);

              runningApps.push({
                name: proc.ProcessName,
                executablePath: proc.Path,
                icon,
                category: 'Running Process',
              });
            }
          }
          resolve(runningApps);
        } catch (err) {
          logger.error('Failed to parse running processes JSON:', err);
          resolve([]);
        }
      });
    });
  }

  /**
   * Discovers installed applications from Windows Registry
   */
  public static async getInstalledApps(): Promise<DiscoveredApp[]> {
    return new Promise((resolve) => {
      // Query registry keys for App Paths
      const psCommand = `Get-ItemProperty -Path 'HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\*', 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\*' -ErrorAction SilentlyContinue | ForEach-Object { [PSCustomObject]@{ Name = $_.PSChildName; Path = $_.'(default)' } } | ConvertTo-Json -Compress`;
      const fullCmd = `powershell -NoProfile -ExecutionPolicy Bypass -Command "${psCommand.replace(/"/g, '\\"')}"`;

      exec(fullCmd, { maxBuffer: 1024 * 1024 * 10 }, (error, stdout) => {
        if (error || !stdout) {
          logger.error('Failed to query installed registry apps:', error);
          return resolve([]);
        }
        try {
          const parsed = JSON.parse(stdout.trim());
          const list = Array.isArray(parsed) ? parsed : [parsed];
          const installedApps: DiscoveredApp[] = [];

          for (const item of list) {
            if (item.Path && fs.existsSync(item.Path)) {
              const lowerPath = item.Path.toLowerCase();
              if (
                !lowerPath.endsWith('.exe') ||
                installedApps.some(app => app.executablePath.toLowerCase() === lowerPath)
              ) {
                continue;
              }

              const rawName = item.Name.replace('.exe', '');
              const friendlyName = rawName.charAt(0).toUpperCase() + rawName.slice(1);

              installedApps.push({
                name: friendlyName,
                executablePath: item.Path,
                icon: null, // Lazy-loaded or extracted on selection to keep query fast
                category: 'Installed System App',
              });
            }
          }
          resolve(installedApps);
        } catch (err) {
          logger.error('Failed to parse installed apps JSON:', err);
          resolve([]);
        }
      });
    });
  }
}
