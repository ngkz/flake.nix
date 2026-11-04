# autorecon - Multi-threaded network reconnaissance tool
{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  poetry-core,
  makeWrapper,
  colorama,
  impacket,
  platformdirs,
  psutil,
  requests,
  toml,
  unidecode,
  # external programs invoked by AutoRecon plugins
  curl,
  dnsutils,
  dirb,
  dirsearch,
  dnsrecon,
  enum4linux,
  enum4linux-ng,
  feroxbuster,
  ffuf,
  gobuster,
  hydra,
  nbtscan,
  nikto,
  nmap,
  onesixtyone,
  redis,
  rsync,
  nfs-utils,
  samba,
  smbmap,
  net-snmp,
  sslscan,
  whatweb,
  oscanner,
  tnscmd10g,
}:

buildPythonApplication rec {
  pname = "autorecon";
  version = "2.0.36-unstable-2026-11-03";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "AutoRecon";
    repo = "AutoRecon";
    rev = "bf40763dcc58f547680645616b1ee4155baf2e7a";
    hash = "sha256-t/Iv0W1qePbMyCRa/zr86WunfSKBX2Jjsuggf3WqC/I=";
  };

  build-system = [ poetry-core ];

  dependencies = [
    colorama
    impacket
    platformdirs
    psutil
    requests
    toml
    unidecode
  ];

  pythonRelaxDeps = [
    "impacket"
    "psutil"
  ];

  nativeBuildInputs = [ makeWrapper ];

  # Runtime tools AutoRecon invokes via PATH. impacket-getArch / impacket-rpcdump
  # come from the impacket Python dependency above.
  runtimeTools = [
    curl
    dnsutils
    dirb
    dirsearch
    dnsrecon
    enum4linux
    enum4linux-ng
    feroxbuster
    ffuf
    gobuster
    hydra
    nbtscan
    nikto
    nmap
    onesixtyone
    redis
    rsync
    nfs-utils
    samba
    smbmap
    net-snmp
    sslscan
    whatweb
    oscanner
    tnscmd10g
  ];

  postFixup = ''
    makeWrapper "$out/bin/.autorecon-wrapped" "$out/bin/autorecon" \
      --prefix PATH : ${lib.makeBinPath runtimeTools}
  '';

  doCheck = false;

  pythonImportsCheck = [ "autorecon" ];

  meta = {
    description = "Multi-threaded network reconnaissance tool for automated service enumeration";
    homepage = "https://github.com/AutoRecon/AutoRecon";
    license = lib.licenses.gpl3Only;
    mainProgram = "autorecon";
    platforms = lib.platforms.linux;
  };
}
