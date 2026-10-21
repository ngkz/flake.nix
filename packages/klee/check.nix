# Functional check for pkgs.ngkz.klee: symbolic execution of two crackmes, then
# replay of the generated tests as native binaries.
#
# Needed in addition to the derivation's doCheck (upstream unit + lit suite): the
# packaged pieces are built separately, so klee-uclibc bitcode, the LLVM 18
# bitcode compiler, the STP/Z3 bridges and the replay tools can each be fine and
# still fail at run time.
{ pkgs, klee }:
pkgs.runCommand "klee-check"
  {
    nativeBuildInputs = [
      klee
      # KLEE links against LLVM 18, so the bitcode under test must come from the
      # same LLVM major version.
      pkgs.llvmPackages_18.clang
    ];
  }
  ''
    set -eu -o pipefail
    export HOME="$TMPDIR"
    cd "$(mktemp -d)"

    # POSIX runtime: the target path needs "ngkz" on stdin.
    clang -emit-llvm -c -g -O0 ${./test/symread.c} -o symread.bc
    cc -g -O0 ${./test/symread.c} -o symread
    klee --output-dir=posix --posix-runtime symread.bc --sym-stdin 4
    test "$(ls posix/*.ktest | wc -l)" -eq 5

    # klee-replay exits 0 for every case, so read its report: exactly one
    # replayed test may exit with the target status.
    normal=0
    for t in posix/*.ktest; do
      if klee-replay ./symread "$t" 2>&1 | grep -q "EXIT STATUS: NORMAL"; then
        normal=$((normal + 1))
      fi
    done
    test "$normal" -eq 1

    # KLEE runtime: the target path needs x == 1234. Check both solver bridges.
    clang -I ${klee}/include -emit-llvm -c -g -O0 ${./test/crackme.c} -o crackme.bc
    cc -I ${klee}/include -g -O0 ${./test/crackme.c} -o crackme -L ${klee}/lib -lkleeRuntest
    for backend in stp z3; do
      klee --output-dir=crackme-$backend --solver-backend=$backend crackme.bc \
        > crackme-$backend.log 2>&1
      # x <= 100; x > 100 && x != 1234; x == 1234
      grep -q "done: generated tests = 3" crackme-$backend.log
      hits=0
      for t in crackme-$backend/*.ktest; do
        if LD_PRELOAD=${klee}/lib/libkleeRuntest.so KTEST_FILE="$PWD/$t" ./crackme; then
          ktest-tool "$t" | grep -q "int : 1234"
          hits=$((hits + 1))
        fi
      done
      test "$hits" -eq 1
    done

    touch $out
  ''
