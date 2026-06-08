# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A discontinued (2013-12-05) Windows-only remote administration tool written in Object Pascal (Borland Delphi 7), preserved for archival/educational reference. No new features or fixes are planned. All UI strings are in Brazilian Portuguese — do not translate them.

See `.github/copilot-instructions.md` for the full file-by-file map and `README.md` for the feature list; this file covers only what is non-obvious.

## Two programs, compiled separately

- **Controller** — `ID.dpr`, the attacker-side app. Hosts a `TServerSocket` and waits for inbound connections. This is the code in the repo root.
- **Server/agent** — `Servidor/IDS.dpr`, the payload deployed on targets. Connects *outbound* to the controller. Built separately, then embedded into `Resources/Server.res`.

The two never share a `.dpr`; the controller talks to the agent only over the socket.

## Wire protocol (the load-bearing coupling)

The controller and agent are coupled by string command prefixes sent over the socket, not by any shared interface:

- File-manager commands: `'Rk06:'` + integer command code + param (see `GET_FILE`, `GET_DRIV`, etc. constants). Dispatched in `TFrm33585IDPrincipal.SrvrScktClientRead` (`UID.pas`); also sent from `UFM.pas`.
- Remote shell: `'CMD:'` + command string (`UID.pas`).
- Hardware/software toggles: plain command strings.

Changing a prefix or code on one side silently breaks the other. The agent's matching dispatch lives in `Servidor/`.

## Server builder is binary patching

`UCS.pas` (`TFrmCriarServer`) extracts the embedded `IDS` EXE template from `Server.res` into a `TMemoryStream`, then writes IP/port/name **at hard-coded byte offsets**. Offsets are positional — they depend on the exact compiled layout of `IDS.exe`. Icon replacement is done by `IconChanger.pas`.

## Build / test / lint

There is no build system, no tests, and no linters. Compilation requires Borland Delphi 7 (or compatible RAD Studio) on Windows:

- Controller: open `ID.dpr`, **Ctrl+F9** (compile) / **F9** (build+run). Unit search paths must include `Servidor/External Uses/` and `Servidor/System/`.
- Agent: open `Servidor/IDS.dpr`, compile separately.
- Clean artifacts: run `Clear.bat`.

CI: `.github/workflows/release.yaml` is a reusable release pipeline that tags on push to `main`. It does not build the Delphi code.

## Conventions and gotchas

- `.dfm` files pair 1-to-1 with their `.pas` unit (form layout vs. logic).
- Binary, not text-editable: `ID.res`, `Resources/*.res`, and the precompiled zlib `*.obj` files in `Servidor/System/`.
- Component naming uses Hungarian prefixes (`edt`, `btn`, `lbl`, `mmo`, `lv`, `cb`, `spn`); event handlers follow Delphi's `<Component><Event>` pattern.
- When making any source or doc change, add a `CHANGELOG.md` entry under `[Unreleased]`.
