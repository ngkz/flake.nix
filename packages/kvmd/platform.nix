# https://github.com/pikvm/kvmd/blob/v4.110/PKGBUILD
{
  lib,
  bash,
  fetchFromGitHub,
  stdenvNoCC,
  coreutils,
  ustreamer,
  makeWrapper,
  systemd,
}:
let
  base = "v2";
  video = "hdmiusb";
  platform = "${base}-${video}";
  board = "opizero2";
  base_board = "rpi4";
  srcinfo = import ./src.nix { inherit fetchFromGitHub; };
in
stdenvNoCC.mkDerivation {
  pname = "kvmd-platform-${platform}-${board}";

  inherit (srcinfo) version src;

  patchPhase = ''
    substituteInPlace scripts/kvmd-udev-hdmiusb-check \
      --replace-fail "/bin/bash" "${bash}/bin/bash"
    for rule in configs/os/udev/*-hdmiusb-*.rules; do
      substituteInPlace "$rule" \
        --replace-quiet "/usr/bin/kvmd-udev-hdmiusb-check" "$out/bin/kvmd-udev-hdmiusb-check"
    done
    for cfg in configs/kvmd/main/*.yaml; do
      substituteInPlace "$cfg" \
        --replace-quiet "/usr/bin/ustreamer" "${ustreamer}/bin/ustreamer"
    done
    substituteInPlace configs/os/udev/common.rules \
      --replace-fail "/usr/bin/systemd-escape" "${systemd}/bin/systemd-escape" \
      --replace-fail "/usr/bin/chmod" "${coreutils}/bin/chmod" \
      --replace-fail "/usr/bin/chgrp" "${coreutils}/bin/chgrp"
  '';

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    install -Dm755 -t "$out/bin" scripts/kvmd-udev-hdmiusb-check
    wrapProgram $out/bin/kvmd-udev-hdmiusb-check \
      --prefix PATH : ${lib.makeBinPath [ coreutils ]}

    install -DTm644 "configs/os/modprobe.conf" "$out/lib/modprobe.d/99-kvmd.conf"
    install -DTm644 "configs/os/sysctl.conf" "$out/lib/sysctl.d/99-kvmd.conf"
    install -DTm644 "configs/os/udev/common.rules" "$out/lib/udev/rules.d/99-kvmd-common.rules"
    install -DTm644 "configs/os/udev/${platform}-${base_board}.rules" "$out/lib/udev/rules.d/99-kvmd.rules"
    install -DTm644 "configs/kvmd/main/${platform}-${base_board}.yaml" "$out/lib/kvmd/main.yaml"
    install -DTm644 ${./v2-hdmiusb-opizero2.conf} "$out/lib/modules-load.d/kvmd.conf"
    # XXX no sudoers because of dependency loop
    install -DTm444 "configs/kvmd/edid/_no-1920x1200.hex" "$out/etc/kvmd/switch-edid.hex"

    mkdir -p "$out/lib/kvmd"
    local _platform="$out/lib/kvmd/platform"
    rm -f "$_platform"
    echo PIKVM_MODEL=${base} > "$_platform"
    echo PIKVM_VIDEO=${video} >> "$_platform"
    echo PIKVM_BOARD=${board} >> "$_platform"
    chmod 444 "$_platform"
  '';

  meta = with lib; {
    description = "PiKVM platform configs - ${platform} for ${board}";
    homepage = "https://github.com/pikvm/kvmd";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
