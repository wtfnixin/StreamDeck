import { db } from '../core/database/connection';
import { logger } from '../core/logger/winston';
import { Workspace, WorkspaceAction } from '../types/workspace';
import { AppRegistryService } from './appRegistryService';
import { WebsiteRegistryService } from './websiteRegistryService';
import { exec } from 'child_process';
import { openUrl } from '../utils/open';
import crypto from 'crypto';

export class WorkspaceService {
  public static getAllWorkspaces(): Workspace[] {
    try {
      const workspaces = db.prepare('SELECT id, name, icon, description FROM workspaces').all() as Workspace[];
      
      for (const ws of workspaces) {
        const actions = db.prepare(
          'SELECT id, workspace_id as workspaceId, action_type as actionType, payload, sequence_order as sequenceOrder FROM workspace_actions WHERE workspace_id = ? ORDER BY sequence_order ASC'
        ).all(ws.id) as WorkspaceAction[];
        ws.actions = actions;
      }
      
      return workspaces;
    } catch (error) {
      logger.error('Failed to get workspaces:', error);
      return [];
    }
  }

  public static registerWorkspace(ws: Workspace): boolean {
    try {
      // Begin transaction
      const transaction = db.transaction(() => {
        // Insert or replace workspace
        db.prepare('INSERT OR REPLACE INTO workspaces (id, name, icon, description) VALUES (?, ?, ?, ?)')
          .run(ws.id, ws.name, ws.icon, ws.description);

        // Clear existing actions
        db.prepare('DELETE FROM workspace_actions WHERE workspace_id = ?').run(ws.id);

        // Insert new actions
        if (ws.actions && ws.actions.length > 0) {
          const insertAction = db.prepare(
            'INSERT INTO workspace_actions (id, workspace_id, action_type, payload, sequence_order) VALUES (?, ?, ?, ?, ?)'
          );
          
          ws.actions.forEach((action, index) => {
            insertAction.run(
              action.id || crypto.randomUUID(),
              ws.id,
              action.actionType,
              action.payload,
              action.sequenceOrder ?? index
            );
          });
        }
      });

      transaction();
      return true;
    } catch (error) {
      logger.error(`Failed to register workspace "${ws.name}":`, error);
      return false;
    }
  }

  public static deleteWorkspace(id: string): boolean {
    try {
      db.prepare('DELETE FROM workspaces WHERE id = ?').run(id);
      return true;
    } catch (error) {
      logger.error(`Failed to delete workspace ${id}:`, error);
      return false;
    }
  }

  public static async executeWorkspace(id: string): Promise<boolean> {
    try {
      logger.info(`🚀 Executing workspace flow: ${id}`);
      const actions = db.prepare(
        'SELECT action_type as actionType, payload FROM workspace_actions WHERE workspace_id = ? ORDER BY sequence_order ASC'
      ).all(id) as { actionType: string; payload: string }[];

      if (actions.length === 0) {
        logger.warn(`Workspace "${id}" has no actions to execute.`);
        return true;
      }

      for (const action of actions) {
        const payload = JSON.parse(action.payload);
        logger.info(`Running action step: ${action.actionType} with payload`, payload);

        try {
          switch (action.actionType) {
            case 'launch_app':
              if (payload.appId) {
                await AppRegistryService.launchApp(payload.appId);
              } else if (payload.executablePath) {
                logger.info(`Starting execution of app path: ${payload.executablePath}`);
                const command = payload.executablePath.includes(' ') && !payload.executablePath.startsWith('"')
                  ? `"${payload.executablePath}"`
                  : payload.executablePath;
                exec(command, (error) => {
                  if (error) logger.error(`Error executing app ${payload.executablePath}:`, error);
                });
              }
              break;

            case 'launch_website':
              if (payload.websiteId) {
                await WebsiteRegistryService.launchWebsite(payload.websiteId);
              } else if (payload.url) {
                logger.info(`Opening website URL: ${payload.url}`);
                await openUrl(payload.url);
              }
              break;

            case 'run_command':
              if (payload.command) {
                exec(payload.command, (err) => {
                  if (err) logger.error(`Command execution failed: ${payload.command}`, err);
                });
              }
              break;

            default:
              logger.warn(`Unknown action type: ${action.actionType}`);
          }
        } catch (stepErr) {
          logger.error(`Error executing workspace step: ${action.actionType}`, stepErr);
        }

        // Delay 500ms between execution steps to let OS process thread scheduling
        await new Promise((resolve) => setTimeout(resolve, 500));
      }

      return true;
    } catch (error) {
      logger.error(`Failed to execute workspace ${id}:`, error);
      return false;
    }
  }

  public static seedDefaults(): void {
    try {
      const count = db.prepare('SELECT count(*) as count FROM workspaces').get() as { count: number };
      if (count.count > 0) return;

      logger.info('🌱 Seeding default workspaces...');
      
      const wsId = 'default-dev-env';
      this.registerWorkspace({
        id: wsId,
        name: 'Developer Workspace',
        description: 'Launch VS Code, GitHub, and ChatGPT to start coding.',
        icon: 'code',
        actions: [
          {
            id: crypto.randomUUID(),
            workspaceId: wsId,
            actionType: 'run_command',
            payload: JSON.stringify({ command: 'code' }),
            sequenceOrder: 0,
          },
          {
            id: crypto.randomUUID(),
            workspaceId: wsId,
            actionType: 'launch_website',
            payload: JSON.stringify({ url: 'https://github.com' }),
            sequenceOrder: 1,
          },
          {
            id: crypto.randomUUID(),
            workspaceId: wsId,
            actionType: 'launch_website',
            payload: JSON.stringify({ url: 'https://chatgpt.com' }),
            sequenceOrder: 2,
          },
        ],
      });
    } catch (error) {
      logger.error('Failed to seed default workspaces:', error);
    }
  }
}
