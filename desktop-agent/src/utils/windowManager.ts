import { exec } from 'child_process';
import { logger } from '../core/logger/winston';

export class WindowManager {
  /**
   * Attempts to find a window matching a set of keywords (case-insensitive substring match),
   * restores it if minimized, and brings it to the foreground.
   * Returns true if focused successfully, false otherwise.
   */
  public static focusWindow(keywords: string[]): Promise<boolean> {
    return new Promise((resolve) => {
      // Filter out empty keywords and escape single quotes
      const cleanKeywords = keywords
        .filter(k => k && k.trim().length > 0)
        .map(k => k.replace(/'/g, "''").toLowerCase());

      if (cleanKeywords.length === 0) {
        return resolve(false);
      }

      // Build PowerShell array of keywords
      const psKeywordsArray = '@(' + cleanKeywords.map(k => `'${k}'`).join(', ') + ')';

      const psScript = `
        $keywords = ${psKeywordsArray}
        
        # Get all processes with main window titles
        $processes = Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowHandle -ne [IntPtr]::Zero }
        
        $targetProc = $null
        
        # Try matching by window title first (any of the keywords)
        foreach ($kw in $keywords) {
          $match = $processes | Where-Object { $_.MainWindowTitle.ToLower().Contains($kw) } | Select-Object -First 1
          if ($match) {
            $targetProc = $match
            break
          }
        }
        
        # If no window title match, try matching by process name
        if (-not $targetProc) {
          foreach ($kw in $keywords) {
            $match = Get-Process | Where-Object { $_.ProcessName.ToLower().Contains($kw) -and $_.MainWindowHandle -ne [IntPtr]::Zero } | Select-Object -First 1
            if ($match) {
              $targetProc = $match
              break
            }
          }
        }
        
        if ($targetProc) {
          $sig = @'
          [DllImport("user32.dll")]
          public static extern bool SetForegroundWindow(IntPtr hWnd);
          [DllImport("user32.dll")]
          public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
          [DllImport("user32.dll")]
          public static extern bool IsIconic(IntPtr hWnd);
'@
          $type = Add-Type -MemberDefinition $sig -Name "Win32Util" -Namespace "Win32" -PassThru -ErrorAction SilentlyContinue
          $hwnd = $targetProc.MainWindowHandle
          
          # If minimized, restore it
          if ([Win32.Win32Util]::IsIconic($hwnd)) {
            [Win32.Win32Util]::ShowWindowAsync($hwnd, 9) # 9 = SW_RESTORE
          }
          [Win32.Win32Util]::SetForegroundWindow($hwnd)
          Write-Output "SUCCESS"
        } else {
          Write-Output "FAIL"
        }
      `.trim();

      // Encode the PowerShell script to UTF-16LE Base64 to safely execute complex/multiline code
      const base64Script = Buffer.from(psScript, 'utf16le').toString('base64');
      const fullCmd = `powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand ${base64Script}`;

      exec(fullCmd, (error, stdout) => {
        if (!error && stdout && stdout.trim().includes('SUCCESS')) {
          resolve(true);
        } else {
          resolve(false);
        }
      });
    });
  }
}
