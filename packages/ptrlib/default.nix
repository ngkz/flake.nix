{
  lib,
  pythonOlder,
  buildPythonPackage,
  pycryptodome,
  fetchFromGitHub,
  setuptools,
}:
buildPythonPackage {
  pname = "ptrlib";
  version = "3.1.2";

  src = fetchFromGitHub {
    owner = "ptr-yudai";
    repo = "ptrlib";
    rev = "3bc14a428feb99fa01ed0d29701fbb4e7688b151";
    hash = "sha256-dY+gU5TtfEMWS2+elFQ4+181Pc9aQlzX2Ly3yYFH+PU=";
  };

  propagatedBuildInputs = [ pycryptodome ];
  pythonImportsCheck = [ "ptrlib" ];
  disabled = pythonOlder "3.10";
  pyproject = true;
  build-system = [ setuptools ];

  postBuild = ''
    # remove broken entrypoint
    rm -rf $out/bin
  '';

  meta = with lib; {
    description = "CTF library";
    longDescription = ''
      Ptrlib is a Python library for CTF players. It's designed to make it easy to
      write complex programs for cryptography, networking, exploits, and more.

      Optional features may require external programs:
      - SSH: ssh
      - IntelCPU.assemble: gcc+objcopy, nasm, or keystone-engine
      - IntelCPU.disassemble: objdump or capstone
      - ArmCPU/MipsCPU: cross-architecture compilers
    '';
    homepage = "https://github.com/ptr-yudai/ptrlib";
    license = licenses.mit;
  };
}
