[Setup]
AppName=DevDeck Desktop Agent
AppVersion=1.0.0
DefaultDirName={userpf}\DevDeckAgent
DefaultGroupName=DevDeck
OutputDir=build
OutputBaseFilename=DevDeckAgentSetup
Compression=lzma
SolidCompression=yes
SetupIconFile=

[Files]
Source: "build\devdeck-agent.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\DevDeck Agent"; Filename: "{app}\devdeck-agent.exe"
Name: "{userstartup}\DevDeck Agent"; Filename: "{app}\devdeck-agent.exe"
