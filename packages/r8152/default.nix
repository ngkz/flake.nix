{
  lib,
  linuxPackages,
  kernel ? linuxPackages.kernel,
  kernelModuleMakeFlags ? linuxPackages.kernelModuleMakeFlags,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  name = "r8152-${kernel.version}-${version}";
  version = "2.21.4.20260427";

  # mirror
  src = fetchFromGitHub {
    owner = "wget";
    repo = "realtek-r8152-linux";
    rev = "v${version}";
    hash = "sha256-bDCaAap5k5LTPNW6f4R9TFNFxCm9+4owLFqlV7BIDk0=";
  };

  hardeningDisable = [ "pic" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  # avoid using the Makefile directly -- it doesn't understand
  # any kernel but the current.
  makeFlags = kernelModuleMakeFlags ++ [
    "-C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
    "EXTRA_CFLAGS=-DRTL8152_S5_WOL"
    "INSTALL_MOD_PATH=$(out)"
    "INSTALL_MOD_DIR=kernel/drivers/net/usb"
  ];

  postInstall = ''
    install -D 50-usb-realtek-net.rules  $out/etc/udev/rules.d/50-usb-realtek-net.rules
  '';

  buildFlags = [ "modules" ];
  installTargets = [ "modules_install" ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Realtek RTL8152/RTL8153 Based USB Ethernet Adapters driver";
    homepage = "https://github.com/wget/realtek-r8152-linux";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
