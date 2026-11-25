[Setup]
AppName=Sahm
AppVersion=0.1.0
AppId=Sahm.LocalPortfolio
DefaultDirName={localappdata}\Programs\Sahm
PrivilegesRequired=lowest
OutputBaseFilename=Sahm-Setup
SetupIconFile=assets\app_icon.ico
[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
[Icons]
Name: "{userprograms}\Sahm"; Filename: "{app}\sahm.exe"
