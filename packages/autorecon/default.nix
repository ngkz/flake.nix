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
  # wordlists referenced by the hardcoded plugin/config defaults
  seclists,
}:

let
  seclistsBase = "${seclists}/share/wordlists/seclists";
  # Upstream SecLists renamed the DirBuster directory lists
  dirbusterMediumList = "DirBuster-2007_directory-list-2.3-medium.txt";
in

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

  # Store path baked into the installed plugin/config files by postPatch
  buildInputs = [ seclists ];

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

  # AutoRecon hardcodes Kali wordlist paths. Rewrite them to the seclists
  # package, mapping the lists upstream SecLists has since renamed. Most
  # specific pattern first: the bare prefix is replaced last.
  postPatch = ''
    replace_path() {
      for file in $(grep -rlF -- "$1" autorecon); do
        substituteInPlace "$file" --replace-fail "$1" "$2"
      done
    }

    replace_path '/usr/share/seclists/Passwords/darkweb2017-top100.txt' \
      '${seclistsBase}/Passwords/Common-Credentials/darkweb2017_top-100.txt'
    replace_path '/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt' \
      '${seclistsBase}/Discovery/Web-Content/${dirbusterMediumList}'
    replace_path '/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt' \
      '${seclistsBase}/Discovery/Web-Content/${dirbusterMediumList}'
    replace_path '/usr/share/seclists' '${seclistsBase}'
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
