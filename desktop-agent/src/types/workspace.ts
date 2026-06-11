export type WorkspaceActionType = 'launch_app' | 'launch_website' | 'run_command';

export interface WorkspaceAction {
  id: string;
  workspaceId: string;
  actionType: WorkspaceActionType;
  payload: string; // JSON string payload
  sequenceOrder: number;
}

export interface Workspace {
  id: string;
  name: string;
  icon: string | null;
  description: string | null;
  actions?: WorkspaceAction[];
}
