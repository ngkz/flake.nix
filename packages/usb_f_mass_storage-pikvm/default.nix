{
  lib,
  linuxPackages,
  kernel ? linuxPackages.kernel,
  kernelModuleMakeFlags ? linuxPackages.kernelModuleMakeFlags,
  stdenv,
  fetchFromGitHub,
}:
let
  pikvm-packages = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "a6d094df79c7b8418c3d7938274e4542a49f40d9";
    hash = "sha256-kPPJWitMMiLKsMxdAfboUfhYwlAOiJshxV8U7xyoQbg=";
  };
in
stdenv.mkDerivation {
  pname = "usb_f_mass_storage-pikvm";
  version = "${kernel.version}-${lib.substring 0 7 pikvm-packages.rev}";
  inherit (kernel) src;

  patches = kernel.patches ++ [
    "${pikvm-packages}/packages/linux-rpi-pikvm/2001-pikvm-msd-dvd-support.patch"
    "${pikvm-packages}/packages/linux-rpi-pikvm/2002-pikvm-msd-inquiry-for-flash-and-cdrom.patch"
  ];

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    # add include options due to /drivers is missing from kernel.dev
    make ${lib.escapeShellArgs kernelModuleMakeFlags} \
      -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$PWD/drivers/usb/gadget/function \
      KCFLAGS="-I$PWD/drivers/usb/gadget -I$PWD/drivers/usb/gadget/udc" \
      usb_f_mass_storage.ko
  '';

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/usb/gadget/function
    cp drivers/usb/gadget/function/usb_f_mass_storage.ko \
       $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/usb/gadget/function/
    xz -f $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/usb/gadget/function/usb_f_mass_storage.ko
  '';

  meta = with lib; {
    description = "Standalone build of usb_f_mass_storage.ko with PiKVM patches";
    homepage = "https://github.com/pikvm/packages";
    license = licenses.gpl2Only;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
