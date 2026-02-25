<h1 align="center">Intelligencer Door</h1>
<p align="center">
    <a href="https://github.com/rios0rios0/intelligencer-door/releases/latest">
        <img src="https://img.shields.io/github/release/rios0rios0/intelligencer-door.svg?style=for-the-badge&logo=github" alt="Latest Release"/></a>
    <a href="https://github.com/rios0rios0/intelligencer-door/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/rios0rios0/intelligencer-door.svg?style=for-the-badge&logo=github" alt="License"/></a>
</p>

A Windows desktop remote administration tool (RAT) built with Object Pascal in Borland Delphi 7, featuring a client-server architecture with TCP socket communication. The application serves as the controller (client) side, providing remote file management, keylogger retrieval, screen capture, system diagnostics, and hardware/software toggle controls over connected targets. This project was created purely for educational purposes to study network programming and Windows internals. Development discontinued on 2013-12-05.

> **Disclaimer:** This software was developed strictly as a learning exercise. It is provided for educational and historical reference only. Do not use this software for unauthorized access to computer systems.

## Features

### Connection Management
- **TCP server socket** listening on a configurable port for incoming connections from remote targets
- **Multi-client support** -- displays connected clients in a `TListView` with socket handle, hostname, IP address, and connection time
- **MSN-style popup notifications** on new connections
- **System tray integration** -- minimizes to tray with `TTrayIcon`, restores via popup menu
- **Mutex-based single instance** enforcement

### Remote Operations
- **File Manager** (`UFM.pas`) -- remote file system browser with:
  - Directory navigation with drive listing
  - File listing with size display (KB, MB, GB formatting)
  - File download with progress bar
  - File deletion, renaming, and directory creation
  - Remote file opening (visible or hidden)
  - Multiple view modes (icons, list, details, side)
  - File type icon mapping for 20+ extensions (audio, video, images, documents, archives, executables)
- **Key Logger** (`UKL.pas`) -- retrieves captured keystrokes from the remote target, with save-to-file and clear functionality
- **Screen Logger** (`USL.pas`) -- captures and displays remote desktop screenshots as BMP images
- **System Diagnostics** (`UDG.pas`) -- retrieves system information from the remote target, displayed in a memo with save-to-file option
- **Remote Command Execution** -- sends arbitrary Windows CMD commands to the remote target
- **Hardware/Software Controls** -- toggle desktop icons, taskbar, start menu, monitor, clock, CD-ROM, keyboard locks (Caps/Num/Scroll), mouse, and shutdown/logoff/restart commands

### Server Builder
- **Server builder** (`UCS.pas`) -- creates customized server executables by:
  - Extracting an embedded server template from resources (`IDS` EXE resource)
  - Writing configuration values (IP address, port, server name) at specific binary offsets using `TMemoryStream`
  - Optional worm functionality with configurable homepage and text
  - Optional registry infection toggle
  - Customizable application icon from 10 built-in icons or a custom `.ico` file
  - Icon replacement via `IconChanger.pas` utility

## Technologies

- **Object Pascal** (Borland Delphi 7)
- **VCL** -- `TForm`, `TListView`, `TServerSocket`, `TTimer`, `TMainMenu`, `TPopupMenu`, `TStatusBar`, `TProgressBar`
- **ScktComp** -- Delphi socket components for TCP communication
- **WinSock** -- low-level socket `Send` calls
- **Windows API** -- `AnimateWindow`, `EnableWindow`, `CreateMutex`, `ShowWindow`
- **Third-party components** -- `TMSNPopUp` (notification popups), `TTrayIcon` (system tray), `TXPManifest` (XP visual styles)
- **TMemoryStream** -- binary patching of server executables at specific offsets
- **TResourceStream** -- extracting embedded resources (server template, icons)

## Project Structure

```
intelligencer-door/
├── ID.dpr                    # Main program with mutex, form creation, and application initialization
├── ID.res                    # Compiled resources
├── UID.pas / UID.dfm         # Main form -- connection list, server socket, menu, tray, all command dispatch
├── UCS.pas / UCS.dfm         # Server builder form -- configure IP, port, icon, worm options, build EXE
├── UFM.pas / UFM.dfm         # File Manager form -- remote file browsing, download, delete, rename
├── UKL.pas / UKL.dfm         # Key Logger form -- display and save captured keystrokes
├── USL.pas / USL.dfm         # Screen Logger form -- display remote desktop screenshots
├── UDG.pas / UDG.dfm         # Diagnostics form -- system info display and save
├── IconChanger.pas           # Utility to replace the icon of a compiled EXE
├── Resources/
│   ├── Server.rc / Server.res    # Embedded server template resource
│   ├── Icons.rc / Icons.res      # Embedded icon resources (10 options)
│   └── Address.xlsx              # Address reference spreadsheet
├── Servidor/                     # Server-side source code
│   ├── IDS.dpr                   # Server main program
│   ├── External Uses/
│   │   ├── MyUtils.pas           # Utility functions
│   │   ├── sndkey32.pas          # Keyboard simulation
│   │   └── TrjFuncs.pas         # Trojan helper functions
│   └── System/                   # Custom system units and compression
│       ├── System.pas
│       ├── SysInit.pas
│       ├── CompressionStreamUnit.pas
│       └── *.obj                 # Precompiled zlib objects (deflate, inflate, crc32, etc.)
├── Imgs/
│   ├── ICON01..ICON10.ico        # Selectable icons for the server builder
│   ├── AppIcon.ico               # Application icon
│   └── PopUp.png                 # Notification popup image
├── Clear.bat                     # Cleans Delphi build artifacts
└── LICENSE
```

## Installation

1. Install **Borland Delphi 7** with socket and third-party component packages (`TMSNPopUp`, `TTrayIcon`)
2. Open `ID.dpr` in the Delphi IDE
3. Ensure all unit paths are configured (especially `Servidor/External Uses/` and `Servidor/System/`)
4. Compile and run

## Usage

1. Launch the application -- the main window "Intelligencer Door" appears
2. Set the listening port using the spin edit control
3. Click **Ativar Busca** (Activate Search) to start the TCP server and listen for incoming connections
4. Connected targets appear in the list view with their IP addresses
5. Right-click a connected target to access remote operations:
   - **File Manager** -- browse and manage remote files
   - **Key Logger** -- retrieve captured keystrokes
   - **Screen Logger** -- capture remote desktop screenshots
   - **Diagnostics** -- view system information
   - **CMD Remoto** -- execute remote commands
   - **Hardware/Software controls** -- toggle system features
6. Use **Criar Servidor** (Create Server) from the menu to build a customized server executable

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.
