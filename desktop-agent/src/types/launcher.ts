export interface AppLauncher {
  id: string;
  name: string;
  icon: string | null;
  executablePath: string;
  category: string | null;
}

export interface WebsiteShortcut {
  id: string;
  name: string;
  url: string;
  icon: string | null;
}
