{ pkgs, inputs }:
rec {
  sarasa-term-j-nerd-font = pkgs.callPackage ./sarasa-term-j-nerd-font { };
  flygrep-vim = pkgs.callPackage ./flygrep-vim { };
  ical2org = pkgs.callPackage ./ical2org { };
  avr-ghidra-helpers = pkgs.callPackage ./avr-ghidra-helpers { };
  edbgserver = pkgs.callPackage ./edbgserver { };
  skk-dicts-jawiki = pkgs.callPackage ./skk-dicts-jawiki { };
  fcitx5-themes-candlelight = pkgs.callPackage ./fcitx5-themes-candlelight { };
  gnome-ssh-askpass4 = pkgs.callPackage ./gnome-ssh-askpass4.nix { };
  thunderbird-extension-minimize-on-startup =
    pkgs.callPackage ./thunderbird-extension-minimize-on-startup
      { };
  pi-coding-agent = pkgs.callPackage ./pi-coding-agent { };
  caringcaribou = pkgs.python3Packages.callPackage ./caringcaribou { };
  qiling = pkgs.python3Packages.callPackage ./qiling { };
  saleae = pkgs.python3Packages.callPackage ./saleae { };
  saleae-cli = pkgs.python3Packages.callPackage ./saleae-cli {
    inherit saleae;
  };
  cvc5-python = pkgs.python3Packages.callPackage ./cvc5-python {
    cvc5 = pkgs.cvc5;
  };

  kvantum-libadwaita = pkgs.callPackage ./kvantum-libadwaita { };
  fzf-tab-completion = pkgs.callPackage ./fzf-tab-completion { };
  overlayfs-tools = pkgs.callPackage ./overlayfs-tools { };
  jadx-ai-mcp = pkgs.callPackage ./jadx-ai-mcp { };
  jadx-mcp-server = pkgs.python3Packages.callPackage ./jadx-mcp-server { };
  r8152 = pkgs.callPackage ./r8152 { };
  ryzen-smu = pkgs.callPackage ./ryzen-smu {
    kernel = pkgs.linuxPackages.kernel;
  };
  ghidra-cli = pkgs.callPackage ./ghidra-cli { };
  ghidra-decomp2dbg = pkgs.callPackage ./ghidra-decomp2dbg { };
  ghidra-mcp = pkgs.callPackage ./ghidra-mcp { };
  ghidra-rpc = pkgs.python3Packages.callPackage ./ghidra-rpc { };
  ghidra-mcp-bridge = pkgs.python3Packages.callPackage ./ghidra-mcp-bridge { };
  pi-tps-meter = pkgs.callPackage ./pi-tps-meter { };
  pi-openrouter-plus = pkgs.callPackage ./pi-openrouter-plus { };
  ptrlib = pkgs.python3Packages.callPackage ./ptrlib { };
  qbdi = pkgs.callPackage ./qbdi { };
  pyqbdi = pkgs.python3Packages.callPackage ./pyqbdi { };
  pydemumble = pkgs.python3Packages.callPackage ./pydemumble { };
  gef-bata = pkgs.callPackage ./gef-bata {
    inherit codext;
  };
  codext = pkgs.python3Packages.callPackage ./codext {
    inherit legacycrypt;
  };
  legacycrypt = pkgs.python3Packages.callPackage ./legacycrypt { };
  llama-cpp = (pkgs.unstable.callPackage ./llama-cpp { }).override {
    vulkanSupport = true;
    rocmSupport = true;
  };
  llama-cpp-rocmfpx-strix-mtp = pkgs.unstable.callPackage ./llama-cpp-rocmfpx-strix-mtp { };
  ds4-strix = pkgs.unstable.callPackage ./ds4-strix { };
  ds4fa = pkgs.unstable.callPackage ./ds4fa { };
  crosvm = pkgs.callPackage ./crosvm { };
  xdis = pkgs.python3Packages.callPackage ./xdis { };
  uncompyle6 = pkgs.python3Packages.callPackage ./uncompyle6 {
    xdis = xdis;
  };
  de4dot-kant2002 = pkgs.callPackage ./de4dot-kant2002 { };
  pin = pkgs.callPackage ./pin { };
  binutils-all = pkgs.callPackage ./binutils-all { };
  e9patch = pkgs.callPackage ./e9patch { };
  dynamorio = pkgs.callPackage ./dynamorio { };
  username-anarchy = pkgs.callPackage ./username-anarchy { };
  dnscat2 = pkgs.callPackage ./dnscat2 { };
  autorecon = pkgs.python3Packages.callPackage ./autorecon {
    inherit oscanner tnscmd10g;
    redis = pkgs.redis;
  };
  oscanner = pkgs.callPackage ./oscanner { };
  tnscmd10g = pkgs.callPackage ./tnscmd10g { };
  klee = pkgs.callPackage ./klee { };
  angr-data = pkgs.python3Packages.callPackage ./angr-data { };
  pypcode = pkgs.python3Packages.callPackage ./pypcode { };
  archinfo = pkgs.python3Packages.callPackage ./archinfo { };
  claripy = pkgs.python3Packages.callPackage ./claripy { };
  pyvex = pkgs.python3Packages.callPackage ./pyvex { };
  uefi-firmware = pkgs.python3Packages.callPackage ./uefi-firmware { };
  adwaita-colors-icon-theme = pkgs.callPackage ./adwaita-colors-icon-theme { };
  battery-usage-wattmeter = pkgs.callPackage ./battery-usage-wattmeter { };
  umap2 = pkgs.callPackage ./umap2 { };
  pyxdia = pkgs.python3Packages.callPackage ./pyxdia { };
  cle = pkgs.python3Packages.callPackage ./cle {
    inherit
      archinfo
      pyvex
      pyxdia
      uefi-firmware
      ;
  };
  angr = pkgs.python3Packages.callPackage ./angr {
    inherit
      angr-data
      pypcode
      pydemumble
      archinfo
      claripy
      cle
      pyvex
      ;
  };
  usb_f_mass_storage-pikvm = pkgs.callPackage ./usb_f_mass_storage-pikvm { };
  it930x-firmware = pkgs.callPackage ./px4_drv/firmware.nix { };
  px4_drv-udev-rules = pkgs.callPackage ./px4_drv/udev.nix { };
  px4_drv = pkgs.callPackage ./px4_drv/module.nix {
    kernel = pkgs.linuxPackages.kernel;
  };
}
