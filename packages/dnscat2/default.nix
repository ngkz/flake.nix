# dnscat2 - C2 server and client that tunnel data over DNS
#
# The server (server/dnscat2.rb) needs the ruby gems pinned in
# server/Gemfile.lock: trollop, salsa20, sha3, ecdsa. None of these exist in
# the nixpkgs ruby gem cache, so we build and merge them manually with
# buildRubyGem (following pkgs/development/ruby-modules/with-packages).
# salsa20 and sha3 ship native extensions; they build fine against ruby 3.4.
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  makeWrapper,
  buildEnv,
  buildRubyGem,
  gcc,
  ruby,
}:

let
  # Gem sha256 from https://rubygems.org/api/v1/versions/<gem>.json
  serverGems = [
    (buildRubyGem {
      gemName = "ecdsa";
      version = "1.2.0";
      src = fetchurl {
        url = "https://rubygems.org/downloads/ecdsa-1.2.0.gem";
        sha256 = "b8f7c9541b6c587cbe37e705a1b76be6dc1e85336aa23ac3cf2f07b038bcec55";
      };
    })
    (buildRubyGem {
      gemName = "trollop";
      version = "2.1.2";
      src = fetchurl {
        url = "https://rubygems.org/downloads/trollop-2.1.2.gem";
        sha256 = "88422e8137b1e635ed07f6b8480c2c2a16d3ac1288023688c4da20d786f12510";
      };
    })
    (buildRubyGem {
      gemName = "salsa20";
      version = "0.1.1";
      src = fetchurl {
        url = "https://rubygems.org/downloads/salsa20-0.1.1.gem";
        sha256 = "1a69332fb3d2380a80acf899cd9aae95b88a27fce8d8512a491ac0b627e3ecba";
      };
      dontBuild = false;
      buildInputs = [ gcc ];
    })
    (buildRubyGem {
      gemName = "sha3";
      version = "1.0.1";
      src = fetchurl {
        url = "https://rubygems.org/downloads/sha3-1.0.1.gem";
        sha256 = "a88967e22b0f1cf8edb901ae4d83b6f26b74ea525a899165dd87ebb38cfdbd01";
      };
      dontBuild = false;
      buildInputs = [ gcc ];
    })
  ];

  gemEnv = buildEnv {
    name = "dnscat2-gems";
    paths = serverGems;
    pathsToLink = [
      "/lib"
      "/bin"
    ];
  };
in
stdenv.mkDerivation {
  pname = "dnscat2";
  version = "0.07-unstable-2022-01-03";

  src = fetchFromGitHub {
    owner = "iagox86";
    repo = "dnscat2";
    rev = "42f8d783488836c0e24ff25571684170be0a0cc2";
    hash = "sha256-fMll+T3sbl4daw8GAVUnNexeA2xWZR7Aw6jxfUByrTw=";
  };

  enableParallelBuilding = true;

  nativeBuildInputs = [ makeWrapper ];

  # Build the C client only. The server is ruby, no build step needed.
  buildPhase = ''
    runHook preBuild
    make -C client -j"$NIX_BUILD_CORES"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # C client
    install -Dm755 client/dnscat "$out/bin/dnscat"

    # Ruby server. The script resolves its libs relative to
    # File.dirname(__FILE__), so keep the server/ tree intact.
    mkdir -p "$out/lib/dnscat2" "$out/bin"
    cp -r server "$out/lib/dnscat2/server"

    # Launch the server with the bundled gems (GEM_PATH pattern from
    # pkgs/development/ruby-modules/with-packages).
    makeWrapper ${ruby}/bin/ruby "$out/bin/dnscat2" \
      --add-flags "$out/lib/dnscat2/server/dnscat2.rb" \
      --set GEM_PATH "${gemEnv}/${ruby.gemPath}"

    runHook postInstall
  '';

  meta = {
    description = "C2 server and client for tunneling data over DNS";
    homepage = "https://github.com/iagox86/dnscat2";
    license = lib.licenses.bsd3;
    mainProgram = "dnscat2";
    platforms = lib.platforms.linux;
  };
}
