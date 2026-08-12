# Command-line utility to automate the Saleae Logic software.
{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  makePythonPath,
  makeWrapper,
  python,
  saleae,
}:

let
  pythonDeps = [ saleae ];
in
buildPythonApplication rec {
  pname = "saleae-cli";
  version = "0-unstable-2021-05-26";
  format = "other";

  src = fetchFromGitHub {
    owner = "saleae";
    repo = "python-saleae-cli";
    rev = "92579585750f99dc679aa9b8b191cda3eb1d91a0";
    hash = "sha256-0yw1c8MU19982Lkk3XD/xKPH/sMEz5kpSrFc9K8ckD4=";
  };

  propagatedBuildInputs = pythonDeps;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    sitepkgs=$out/${python.sitePackages}
    install -Dm644 saleae_cli.py "$sitepkgs/saleae_cli.py"

    makeWrapper ${python.interpreter} "$out/bin/saleae-cli" \
      --set PYTHONPATH "$sitepkgs:${makePythonPath pythonDeps}" \
      --add-flags "$sitepkgs/saleae_cli.py"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Command-line utility to automate the Saleae Logic software";
    homepage = "https://github.com/saleae/python-saleae-cli";
    license = licenses.mit;
    mainProgram = "saleae-cli";
    platforms = platforms.all;
  };
}
