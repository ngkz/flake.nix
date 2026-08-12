# Dotfiles
## Directory Structure
```
flake.nix/
├── flake.nix              # Flake definition
├── nixpkgs.nix            # nixpkgs config (overlays, config)
├── overlays.nix           # nixpkgs overlays: pkgs.ngkz, pkgs.unstable
├── repl.nix               # Variables loaded into the REPL
├── devshell.toml          # numtide devshell (custom commands and packages available to devshell (nix develop, direnv), <flake>.devShells.<system>.default)
├── home/                  # Home Manager modules for multiple hosts
│   ├── default.nix        # Set of all modules in this directory (<flake>.homeManagerModules)
│   ├── adb.nix            # One file/directory per component. Use a single file module when multiple files aren't needed.
│   │                      # Use a module directory when multiple files are needed.
│   └── ...
├── packages/              # Custom nix packages
│   ├── default.nix        # Set of all custom packages (<flake>.packages.<system>)
│   ├── lib/               # Shared, pkgs-dependent functions exposed as `pkgs.ngkz`
│   └── <package>/         # Each package: default.nix + optional update.sh (package update script)
└── scripts/               # devshell command scripts and flake update scripts
    └── ...
```

## Code style
- File naming: Kebab-case
- Comment: Add `# description` comment at start of files. Add inline comments for non-obvious logic
- Import nix module with relative paths
- Add `rec` only when it's necessary
- Use offcial nix code format for nix code: format with `nixfmt FILE` (single file) or `format` (all files) after edit
- Format shell scripts with shfmt: `shfmt FILE`
- When writing/editing derivation:
  - Nix doesn't support Windows. Don't include windows dependencies
  - Don't add empty meta.maintainers
  - Use tag name or commit hash for fetchFromGitHub/fetchgit hash. Don't use branch name. Fill hash with nix-prefetch-github.
  - `system` is deprecated. Use `pkgs.stdenv.hostPlatform.system` instead.
  - Do `cargoRoot = "<SUBDIR>"; buildAndTestSubDir = "${cargoRoot}";` instead of `buildAndTestSubDir = "<SUBDIR>";` + copying `Cargo.lock` to CWD when packaging rust package in a sub directory.
  - Test custom package build with `nix build .#<pkgname>`
  - Write and test package update script
- When writing/editing update script:
  - Test package update script by:
    1. change version, source rev, and hashes to dummy value
    2. run update script
    3. check script output and updated package derivation
  - DONT FORGET TO STUB VERSION, REV, AND HASHES!
    - DONT REPLACE THEM WITH SED!
  - DONT BREAK VARIABLE EXPANSION INSIDE VERSION, REV AND HASHES
  - THE SCRIPT MUST WORK PERFECTLY WITHOUT ANY MANUAL INTERVENTION. YOU MUST NOT RESTORE THE PACKAGE MANUALLY AND CONSIDER THE WORK IS DONE!
- `chmod +x` update scripts and maintancnce scripts
- Do not add `/` suffix when referencing directory in nix
- Add update script when adding new flakes or packages
  - Only `packages/*/update.sh` are auto-discovered. Add explicit invocation to `scripts/update.sh` when you add other update scripts.
- use `home.file.FILE.source = config.lib.file.mkOutOfStoreSymlink PATH` when you need to symlink out-of-store file like age secret inside home directory
* dont add python packages to `home.packages` and `environment.systemPackages`. nix python won't pick up that. add to `cli-essential.pythonPackages`

## nixpkgs channels

- `nixpkgs` (nixos-XX.XX): stable nixpkgs. use this for desktops
- `nixpkgs-small` (nixos-XX.XX-small): identical to nixpkgs. It contains fewer binary cache but update faster. Use this for server/iot hosts
- `nixpkgs-unstable`: available as `pkgs.unstable.<pkg>` via the `unstable` overlay. Use this when the stable package is broken or missing, or when you need the latest version. If you use it because the stable package is broken or missing, add a comment: `# XXX switch to stable after upgrade`.

## tmpfs-as-root/home

- Most hosts use a tmpfs root filesystem with persistent state under `/var/persist`.
- Files not added to `tmpfs-as-root.persistentDirs`/`persistentFiles` (in NixOS module) or `tmpfs-as-home.persistentDirs`/`persistentFiles` (in home-manager module) will be lost on reboot.
  - Add paths to the state should be persistent and large GB-class cache to persistentDirs/Files

## Git Conventions

- Commit messages: Short, lowercase, path-prefixed when applicable
  - Examples
    - `hosts/calidus/ai: add qwen3.5 122b uncensored draft`
    - `hosts/{ai-client,calidus}: unsloth qwen3.5 122b`
    - `home/foo, modules/bar: format`
    - `AGENTS.md: foo`
    - `update` (for system updates)
  - Don't forget path prefix
  - Use commit messages in git log as example
- Final check with `build-all` and `nix flake check` before commit
  - Use these only for final check because these are slower than `dry-build <HOST>`
- Don't commit changes without explicit user approval
- DON'T DISCARD CHANGES (e.g.  `git reset --hard`) WITHOUT explicit user approval

## Nix coding rules
* Nix dintinguishes file by hash. Update hash when changing fetch parameters or source, or nix still sees previous source/lock file.
  * For simple fetch, use nix-prefetch-github, nix-prefetch-git, nix-prefetch-url commands
    * For fetchgit/fetchGitHub, re-prefetch the repo with correct args (--fetch-submodules, etc)
  * For complicated hash (fetchzip, npmHash, cargoHash, etc), replace npmHash/cargoHash to placeholder and extract expected hash from the error message
    * Use valid hash format for the placeholder like: `sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=`
* Untracked files are invisible from nix when the flake is a git repo. When Nix doesn't recognize files that should exist, do `git add -N <file>`.
   * Don't commit without explicit user instruction.
* Use `rec` attr only when it's necessary
* `system` is deprecated. Use `pkgs.stdenv.hostPlatform.system` instead.
* When writing derivation (creating package):
  * Nix doesn't support Windows. Don't include windows dependencies
  * Don't add empty meta.maintainers
  * Use tag name or commit hash for fetchFromGitHub/fetchgit hash. Don't use branch name. Fill hash with nix-prefetch-git/github.
  * Do `cargoRoot = "<SUBDIR>"; buildAndTestSubDir = "${cargoRoot}";` instead of `buildAndTestSubDir = "<SUBDIR>";` + copying `Cargo.lock` to CWD when packaging rust package in a sub directory.
  * Follow this workflow:
    **Recommended directory structure:**
    ```
    <pkg>/
    ├── bin/              # user-facing executables (stays in $out)
    ├── sbin/             # system administration binaries (stays in $out)
    ├── lib/              # shared libraries (including one in scripting language), plugins
    ├── libexec/          # internal executables called by scripts
    ├── include/          # C/C++ header files
    ├── share/
    │   ├── locale/       # internationalization (i18n) files
    │   ├── man/          # man pages (man[0-9]/)
    │   ├── info/         # GNU Info pages
    │   ├── doc/          # user documentation
    │   ├── aclocal/      # Autoconf macro files
    │   ├── gtk-doc/      # GTK-Doc references (removed by default)
    │   └── devhelp/      # DevHelp books (removed by default)
    └── nix-support/      # Nix internal metadata (do not modify)
    ```

    1. **Verify build output structure.** After building, check that files are placed in the recommended directory layout.
       Move or remove misplaced files to their correct outputs.

    2. **If restructuring breaks the package**, install the files to `/opt/<pkgname>` instead and reference them via symlinks or `makeWrapper`.
       Do not force files into non-standard paths within the Nix store.

    3. **Define the `outputs` attribute** to match the file types the package provides. Binaries (`bin/`, `sbin/`) must stay in `$out`.
       Add outputs as needed:
       * `out` — always include (catches everything not assigned elsewhere, including binaries)
       * `lib` — add if the package provides shared libraries
       * `dev` — add if the package provides development files
       * `doc` — add if the package provides user documentation
       * `man` — add if the package provides man pages
       * `info` — add if the package provides GNU Info pages

       Directory-to-output mapping:
       * `lib/`, `libexec/`, `share/locale/` → `outputLib`
       * `include/`, `lib/cmake/`, `lib/pkgconfig/`, `share/aclocal/`, `share/pkgconfig/` → `outputDev`
       * `share/doc/` → `outputDoc`
       * `share/man/` → `outputMan`
       * `share/info/` → `outputInfo`
       * `share/gtk-doc/`, `share/devhelp/` → `outputDevdoc` (removed by default)

       See [Nixpkgs Manual: Multiple-output packages](https://nix.dev/manual/nixpkgs/stable/stdenv/multiple-output.html).
       If automatic movement fails, add `moveToOutput <path-pattern> "$output<Name>"` to the fixup phase manually.
* escape literal `${var}` inside `''...''` string with `''${var}` (escape `${` with `''`)
* dont patch shebangs with `sed`. use `patchShbangs` instead
* Use `substituteInPlace <FILE> --replace-fail ...` instead of `sed`
* when fixing hardcoded paths, use actual path of the command instead of `/usr/bin/env COMMAND`
* find nixpkgs packages with `https://search.nixos.org/packages?channel=<NIXPKGS VERSION>&query=<NAME>` or `nix search nixpkgs <QUERY>`
* dont add python packages to `home.packages` and `environment.systemPackages`. nix python won't pick up that.
* `nix build --print-out-paths ...` to retrieve store path. nix does not output result path by default.
* `nix build ...` does not output anything when the build succeeded. use `--print-out-paths`. check return code and the result
* don't use `exit` inside home-manager/system activation script
* don't truncate `nix build` output with `tail`
