import { exec, spawn } from 'child_process';
import { logger } from '../core/logger/winston';
import { Server } from 'socket.io';

export class ClipboardService {
  private static ioServer: Server | null = null;
  private static lastContent: string = '';
  private static pollInterval: NodeJS.Timeout | null = null;

  public static init(io: Server): void {
    this.ioServer = io;
    this.paste((error, content) => {
      if (error) {
        logger.warn('Failed to initialize clipboard content:', error);
        this.lastContent = '';
      } else {
        this.lastContent = content || '';
      }
      this.startPolling();
    });
  }

  private static paste(callback: (error: any, content: string) => void): void {
    // Run PowerShell to get clipboard with UTF-8 encoding to prevent garbled characters
    const cmd = `powershell.exe -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-Clipboard"`;
    exec(cmd, { encoding: 'utf8' }, (error, stdout, stderr) => {
      if (error) {
        callback(error, '');
      } else {
        // Strip trailing newlines/carriage returns that powershell may append
        const content = stdout.replace(/\r\n$/, '').replace(/\n$/, '');
        callback(null, content);
      }
    });
  }

  private static copy(content: string, callback: (error: any) => void): void {
    // Run PowerShell to set clipboard with UTF-8 encoding
    const child = spawn('powershell.exe', [
      '-NoProfile',
      '-Command',
      '[Console]::InputEncoding = [System.Text.Encoding]::UTF8; $content = [Console]::In.ReadToEnd(); Set-Clipboard -Value $content'
    ]);

    let err = '';
    child.stderr.on('data', (data) => {
      err += data.toString();
    });

    child.on('close', (code) => {
      if (code !== 0) {
        callback(new Error(err || `Exit code ${code}`));
      } else {
        callback(null);
      }
    });

    child.stdin.write(content);
    child.stdin.end();
  }

  public static startPolling(): void {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
    }

    this.pollInterval = setInterval(() => {
      this.paste((error, currentContent) => {
        if (error) return;

        if (currentContent !== this.lastContent && currentContent.trim() !== '') {
          this.lastContent = currentContent;
          logger.info(`📋 Clipboard change detected on desktop: "${currentContent.substring(0, 30)}..."`);
          
          // Broadcast to all authenticated clients
          if (this.ioServer) {
            this.ioServer.emit('clipboard:sync', {
              content: currentContent,
              source: 'desktop',
              timestamp: Date.now(),
            });
          }
        }
      });
    }, 1000);
  }

  public static handleMobileSync(content: string): void {
    if (content === this.lastContent) return;
    
    this.lastContent = content;
    this.copy(content, (error) => {
      if (error) {
        logger.error('Failed to write clipboard to system:', error);
      } else {
        logger.info(`📋 Clipboard synced from mobile to desktop: "${content.substring(0, 30)}..."`);
      }
    });
  }

  public static stopPolling(): void {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }
  }
}
