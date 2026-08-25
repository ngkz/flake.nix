{
  stdenvNoCC,
  fetchFromGitHub,
  gtk3,
  adwaita-icon-theme,
  adwaita-icon-theme-legacy,
  hicolor-icon-theme,
  morewaita-icon-theme,
  bash,
  gnused,
  lib,
}:

stdenvNoCC.mkDerivation rec {
  pname = "adwaita-colors-icon-theme";
  version = "2.6";

  src = fetchFromGitHub {
    owner = "dpejoh";
    repo = "Adwaita-colors";
    rev = "v${version}";
    hash = "sha256-EncnmE5Ck7QnebyU5zW4L5yV9wIW2yLr4lB1FgqG+0A=";
  };

  meta = with lib; {
    description = "Colorized variant of the Adwaita icon theme";
    homepage = "https://github.com/dpejoh/Adwaita-colors";
    license = licenses.gpl3Plus;
    platforms = platforms.all;
  };

  patches = [
    ./nix.patch
  ];

  nativeBuildInputs = [
    gtk3
    bash
    gnused
  ];

  propagatedBuildInputs = [
    adwaita-icon-theme
    adwaita-icon-theme-legacy
    hicolor-icon-theme
    morewaita-icon-theme
  ];

  dontDropIconThemeCache = true;
  dontPatchELF = true;
  dontRewriteSymlinks = true;

  postPatch = ''
    patchShebangs .
    sed -i "/ADWAITA_PATHS=(/,/)/c\ADWAITA_PATHS=(${adwaita-icon-theme}/share/icons/Adwaita)" variants.conf
    sed -i "/possible_paths=(/,/)/c\possible_paths=(${morewaita-icon-theme}/share/icons $out/share/icons)" morewaita.sh
  '';

  installPhase = ''
    runHook preInstall

    ./setup -i -f -p $out/share/icons
    ./morewaita.sh

    # XXX Adwaita-blue keeps upstream symlinks but deduplicates the identity-colored target.
    cp ${adwaita-icon-theme}/share/icons/Adwaita/scalable/places/folder.svg \
      $out/share/icons/Adwaita-blue/scalable/places/folder.svg

    runHook postInstall
  '';
}
