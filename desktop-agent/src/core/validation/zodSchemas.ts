import { z } from 'zod';

export const websiteShortcutSchema = z.object({
  id: z.string().uuid().or(z.string().min(1)),
  name: z.string().min(1, 'Name is required').max(100),
  url: z.string().url('Invalid website URL'),
  icon: z.string().nullable().optional(),
});

export const appLauncherSchema = z.object({
  id: z.string().uuid().or(z.string().min(1)),
  name: z.string().min(1, 'Name is required').max(100),
  icon: z.string().nullable().optional(),
  executablePath: z.string().min(1, 'Executable path is required'),
  category: z.string().nullable().optional(),
});

export const workspaceActionSchema = z.object({
  id: z.string().uuid().or(z.string().min(1)),
  workspaceId: z.string().uuid().or(z.string().min(1)),
  actionType: z.enum(['launch_app', 'launch_website', 'run_command']),
  payload: z.string().min(1, 'Payload is required'),
  sequenceOrder: z.number().int().nonnegative(),
});

export const workspaceSchema = z.object({
  id: z.string().uuid().or(z.string().min(1)),
  name: z.string().min(1, 'Name is required').max(100),
  icon: z.string().nullable().optional(),
  description: z.string().nullable().optional(),
  actions: z.array(workspaceActionSchema).optional(),
});

export const pairingRequestSchema = z.object({
  deviceId: z.string().min(1, 'Device ID is required'),
  deviceName: z.string().min(1, 'Device Name is required'),
  pairingToken: z.string().min(1, 'Pairing token is required'),
});

export const gestureActionSchema = z.object({
  id: z.string().uuid().or(z.string().min(1)),
  gestureType: z.enum(['swipe_left', 'swipe_right', 'swipe_up', 'swipe_down', 'double_tap', 'long_press']),
  actionType: z.enum(['keyboard_shortcut', 'run_command', 'launch_workspace']),
  payload: z.string().min(1, 'Payload is required'),
});
