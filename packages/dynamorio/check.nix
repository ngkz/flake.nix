# Functional check for pkgs.ngkz.dynamorio: injecting into a live process.
#
# DynamoRIO ships a self-contained runtime tree (bin64, lib64, ext, tools) that
# it resolves relative to the executable, and its frontends write into that
# tree.  A successful build says nothing about that layout, about the Perl
# scripts among the tools, or about the private ELF loader that maps the client
# dependency chain.
{ pkgs, dynamorio }:
pkgs.runCommand "dynamorio-check" { nativeBuildInputs = [ dynamorio ]; } ''
  set -eu -o pipefail
  # The frontend lib writes $HOME/.__drfrontendlib_tmp before it falls back.
  export HOME="$TMPDIR"
  cd "$(mktemp -d)"

  # Instrumentation through a sample client: the app must run and the client
  # must report the count it collected from the code cache.
  drrun -quiet -c ${dynamorio}/opt/dynamorio/samples/bin64/libinscount.so -- \
    ${pkgs.bash}/bin/bash -c 'exit 0' > inscount.log 2>&1
  grep -q "instructions executed" inscount.log

  # Basic block coverage tool: drcov pulls in the drx, drreg, drmgr and
  # drcovlib extensions, so this covers extension loading as well.
  drrun -quiet -t drcov -- ${pkgs.coreutils}/bin/ls .
  test -n "$(ls drcov.*)"

  # genhtml is an installed Perl script; the wrapper must supply the
  # interpreter.  It exits non-zero on the missing argument.
  genhtml > genhtml.log 2>&1 || true
  grep -q "No filename specified" genhtml.log

  # Memory trace: the client is libdrmemtrace.so, whose dependency chain drags
  # in libc.so.6, so DynamoRIO's private loader has to resolve
  # ld-linux-x86-64.so.2.  The wrapper's LD_LIBRARY_PATH must name the real
  # loader, not the NixOS /lib64 stub.
  mkdir raw
  drrun -quiet -t drmemtrace -offline -outdir raw -- ${pkgs.coreutils}/bin/true
  trace=""
  for f in $(find raw -type f -name '*.raw*'); do
    if test -z "$trace"; then
      trace="$f"
    fi
  done
  test -n "$trace"

  # Offline post-processing: turn the raw files into a trace the analyzers read.
  mkdir out
  drraw2trace -indir "$(dirname "$trace")" -out out
  test -n "$(ls out)"

  touch $out
''
