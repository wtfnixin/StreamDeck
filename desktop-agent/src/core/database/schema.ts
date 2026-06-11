export const SCHEMA_SQL = `
CREATE TABLE IF NOT EXISTS trusted_devices (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    paired_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_connected_at DATETIME,
    token_hash TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS apps (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    icon TEXT,
    executable_path TEXT NOT NULL,
    category TEXT
);

CREATE TABLE IF NOT EXISTS websites (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    icon TEXT
);

CREATE TABLE IF NOT EXISTS workspaces (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    icon TEXT,
    description TEXT
);

CREATE TABLE IF NOT EXISTS workspace_actions (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    action_type TEXT NOT NULL,
    payload TEXT NOT NULL,
    sequence_order INTEGER NOT NULL,
    FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS gestures (
    id TEXT PRIMARY KEY,
    gesture_type TEXT UNIQUE NOT NULL,
    action_type TEXT NOT NULL,
    payload TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS clipboard_history (
    id TEXT PRIMARY KEY,
    content TEXT NOT NULL,
    source TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
`;
