# flake-nix

My custom Nix packages/NixOS modules/Home-Manager modules

## Packages

### Static analysis

| Package            | Description                                                                             |
|--------------------|-----------------------------------------------------------------------------------------|
| binutils-all       | Binutils with all targets support, prefixed with `all-` + gas for all supported targets |
| avr-ghidra-helpers | ATmega328p extension for Ghidra                                                         |
| de4dot-kant2002    | Open source .NET deobfuscator and unpacker (kant2002 fork)                              |

#### Symbolic Execution

| Package       | Description                                                                   |
|---------------|-------------------------------------------------------------------------------|
| angr          | Powerful and user-friendly binary analysis platform                           |
| angr-data     | Data files for angr (angr dependency)                                         |
| archinfo      | Classes with architecture-specific information (angr dependency)              |
| claripy       | Abstraction layer for constraint solvers (angr dependency)                    |
| cle           | CLE Loads Everything — binary loader for angr (angr dependency)               |
| pyvex         | Python interface to libVEX and VEX IR (angr dependency)                       |
| pyxdia        | Extract program information from PDB files (angr dependency)                  |
| pydemumble    | Python wrapper for C++/Rust/Swift symbol demangler (angr dependency)          |
| pypcode       | Decompiler intermediate representation library (angr dependency)              |
| uefi-firmware | Various data structures and parsing tools for UEFI firmware (angr dependency) |
| klee          | KLEE symbolic execution engine                                                |

### Dynamic analysis
#### Debugger

| Package           | Description                                                                                                         |
|-------------------|---------------------------------------------------------------------------------------------------------------------|
| gef-bata          | Modern experience for GDB with advanced debugging features for exploit developers & reverse engineers (bata24 fork) |
| codext            | Native codecs extension (gef dependency)                                                                            |
| legacycrypt       | Wrapper to the POSIX crypt library call and associated functionality (gef dependency)                               |
| ghidra-decomp2dbg | Ghidra-Pwndbg/GEF integration, Ghidra extension part                                                                |
| edbgserver        | eBPF-powered GDB server for Linux and Android                                                                       |

#### Dynamic Binary Instrumentation

| Package   | Description                                 |
|-----------|---------------------------------------------|
| dynamorio | DynamoRIO dynamic instrumentation framework |
| qbdi      | QBDI — Quick Binary Dynamic Instrumentation |
| pyqbdi    | Python bindings for QBDI                    |
| qiling    | Advanced binary emulation framework         |
| pin       | Intel PIN dynamic instrumentation framework |

### Network

| Package   | Description                                                          |
|-----------|----------------------------------------------------------------------|
| autorecon | Multi-threaded network reconnaissance tool                           |
| dnscat2   | C2 server/client that tunnels data over DNS                          |
| oscanner  | Oracle assessment framework for SID enumeration and password testing |
| tnscmd10g | Oracle TNS listener access tool                                      |

### Embedded & Automotive

| Package       | Description                                                     |
|---------------|-----------------------------------------------------------------|
| caringcaribou | A friendly automotive security exploration tool for the CAN bus |
| umap2         | USB Host Security Assessment Tool                               |
| saleae        | Python library to control a Saleae Logic Analyzer               |
| saleae-cli    | CLI utility to automate Saleae Logic software                   |

### SMT Solver

| Package     | Description                     |
|-------------|---------------------------------|
| cvc5-python | cvc5 SMT solver Python bindings |

### Misc. Hacking Utilities

| Package          | Description                                       |
|------------------|---------------------------------------------------|
| ptrlib           | Python library for CTF players                    |
| e9patch          | Static binary rewriting tool for x86_64 Linux ELF |
| username-anarchy | Username generation tool                          |

### LLM

| Package                     | Description                                                                        |
|-----------------------------|------------------------------------------------------------------------------------|
| llama-cpp                   | Latest release of llama.cpp, default build                                         |
| llama-cpp-vulkan            | llama-cpp, Vulkan enabled build                                                    |
| llama-cpp-rocm              | llama-cpp, ROCm enabled build                                                      |
| llama-cpp-rocmfpx-strix-mtp | llama-cpp ROCmFPX fork - AMD-focused GGUF quant formats, Strix Halo build          |
| ds4-strix                   | DeepSeek V4 Flash/PRO local inference engine (DwarfStar) — ROCm/Strix Halo build   |
| ds4fa                       | DeepSeek V4 Flash/PRO local inference engine (DwarfStar) — ROCmFPX/Strix Halo fork |
| pi-coding-agent             | Latest release of Pi coding agent                                                  |
| ghidra-mcp                  | Ghidra MCP, Ghidra extension part                                                  |
| ghidra-mcp-bridge           | Ghidra MCP, MCP server part                                                        |
| jadx-ai-mcp                 | JADX MCP, JADX extension part, quality is meh                                      |
| jadx-mcp-server             | JADX MCP, MCP server part, quality is meh                                          |

### Virtualization

| Package | Description                                |
|---------|--------------------------------------------|
| crosvm  | Secure virtual machine monitor for KVM      |

### Vim

| Package     | Description                   |
|-------------|-------------------------------|
| flygrep-vim | Vim plugin for fast file grep |

### Emacs

| Package  | Description                     |
|----------|---------------------------------|
| ical2org | iCalendar to Org-mode converter |

### CLI

| Package            | Description                           |
|--------------------|---------------------------------------|
| fzf-tab-completion | fzf-based tab completion for zsh/bash |

## GUI

| Package                                   | Description                                  |
|-------------------------------------------|----------------------------------------------|
| gnome-ssh-askpass4                        | GNOME SSH askpass helper                     |
| sarasa-term-j-nerd-font                   | Sarasa Gothic Nerd Font                      |
| fcitx5-themes-candlelight                 | Fcitx5 Candlelight theme                     |
| kvantum-libadwaita                        | Qt Libadwaita theme                          |
| skk-dicts-jawiki                          | SKK Wikipedia dictionary                     |
| thunderbird-extension-minimize-on-startup | Thunderbird extension to minimize on startup |
| mutter_50_3                               | GNOME Mutter 50.3 (nixpkgs#541689)           |

### Drivers

| Package                  | Description                                                                |
|--------------------------|----------------------------------------------------------------------------|
| r8152                    | Realtek RTL8152/RTL8153 USB Ethernet kernel module                         |
| px4_drv                  | Unofficial Linux/Windows driver for PLEX PX4/PX5/PX-MLT ISDB-T/S receivers |
| it930x-firmware          | Firmware for PLEX PX4/PX5/PX-MLT series ISDB-T/S receivers                 |
| px4_drv-udev-rules       | Udev rules for PLEX PX4/PX5/PX-MLT series ISDB-T/S receivers               |
| usb_f_mass_storage-pikvm | USB mass storage kernel module for PiKVM                                   |

### System Utilities

| Package         | Description                                                        |
|-----------------|--------------------------------------------------------------------|
| overlayfs-tools | Maintenance tools for overlayfs (fsck, vacuum, diff, merge, deref) |
