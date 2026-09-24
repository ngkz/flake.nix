# strixec: exposes the MS-S1 MAX embedded controller as /dev/strixec.
# Works without CONFIG_ACPI_EC_DEBUGFS and under Secure Boot kernel lockdown,
# unlike the debugfs interface used by ec_sys.
{
  lib,
  stdenv,
  fetchFromGitHub,
  linuxPackages,
  kernel ? linuxPackages.kernel,
  kernelModuleMakeFlags ? linuxPackages.kernelModuleMakeFlags,
}:
let
  inherit (import ./src.nix { inherit fetchFromGitHub; }) version src;
in
stdenv.mkDerivation rec {
  pname = "strixec-module";
  name = "${pname}-${version}-${kernel.version}";
  inherit version src;

  sourceRoot = "${src.name}/module";

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  # Upstream Makefile defaults KDIR to the headers of the running kernel.
  makeFlags = kernelModuleMakeFlags ++ [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    runHook preInstall

    install -Dm444 strixec.ko -t $out/lib/modules/${kernel.modDirVersion}/extra

    runHook postInstall
  '';

  meta = {
    description = "Kernel module exposing the Minisforum MS-S1 MAX embedded controller as /dev/strixec";
    homepage = "https://github.com/raimondomartire/ms-s1-max-fans-control";
    license = lib.licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
  };
}
