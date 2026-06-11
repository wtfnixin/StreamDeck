import { exec } from 'child_process';

/**
 * Opens a URL in the host's default web browser.
 */
export function openUrl(url: string): Promise<void> {
  return new Promise((resolve, reject) => {
    // For Windows, use the 'start' command. 
    // Escape ampersands and other shell characters in URL to avoid command injection or breaks
    const escapedUrl = url.replace(/["^&]/g, (match) => `^${match}`);
    
    exec(`start "" "${escapedUrl}"`, (error) => {
      if (error) {
        reject(error);
      } else {
        resolve();
      }
    });
  });
}
