import ncp from 'copy-paste';
import { logger } from '../core/logger/winston';
import { Server } from 'socket.io';

export class ClipboardService {
  private static ioServer: Server | null = null;
  private static lastContent: string = '';
  private static pollInterval: NodeJS.Timeout | null = null;

  public static init(io: Server): void {
    this.ioServer = io;
    ncp.paste((error, content) => {
      if (error) {
        logger.warn('Failed to initialize clipboard content:', error);
        this.lastContent = '';
      } else {
        this.lastContent = content || '';
      }
      this.startPolling();
    });
  }

  public static startPolling(): void {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
    }

    this.pollInterval = setInterval(() => {
      ncp.paste((error, currentContent) => {
        if (error || !currentContent) return;

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
    ncp.copy(content, (error) => {
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
