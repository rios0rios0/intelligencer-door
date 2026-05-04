# Copilot Instructions for Intelligencer Door

## Project Overview

Intelligencer Door is a historical Windows desktop Remote Administration Tool (RAT) built with **Object Pascal (Delphi 7)** and discontinued on **2013-12-05**. The repository is preserved as an educational and archival reference. No new features or bug fixes are planned.

The application acts as the **controller (client) side** of a TCP client-server system, providing remote file management, keylogger retrieval, screen capture, system diagnostics, and hardware/software toggle controls over connected target machines. The UI is in **Brazilian Portuguese**.

> **Disclaimer:** This software was developed strictly as a learning exercise to study network programming and Windows internals. It is provided for educational and historical reference only. Do not use this software for unauthorized access to computer systems.

## Repository Structure

```
intelligencer-door/
├── .github/
│   ├── copilot-instructions.md   # This file
│   └── workflows/
│       └── release.yaml          # Reusable release workflow (tag on merge to main)
├── ID.dpr                        # Delphi project file – entry point; creates mutex, Form1
├── ID.res                        # Compiled application resources
├── UID.pas / UID.dfm             # Main form – connection list, server socket, tray icon,
│                                 #   menu, and all remote command dispatch
├── UCS.pas / UCS.dfm             # Server Builder form – configure IP, port, icon, worm
│                                 #   options, and generate a custom server EXE
├── UFM.pas / UFM.dfm             # File Manager form – remote file browsing, download,
│                                 #   delete, rename, and directory creation
├── UKL.pas / UKL.dfm             # Key Logger form – display and save captured keystrokes
├── USL.pas / USL.dfm             # Screen Logger form – display remote desktop screenshots
├── UDG.pas / UDG.dfm             # Diagnostics form – system information display and save
├── IconChanger.pas               # Utility to replace the icon of a compiled EXE
├── Resources/
│   ├── Server.rc / Server.res    # Embedded server-template resource (IDS EXE)
│   ├── Icons.rc / Icons.res      # Embedded icon resources (10 selectable icons)
│   └── Address.xlsx              # Address reference spreadsheet
├── Servidor/                     # Server-side source code (payload / target agent)
│   ├── IDS.dpr                   # Server main program
│   ├── External Uses/
│   │   ├── MyUtils.pas           # General utility functions
│   │   ├── sndkey32.pas          # Keyboard simulation
│   │   └── TrjFuncs.pas          # Trojan helper functions (worm / registry persistence)
│   └── System/                   # Custom system units and zlib compression
│       ├── System.pas
│       ├── SysInit.pas
│       ├── SysSfIni.pas
│       ├── SYSWSTR.PAS
│       ├── CompressionStreamUnit.pas
│       └── *.obj                 # Pre-compiled zlib objects (deflate, inflate, crc32, …)
├── Imgs/
│   ├── ICON01..ICON10.ico        # Selectable icons for the server builder
│   ├── AppIcon.ico               # Application icon
│   └── PopUp.png                 # MSN-style notification popup image
├── CHANGELOG.md                  # Changelog following Keep a Changelog format
├── Clear.bat                     # Removes Delphi build artifacts (*.dcu, *.obj, etc.)
├── CONTRIBUTING.md
├── LICENSE                       # GNU General Public License v3.0
└── README.md
```

## Technology Stack

| Component            | Details                                                                                        |
|----------------------|------------------------------------------------------------------------------------------------|
| **Language**         | Object Pascal (Borland Delphi 7)                                                               |
| **IDE**              | Borland Delphi 7 (or compatible: Embarcadero RAD Studio)                                       |
| **Networking**       | `TServerSocket` / `TClientSocket` (ScktComp), low-level WinSock `Send`/`Recv`/`Connect` calls |
| **UI Framework**     | VCL (`TForm`, `TListView`, `TMainMenu`, `TPopupMenu`, `TStatusBar`, `TProgressBar`, `TTimer`)  |
| **Third-party VCL**  | `TMSNPopUp` (notification popups), `TTrayIcon` (system tray), `TXPManifest` (XP theming)       |
| **Resource handling**| `TResourceStream` (extract embedded EXE template and icons), `TMemoryStream` (binary patching) |
| **Compression**      | zlib (pre-compiled `.obj` objects bundled in `Servidor/System/`)                               |
| **Platform**         | Windows only (Win32, XP/Vista era)                                                             |

## Architecture

### Client-Server Overview

The system consists of two independent programs compiled separately:

- **Controller (`ID.dpr`)** – runs on the attacker's machine; hosts a `TServerSocket` and waits for inbound connections from targets.
- **Server/Agent (`Servidor/IDS.dpr`)** – the payload deployed on target machines; connects outbound to the controller using a WinSock `Connect` call.

### Controller (Client) Architecture

The main form `TForm1` (`UID.pas`) owns a `TServerSocket`. When a target connects, its socket handle, hostname, IP address, and connection time are added to a `TListView`. A right-click context menu dispatches remote commands by sending command strings through the target's `TCustomWinSocket`.

Feature-specific forms (`UFM`, `UKL`, `USL`, `UDG`) are shown modally or as child windows and communicate with the target through the same socket reference.

```
TForm1 (UID.pas)
├── TServerSocket  ──► accepts connections, populates TListView
├── TTrayIcon      ──► minimise-to-tray with MSN-style popup on new connection
├── Right-click popup menu
│   ├── File Manager  → TFormFM (UFM.pas)  ──► command prefix "Rk06:"
│   ├── Key Logger    → TFormKL (UKL.pas)
│   ├── Screen Logger → TFormSL (USL.pas)
│   ├── Diagnostics   → TFormDG (UDG.pas)
│   ├── CMD Remoto    ──► "CMD:" prefix
│   └── Hardware/Software toggles ──► plain-text command strings
└── Menu bar
    └── Criar Servidor → TFormCS (UCS.pas) – server builder
```

### Server Builder (`UCS.pas`)

Extracts the embedded `IDS` EXE from `Server.res` into a `TMemoryStream`, then writes configuration values (IP address, port, server name) at **specific hard-coded binary byte offsets** using `TMemoryStream.Write`. The resulting stream is saved as the output EXE. Icon replacement is performed by `IconChanger.pas`.

### Server/Agent (`Servidor/IDS.dpr`)

A minimal Win32 app that:

1. Connects to the hard-coded controller IP/port via WinSock.
2. Handles incoming command strings in `MNReceivingText()` dispatching to handlers for file operations (`GET_FILE`, `LST_FILE`, `DEL_FILE`, `REN_FILE`, …), keylogger retrieval, screenshots, diagnostics, and hardware toggles.
3. Optionally installs registry persistence and performs worm propagation through MSN/Hotmail contacts.
4. Compresses data (screenshots, files) with zlib before transmission.

## Build Instructions (Historical)

There is no automated build system. Compilation requires a Windows machine with Borland Delphi 7 or a compatible IDE.

### Controller

1. Install **Borland Delphi 7** with socket and third-party component packages (`TMSNPopUp`, `TTrayIcon`)
2. Open `ID.dpr` in the Delphi IDE
3. Ensure all unit search paths include `Servidor/External Uses/` and `Servidor/System/`
4. Compile: **Ctrl+F9** (compile only) or **F9** (build and run)

### Server/Agent

1. Open `Servidor/IDS.dpr` in Delphi 7
2. Compile separately; the resulting `IDS.exe` can be embedded into `Resources/Server.res`

> **Cleanup:** Run `Clear.bat` in the project root to remove Delphi build artifacts (`.dcu`, `.dsk`, `.cfg`, `.~*`, etc.).

## Tests and Linting

This project has **no automated tests and no linters**. The only GitHub Actions workflow is `.github/workflows/release.yaml`, which triggers a reusable release pipeline on merges to `main` (tag creation). No testing or linting infrastructure exists or is planned.

## Development Workflow

Because this project is archived and no longer maintained, there is no active development workflow. If making historical corrections or documentation updates:

1. Edit the relevant `.pas`, `.dfm`, or documentation files.
2. Add an entry to `CHANGELOG.md` under the `[Unreleased]` section.
3. Open the project in Delphi 7 / RAD Studio to verify compilation if source changes are made.
4. Submit a pull request with a clear description of the archival correction.

## Coding Conventions

- **Language:** Object Pascal with Delphi 7 naming conventions
  - Form component names use lowercase Hungarian-style prefixes (e.g., `edt` for `TEdit`, `btn` for `TButton`, `lbl` for `TLabel`, `mmo` for `TMemo`, `lst` for `TListBox`, `lv` for `TListView`, `cb` for `TCheckBox`, `spn` for `TSpinEdit`)
  - Event handlers follow Delphi's auto-generated pattern: `<ComponentName><EventName>` (e.g., `btnAtivarClick`, `ServerSocket1Accept`)
- **UI language:** All UI strings are in **Brazilian Portuguese** (Português do Brasil) — do not translate them
- **Error handling:** Uses `try/except` blocks with `ShowMessage` or `MessageBox` dialogs for user-facing errors; no structured logging

## Common Tasks

| Task                          | How                                                                                      |
|-------------------------------|------------------------------------------------------------------------------------------|
| Build the controller          | Open `ID.dpr` in Delphi 7, press **Ctrl+F9**                                            |
| Run the controller            | Press **F9** in Delphi 7, or run the compiled `ID.exe` directly                         |
| Build the server/agent        | Open `Servidor/IDS.dpr` in Delphi 7, press **Ctrl+F9**                                  |
| Clean build artifacts         | Run `Clear.bat` in the project root                                                      |
| Start listening for targets   | Set the port in the spin edit, click **Ativar Busca**                                    |
| Connect to a target           | Target must run the compiled server EXE pointing to the controller's IP                  |
| Open the File Manager         | Right-click a connected target → **File Manager**                                        |
| Build a custom server EXE     | Menu → **Criar Servidor**, fill in IP/port/name, pick an icon, click the build button   |

## Notes for AI Assistants

- This is a **Windows-only Win32 application**; all file paths, registry access, WinSock calls, and UI controls are Windows-specific
- The project is **discontinued** – avoid suggesting feature additions, library upgrades, or security hardening
- All UI strings are in **Brazilian Portuguese**; do not translate them
- The `.res` files (`ID.res`, `Resources/Server.res`, `Resources/Icons.res`) are **binary compiled resources** – they cannot be edited as plain text
- The `.obj` files in `Servidor/System/` are **pre-compiled zlib object files** – they cannot be recompiled without the original C toolchain
- The `.dfm` files are Delphi form layout files that describe UI component trees; they are paired 1-to-1 with their `.pas` unit files
