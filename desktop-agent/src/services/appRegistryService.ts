import { db } from '../core/database/connection';
import { logger } from '../core/logger/winston';
import { AppLauncher } from '../types/launcher';
import { exec, execSync } from 'child_process';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';

export class AppRegistryService {
  private static resolveExePath(exePath: string): string {
    if (path.isAbsolute(exePath) && fs.existsSync(exePath)) {
      return exePath;
    }
    
    // Check in common system directories
    const systemDirs = [
      'C:\\Windows\\System32',
      'C:\\Windows',
      'C:\\Program Files',
      'C:\\Program Files (x86)'
    ];
    
    for (const dir of systemDirs) {
      const fullPath = path.join(dir, exePath);
      if (fs.existsSync(fullPath)) {
        return fullPath;
      }
    }
    
    return exePath;
  }

  public static extractExeIcon(exePath: string): string | null {
    try {
      const resolved = this.resolveExePath(exePath);
      if (!fs.existsSync(resolved)) {
        return null;
      }
      
      const escapedPath = resolved.replace(/'/g, "''");
      const psCommand = `Add-Type -AssemblyName System.Drawing; $icon = [System.Drawing.Icon]::ExtractAssociatedIcon('${escapedPath}'); $bitmap = $icon.ToBitmap(); $stream = New-Object System.IO.MemoryStream; $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png); $bytes = $stream.ToArray(); $base64 = [Convert]::ToBase64String($bytes); write-host $base64`;
      
      const base64 = execSync(`powershell -Command "${psCommand.replace(/"/g, '\\"')}"`, { 
        encoding: 'utf8', 
        maxBuffer: 1024 * 1024 * 10 
      }).trim();
      
      if (base64 && base64.startsWith('iVBORw0KGgo')) {
        return `data:image/png;base64,${base64}`;
      }
    } catch (err) {
      logger.error(`Failed to extract icon for ${exePath}:`, err);
    }
    return null;
  }

  public static getAllApps(): AppLauncher[] {
    try {
      const rows = db.prepare('SELECT * FROM apps').all() as any[];
      return rows.map(row => {
        let icon = row.icon;
        
        // Lazy extraction & cache if not already base64
        if (!icon || !icon.startsWith('data:image/')) {
          const extracted = this.extractExeIcon(row.executable_path);
          if (extracted) {
            icon = extracted;
            try {
              db.prepare('UPDATE apps SET icon = ? WHERE id = ?').run(icon, row.id);
            } catch (err) {
              logger.error('Failed to update app icon cache in DB:', err);
            }
          }
        }

        return {
          id: row.id,
          name: row.name,
          icon: icon ?? row.icon ?? null,
          executablePath: row.executable_path,
          category: row.category ?? null,
        };
      });
    } catch (error) {
      logger.error('Failed to get apps from database:', error);
      return [];
    }
  }

  public static registerApp(app: Omit<AppLauncher, 'id'> & { id?: string }): AppLauncher {
    try {
      const id = app.id || crypto.randomUUID();
      
      // Auto-extract executable icon on registration
      let icon = app.icon;
      if (!icon || !icon.startsWith('data:image/')) {
        const extracted = this.extractExeIcon(app.executablePath);
        if (extracted) {
          icon = extracted;
        }
      }

      const stmt = db.prepare(`
        INSERT INTO apps (id, name, icon, executable_path, category)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          icon = excluded.icon,
          executable_path = excluded.executable_path,
          category = excluded.category
      `);
      stmt.run(id, app.name, icon ?? null, app.executablePath, app.category ?? null);
      
      const registeredApp: AppLauncher = {
        id,
        name: app.name,
        icon: icon ?? null,
        executablePath: app.executablePath,
        category: app.category ?? null,
      };
      
      logger.info(`🚀 App registered/updated: ${app.name} (${id})`);
      return registeredApp;
    } catch (error) {
      logger.error('Failed to register app:', error);
      throw error;
    }
  }

  public static deleteApp(id: string): void {
    try {
      const stmt = db.prepare('DELETE FROM apps WHERE id = ?');
      stmt.run(id);
      logger.info(`🗑️ App deleted: ${id}`);
    } catch (error) {
      logger.error(`Failed to delete app ${id}:`, error);
      throw error;
    }
  }

  public static launchApp(id: string): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        const row = db.prepare('SELECT name, executable_path FROM apps WHERE id = ?').get(id) as { name: string, executable_path: string } | undefined;
        if (!row) {
          logger.warn(`Attempted to launch app with unknown ID: ${id}`);
          return reject(new Error('App not found in registry'));
        }

        const name = row.name;
        const execPath = row.executable_path;
        
        // Extract executable filename without path and extension
        const execFilename = path.basename(execPath, path.extname(execPath));

        logger.info(`Attempting window activation for: ${name} / ${execFilename}`);

        // Escape single quotes for PowerShell string literal
        const escapedName = name.replace(/'/g, "''");
        const escapedFilename = execFilename.replace(/'/g, "''");

        const psCommand = `$wshell = New-Object -ComObject WScript.Shell; if ($wshell.AppActivate('${escapedName}') -or $wshell.AppActivate('${escapedFilename}')) { echo "SUCCESS" } else { echo "FAIL" }`;
        const fullCmd = `powershell -NoProfile -ExecutionPolicy Bypass -Command "${psCommand}"`;

        exec(fullCmd, (error, stdout) => {
          if (!error && stdout && stdout.trim() === 'SUCCESS') {
            logger.info(`Focused existing window for app: ${name}`);
            return resolve();
          }

          logger.info(`App window not found or couldn't focus. Launching new instance: ${execPath}`);
          const command = execPath.includes(' ') && !execPath.startsWith('"') ? `"${execPath}"` : execPath;

          exec(command, (launchError) => {
            if (launchError) {
              logger.error(`Error executing app ${execPath}:`, launchError);
              return reject(launchError);
            }
          });
          resolve();
        });
      } catch (error) {
        logger.error(`Exception during launching app ID ${id}:`, error);
        reject(error);
      }
    });
  }

  public static seedDefaults(): void {
    try {
      const countRow = db.prepare('SELECT count(*) as count FROM apps').get() as { count: number };
      if (countRow.count === 0) {
        logger.info('🌱 Seeding default apps...');
        const defaults = [
          { name: 'Notepad', executablePath: 'notepad.exe', icon: 'description', category: 'Utility' },
          { name: 'Calculator', executablePath: 'calc.exe', icon: 'calculate', category: 'Utility' },
          { name: 'Command Prompt', executablePath: 'cmd.exe', icon: 'terminal', category: 'Developer' },
          { name: 'Task Manager', executablePath: 'taskmgr.exe', icon: 'assessment', category: 'System' }
        ];
        for (const app of defaults) {
          this.registerApp(app);
        }
      }
    } catch (error) {
      logger.error('Failed to seed default apps:', error);
    }
  }
}
