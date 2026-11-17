; Inno Setup script for Cursed Survivors.
; Build:  "C:\Users\<you>\AppData\Local\Programs\Inno Setup 6\ISCC.exe" installer\CursedSurvivors.iss
; Needs a finished export at  Z:\CursedSurvivors\CursedSurvivors.exe  (see README).

#define AppName        "Cursed Survivors"
#define AppVersion     "1.0.0"
#define AppExe         "CursedSurvivors.exe"
#define BuildDir       "Z:\CursedSurvivors"
#define ProjectDir     "Z:\WIBECODING\VampireSurvivors"

[Setup]
AppId={{B3E1A7F2-5C4D-4A19-9E8B-6D0F2A7C4E31}}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Cursed Survivors
AppPublisherURL=https://dengarIicdk.github.io/cursed-survivors/
AppSupportURL=https://github.com/dengarIicdk/cursed-survivors/issues
AppUpdatesURL=https://github.com/dengarIicdk/cursed-survivors/releases
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
OutputDir={#BuildDir}
OutputBaseFilename=CursedSurvivors-{#AppVersion}-setup
SetupIconFile={#ProjectDir}\assets\icon.ico
LicenseFile={#BuildDir}\LICENSE.txt
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
PrivilegesRequired=admin
DisableProgramGroupPage=yes
AllowNoIcons=yes
ChangesAssociations=no
VersionInfoVersion=1.0.0.0
VersionInfoCompany=Cursed Survivors
VersionInfoDescription=Cursed Survivors installer
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}
VersionInfoCopyright=MIT licensed

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[CustomMessages]
english.DesktopIcon=Create a desktop shortcut
english.Launch=Play Cursed Survivors
english.SavesNote=Your progress is stored in %%APPDATA%%\Godot\app_userdata\CursedSurvivors and is kept when you uninstall.
russian.DesktopIcon=Создать ярлык на рабочем столе
russian.Launch=Запустить Cursed Survivors
russian.SavesNote=Прогресс хранится в %%APPDATA%%\Godot\app_userdata\CursedSurvivors и не удаляется при деинсталляции.

[Tasks]
Name: "desktopicon"; Description: "{cm:DesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#BuildDir}\{#AppExe}";  DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\README.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\preview.jpg"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:Launch}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
