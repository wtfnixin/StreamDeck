import { AppLauncher, WebsiteShortcut } from './launcher';
import { Workspace } from './workspace';

export interface PairingRequestPayload {
  deviceId: string;
  deviceName: string;
  pairingToken: string;
}

export interface PairingResponsePayload {
  success: boolean;
  token?: string;
  error?: string;
}

export interface LaunchAppPayload {
  id: string;
}

export interface LaunchWebsitePayload {
  id: string;
}

export interface ClipboardSyncPayload {
  id: string;
  content: string;
  source: 'mobile' | 'desktop';
  timestamp: number;
}

export interface ExecuteWorkspacePayload {
  id: string;
}

export interface GestureTriggerPayload {
  gestureType: 'swipe_left' | 'swipe_right' | 'swipe_up' | 'swipe_down' | 'double_tap' | 'long_press';
}

export interface SettingPayload {
  key: string;
  value: string;
}
