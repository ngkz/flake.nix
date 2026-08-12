# https://forge.onyx.ovh/eymeric/nixos-pikvm
# https://github.com/pikvm/kvmd/blob/v4.110/PKGBUILD
{
  lib,
  avrdude,
  bash,
  binutils,
  coreutils,
  dnsmasq,
  dos2unix,
  e2fsprogs,
  fetchFromGitHub,
  fontconfig,
  glibc,
  gnugrep,
  gnused,
  ipmitool,
  iproute2,
  iptables,
  janus-gateway,
  kvmd-platform,
  libgpiod,
  libraspberrypi,
  libxkbcommon,
  makeWrapper,
  mount,
  nginx,
  openssl,
  parted,
  python3,
  stdenv,
  sysctl,
  systemd,
  tesseract,
  ustreamer,
  util-linux,
  v4l-utils,
  withTesseract ? false,
}:
let
  srcinfo = import ./src.nix { inherit fetchFromGitHub; };
in
python3.pkgs.buildPythonApplication {
  pname = "kvmd";

  inherit (srcinfo) version src;

  pyproject = true;
  build-system = with python3.pkgs; [ setuptools ];

  propagatedBuildInputs =
    with python3.pkgs;
    [

      aiofiles
      aiohttp
      async-lru
      bcrypt
      binutils
      dbus-next
      dbus-python
      evdev
      hidapi
      python-ldap
      python3.pkgs.libgpiod
      luma-core
      mako
      netifaces
      python-pam
      passlib
      pillow
      psutil
      pyghmi
      pygments
      pyotp
      pyrad
      pyserial
      pyserial-asyncio
      pyudev
      pyusb
      pyyaml
      pysmbc
      paramiko
      qrcode
      ruamel-yaml
      setproctitle
      six
      spidev
      systemd-python
      xlib
      zstandard
    ]
    ++ [
      coreutils
      glibc
      ipmitool
      iproute2
      iptables
      janus-gateway
      libgpiod
      libraspberrypi
      libxkbcommon
      openssl
      systemd
      tesseract
      ustreamer
      util-linux
      v4l-utils
    ];

  nativeBuildInputs = [
    makeWrapper
    bash
  ]
  ++ lib.optional withTesseract tesseract;

  patchPhase = ''
    substituteInPlace setup.py \
      --replace-fail "#!/usr/bin/env python3" "#!${python3}/bin/python3"
    substituteInPlace genmap.py \
      --replace-fail "#!/usr/bin/env python3" "#!${python3}/bin/python3"
    substituteInPlace kvmd/apps/__init__.py \
      --replace-fail "/usr/lib/kvmd/main.yaml" "${kvmd-platform}/lib/kvmd/main.yaml"
    substituteInPlace kvmd/apps/_scheme.py \
      --replace-fail "/usr/share/kvmd" "$out/share/kvmd" \
      --replace-fail "/usr/lib/kvmd/platform" "${kvmd-platform}/lib/kvmd/platform" \
      --replace-fail "/usr/bin/vcgencmd" "${libraspberrypi}/bin/vcgencmd" \
      --replace-fail "/bin/true" "${coreutils}/bin/true" \
      ${lib.optionalString withTesseract "--replace-fail \"/usr/share/tessdata\" \"${tesseract}/share/tessdata\""} \
      --replace-fail "/usr/bin/sudo" "/run/wrappers/bin/sudo" \
      --replace-fail "/usr/bin/kvmd-helper-pst-remount" "$out/bin/kvmd-helper-pst-remount" \
      --replace-fail "/usr/bin/ip" "${iproute2}/bin/ip" \
      --replace-fail "/usr/sbin/iptables" "${iptables}/bin/iptables" \
      --replace-fail "/usr/sbin/sysctl" "${sysctl}/bin/sysctl" \
      --replace-fail "/usr/bin/systemd-run" "${systemd}/bin/systemd-run" \
      --replace-fail "/usr/sbin/dnsmasq" "${dnsmasq}/bin/dnsmasq" \
      --replace-fail "/usr/bin/systemctl" "${systemd}/bin/systemctl" \
      --replace-fail "/usr/bin/janus" "${janus-gateway}/bin/janus" \
      --replace-fail "/usr/lib/ustreamer" "${ustreamer}/lib/ustreamer"
    substituteInPlace kvmd/helpers/remount/__init__.py \
      --replace-fail "/bin/mount" "${mount}/bin/mount"
    substituteInPlace kvmd/apps/edidconf/__init__.py \
      --replace-fail "/usr/bin/v4l2-ctl" "${v4l-utils}/bin/v4l2-ctl" \
      --replace-fail "/usr/share/kvmd" "$out/share/kvmd"
    substituteInPlace kvmd/plugins/ugpio/ipmi.py \
      --replace-fail "/usr/bin/ipmitool" "${ipmitool}/bin/ipmitool"
    substituteInPlace kvmd/plugins/msd/otg/__init__.py \
      --replace-fail "/usr/bin/sudo" "/run/wrappers/bin/sudo" \
      --replace-fail "/usr/bin/kvmd-helper-otgmsd-remount" "$out/bin/kvmd-helper-otgmsd-remount"
    substituteInPlace hid/arduino/avrdude.py \
      --replace-fail "/usr/bin/avrdude" "${avrdude}/bin/avrdude"
    patchShebangs scripts
    substituteInPlace scripts/kvmd-bootconfig \
      --replace-fail "/usr/lib/kvmd/platform" "${kvmd-platform}/lib/kvmd/platform"
    substituteInPlace scripts/kvmd-certbot \
      --replace-fail "/usr/bin/bash" "${bash}/bin/bash" \
      --replace-fail "/usr/bin/touch" "${coreutils}/bin/touch"
    substituteInPlace configs/os/services/systemd-networkd-wait-online.service.d/11-pikvm-wait-any.conf \
      --replace-fail "/usr/lib/systemd/systemd-networkd-wait-online" "${systemd}/lib/systemd/systemd-networkd-wait-online"
    substituteInPlace configs/os/services/kvmd-bootconfig.service \
      --replace-fail "/usr/bin/kvmd-bootconfig" "$out/bin/kvmd-bootconfig" \
      --replace-fail "/bin/true" "${coreutils}/bin/true"
    for service in certbot ipmi janus localhid media oled otg otgnet pst vnc watchdog nbd; do
      substituteInPlace configs/os/services/kvmd-$service.service \
        --replace-fail "/usr/bin/kvmd-$service" "$out/bin/kvmd-$service"
    done
    substituteInPlace configs/os/services/kvmd-janus-static.service \
      --replace-fail "/usr/bin/janus" "${janus-gateway}/bin/janus" \
      --replace-fail "/usr/lib/ustreamer" "${ustreamer}/lib/ustreamer"
    substituteInPlace configs/os/services/kvmd-nginx.service \
      --replace-fail "/usr/bin/kvmd-nginx-mkconf" "$out/bin/kvmd-nginx-mkconf" \
      --replace-fail "/usr/sbin/nginx" "${nginx}/bin/nginx"
    substituteInPlace configs/os/services/kvmd-oled-reboot.service \
      --replace-fail "/bin/bash" "${bash}/bin/bash" \
      --replace-fail "/bin/true" "${coreutils}/bin/true"
    substituteInPlace configs/os/services/kvmd-oled-shutdown.service \
      --replace-fail "/bin/bash" "${bash}/bin/bash" \
      --replace-fail "/bin/true" "${coreutils}/bin/true"
    substituteInPlace configs/os/services/kvmd-tc358743.service \
      --replace-fail "/usr/bin/v4l2-ctl" "${v4l-utils}/bin/v4l2-ctl"
    substituteInPlace configs/os/services/kvmd.service \
      --replace-fail "/usr/bin/kvmd" "$out/bin/kvmd"
    substituteInPlace configs/os/services/kvmd-otg-getty@.service \
      --replace-fail "/usr/bin/agetty" "${util-linux}/bin/agetty"
    substituteInPlace configs/os/modprobe.conf \
      --replace-fail "/bin/false" "${coreutils}/bin/false"

    for conf in configs/nginx/*; do
      substituteInPlace "$conf" \
        --replace-quiet "/usr/share/kvmd" "$out/share/kvmd"
    done

    substituteInPlace configs/nginx/kvmd.ctx-server.conf \
      --replace-fail "/usr/share/janus" "${janus-gateway.doc}/share/janus"
    substituteInPlace configs/os/udev/common.rules \
      --replace-fail "/usr/bin/systemd-escape" "${systemd}/bin/systemd-escape"
    substituteInPlace configs/os/services/kvmd-otg-getty@.service \
      --replace-fail ":/usr/lib/issue.d" ""
    # XXX where is ucamera?
    # substituteInPlace configs/os/services/kvmd-camera@.service \
    #   --replace-fail "/usr/bin/ucamera" ""
  '';

  postInstall = ''
    wrapProgram $out/bin/kvmd \
      --suffix PYTHONPATH : $out/${python3.sitePackages} \
      --suffix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath (
          [
            stdenv.cc.libc
            libxkbcommon
          ]
          ++ lib.optional withTesseract tesseract
        )
      }

    # Install scripts and make it executable
    install -Dm755 -t "$out/bin" scripts/kvmd-{bootconfig,gencert,certbot}
    wrapProgram $out/bin/kvmd-bootconfig \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          systemd
          dos2unix
          parted
          util-linux
          gnused
          e2fsprogs
          fontconfig
          gnugrep
        ]
      }:$out/bin
    wrapProgram $out/bin/kvmd-gencert \
      --prefix PATH : ${
        lib.makeBinPath [
          openssl
          coreutils
        ]
      }
    wrapProgram $out/bin/kvmd-certbot \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          systemd
          gnused
        ]
      }:$out/bin

      # Install systemd files
      install -dm755 "$out/lib/systemd/system"
      cp -rd configs/os/services -T "$out/lib/systemd/system"

      install -DTm644 configs/os/sysusers.conf "$out/lib/sysusers.d/kvmd.conf"
      install -DTm644 configs/os/tmpfiles.conf "$out/lib/tmpfiles.d/kvmd.conf"

      # Install web and keymap files
      mkdir -p $out/share/kvmd
      cp -r {switch,hid,web,extras,contrib/keymaps} "$out/share/kvmd"
      find "$out/share/kvmd/web" -name '*.pug' -exec rm -f '{}' \;

      _cfg_default="$out/share/kvmd/configs.default"
      mkdir -p "$_cfg_default"
      cp -r configs/* "$_cfg_default"
      find "$_cfg_default" -type f -exec chmod 444 '{}' \;
      chmod 400 "$_cfg_default/kvmd"/*passwd
      chmod 400 "$_cfg_default/kvmd"/*.secret
      chmod 750 "$_cfg_default/os/sudoers"
      chmod 400 "$_cfg_default/os/sudoers"/*

      find "$out" -name .gitignore -delete

      mkdir -p "$out/etc/kvmd/"{nginx,vnc}"/ssl"
      chmod 755 "$out/etc/kvmd/"{nginx,vnc}"/ssl"
      install -Dm444 -t "$out/etc/kvmd/nginx" "$_cfg_default/nginx"/*.conf*
      chmod 644 "$out/etc/kvmd/nginx/"{nginx,ssl}.conf*

      mkdir -p "$out/etc/kvmd/janus"
      chmod 755 "$out/etc/kvmd/janus"
      install -Dm444 -t "$out/etc/kvmd/janus" "$_cfg_default/janus"/*.jcfg

      install -Dm644 -t "$out/etc/kvmd" "$_cfg_default/kvmd"/*.yaml
      install -Dm600 -t "$out/etc/kvmd" "$_cfg_default/kvmd"/*passwd
      install -Dm600 -t "$out/etc/kvmd" "$_cfg_default/kvmd"/*.secret
      install -Dm644 -t "$out/etc/kvmd" "$_cfg_default/kvmd"/web.css

      mkdir -p "$out/etc/kvmd/override.d"
  '';

  meta = with lib; {
    description = "KVM over IP for Raspberry Pi and other devices";
    homepage = "https://github.com/pikvm/kvmd";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "kvmd";
    longDescription = ''
      PiKVM daemon - the main daemon that drives a Pi-based KVM over IP device.
      OCR support is ${if withTesseract then "enabled" else "disabled"}.
    '';
  };
}
