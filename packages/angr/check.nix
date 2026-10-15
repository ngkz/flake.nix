# Functional check for pkgs.ngkz.angr: solve a crackme by symbolic execution.
#
# Needed in addition to pythonImportsCheck: angr imports cleanly even when its
# vendored Rust solver bridge (native/clarirs-z3) links an incompatible libz3, in
# which case reading any solution back from a solver model fails and angr can no
# longer report results.
{ pkgs, angr }:
let
  python = pkgs.python3.withPackages (ps: [ angr ]);
in
pkgs.runCommandCC "angr-check"
  {
    nativeBuildInputs = [ python ];
  }
  ''
    export HOME=$TMPDIR
    cc -O1 -no-pie -o crackme ${./test/crackme.c}
    cp ${./test/test_angr.py} test_angr.py
    python test_angr.py
    touch $out
  ''
