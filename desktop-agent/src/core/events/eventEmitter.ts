import { EventEmitter } from 'events';

class AppEventEmitter extends EventEmitter {}

export const appEvents = new AppEventEmitter();

export const EVENTS = {
  CLIPBOARD_UPDATED: 'clipboard:updated',
  DEVICE_CONNECTED: 'device:connected',
  DEVICE_DISCONNECTED: 'device:disconnected',
  PAIRING_REQUEST: 'pairing:request',
};
