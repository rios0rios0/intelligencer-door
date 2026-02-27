# Contributing

> **This project was discontinued in December 2013 and is no longer actively maintained.**
> The repository is preserved as a historical reference. No new features or bug fixes are planned.

## Historical Build Information

This project was built using the following tools and technologies:

- **Language:** Object Pascal (Borland Delphi 7)
- **IDE:** Borland Delphi 7
- **Networking:** `TServerSocket` (ScktComp), WinSock
- **UI Framework:** VCL (`TForm`, `TListView`, `TMainMenu`, `TPopupMenu`, `TStatusBar`, `TProgressBar`)
- **Third-party components:** `TMSNPopUp`, `TTrayIcon`, `TXPManifest`
- **Architecture:** Client-server (TCP sockets) with a server builder that patches embedded resources

### Build Steps (Historical)

1. Install Borland Delphi 7 with socket and third-party component packages (`TMSNPopUp`, `TTrayIcon`)
2. Open `ID.dpr` in the Delphi IDE
3. Ensure all unit paths are configured (especially `Servidor/External Uses/` and `Servidor/System/`)
4. Compile and run

> **Note:** The server-side code is in the `Servidor/` directory with its own entry point `IDS.dpr`. `Clear.bat` cleans Delphi build artifacts.
