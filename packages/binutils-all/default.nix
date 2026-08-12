# binutils-all: binutils-unwrapped-all-targets with non-gas programs prefixed `all-`.
#
# - Non-gas programs get `all-` prefix (all-ld, all-nm, all-objdump, ...) and
#   support every BFD target (--enable-targets=all).
# - gas (`as`) is built separately for every target binutils supports and keeps
#   its per-target prefix (e.g. x86_64-unknown-linux-gnu-as, arm-none-eabi-as,
#   mips-elf-as, mipsel-elf-as).
#
# The gas target list was derived from binutils' own gas/configure.tgt +
# config.bfd (the authoritative targets gas knows how to assemble for). It is
# far larger than nixpkgs' hardcoded allGasTargets. Each entry uses the triplet
# gas actually accepts (linux-gnu / elf / coff / eabi / aout as appropriate),
# with both little- and big-endian variants (mipsel-elf/mips-elf,
# arm-none-eabi/armeb-none-eabi, mipsel-unknown-linux-gnu/mips-unknown-linux-gnu,
# ...). Every entry was verified to build gas with binutils 2.46.
#
# binutils configure scripts hardcode /usr/bin/file, which is absent on
# non-FHS systems, so we substitute nixpkgs' file into the configure scripts
# (see postPatch) to make format detection work in the Nix build.
#
# Some targets genuinely can't build a standalone gas and are omitted:
#   amdgcn  - GAS has no backend for it
#   pdp11   - gas fails to link (obsolete arch)
#   scorel  - config.sub doesn't accept a little-endian score triplet
#   m32rle  - BFD has no separate m32rle object; m32r-elf assembles both
#             endians via -EL/-EB
{
  binutils-unwrapped-all-targets,
  file,
  lib,
}:
let
  # gasAssemblerTargets: every target gas supports, as concrete triplets.
  gasTargets = [
    # --- Linux ELF ---
    "aarch64-unknown-linux-gnu"
    "aarch64_be-unknown-linux-gnu"
    "alpha-unknown-linux-gnu"
    "am33_2.0-unknown-linux-gnu"
    "arc-unknown-linux-gnu"
    "arm-unknown-linux-gnu"
    "armeb-unknown-linux-gnu"
    "avr-unknown-linux-gnu"
    "cris-unknown-linux-gnu"
    "crisv32-unknown-linux-gnu"
    "csky-unknown-linux-gnu"
    "d10v-unknown-linux-gnu"
    "d30v-unknown-linux-gnu"
    "epiphany-unknown-linux-gnu"
    "frv-unknown-linux-gnu"
    "ft32-unknown-linux-gnu"
    "h8300-unknown-linux-gnu"
    "hppa-unknown-linux-gnu"
    "ia64-unknown-linux-gnu"
    "kvx-unknown-linux-gnu"
    "lm32-unknown-linux-gnu"
    "loongarch32-unknown-linux-gnu"
    "loongarch64-unknown-linux-gnu"
    "m32r-unknown-linux-gnu"
    "m68hc11-unknown-linux-gnu"
    "m68hc12-unknown-linux-gnu"
    "m68k-unknown-linux-gnu"
    "metag-unknown-linux-gnu"
    "microblaze-unknown-linux-gnu"
    "microblazeel-unknown-linux-gnu"
    "mips-unknown-linux-gnu"
    "mips64-unknown-linux-gnu"
    "mips64el-unknown-linux-gnu"
    "mipsel-unknown-linux-gnu"
    "mipsisa32r6-unknown-linux-gnu"
    "mipsisa32r6el-unknown-linux-gnu"
    "mipsisa64r6-unknown-linux-gnu"
    "mipsisa64r6el-unknown-linux-gnu"
    "mmix-unknown-linux-gnu"
    "mn10200-unknown-linux-gnu"
    "mn10300-unknown-linux-gnu"
    "msp430-unknown-linux-gnu"
    "nds32be-unknown-linux-gnu"
    "nds32le-unknown-linux-gnu"
    "or1k-unknown-linux-gnu"
    "or1knd-unknown-linux-gnu"
    "pj-unknown-linux-gnu"
    "pjl-unknown-linux-gnu"
    "powerpc-unknown-linux-gnu"
    "powerpcle-unknown-linux-gnu"
    "powerpc64-unknown-linux-gnu"
    "powerpc64le-unknown-linux-gnu"
    "pru-unknown-linux-gnu"
    "riscv-unknown-linux-gnu"
    "riscv64-unknown-linux-gnu"
    "riscv64be-unknown-linux-gnu"
    "rx-unknown-linux-gnu"
    "s12z-unknown-linux-gnu"
    "s390-unknown-linux-gnu"
    "s390x-unknown-linux-gnu"
    "sh-unknown-linux-gnu"
    "shle-unknown-linux-gnu"
    "sparc-unknown-linux-gnu"
    "sparc64-unknown-linux-gnu"
    "tilegx-unknown-linux-gnu"
    "tilegxbe-unknown-linux-gnu"
    "tilepro-unknown-linux-gnu"
    "v850-unknown-linux-gnu"
    "vax-unknown-linux-gnu"
    "wasm32-unknown-linux-gnu"
    "x86_64-unknown-linux-gnu"
    "xgate-unknown-linux-gnu"
    "xtensa-unknown-linux-gnu"

    # --- bare-metal (ELF / coff / eabi / none), incl. LE+BE ---
    "aarch64-none-elf"
    "aarch64_be-none-elf"
    "arc-elf"
    "arceb-elf"
    "arm-none-eabi"
    "armeb-none-eabi"
    "avr-unknown-elf"
    "bfin-elf"
    "bpf-unknown-none"
    "cr16-elf"
    "cris-elf"
    "crx-elf"
    "csky-elf"
    "d10v-elf"
    "d30v-elf"
    "dlx-elf"
    "epiphany-elf"
    "fido-elf"
    "fr30-elf"
    "frv-elf"
    "ft32-elf"
    "h8300-elf"
    "i386-elf"
    "x86_64-elf"
    "ia16-elf"
    "ip2k-elf"
    "iq2000-elf"
    "kvx-elf"
    "lm32-elf"
    "loongarch32-elf"
    "loongarch64-elf"
    "m32c-elf"
    "m32r-elf"
    "m68hc11-elf"
    "m68hc12-elf"
    "m68k-elf"
    "mcore-elf"
    "mep-elf"
    "metag-elf"
    "microblaze-elf"
    "microblazeel-elf"
    "mips-elf"
    "mips64-elf"
    "mips64el-elf"
    "mipsel-elf"
    "mipsisa32r6-elf"
    "mipsisa32r6el-elf"
    "mipsisa64r6-elf"
    "mipsisa64r6el-elf"
    "mmix-elf"
    "mn10200-elf"
    "mn10300-elf"
    "moxie-elf"
    "msp430-elf"
    "mt-elf"
    "nds32be-elf"
    "nds32le-elf"
    "ns32k-pc532-mach"
    "or1k-elf"
    "or1knd-elf"
    "pj-elf"
    "pjl-elf"
    "powerpc-none-elf"
    "powerpcle-none-elf"
    "powerpc64-none-elf"
    "powerpc64le-none-elf"
    "pru-elf"
    "riscv32-elf"
    "riscv32be-elf"
    "riscv64-elf"
    "riscv64be-elf"
    "rl78-elf"
    "rx-elf"
    "s12z-elf"
    "score-elf"
    "sh-elf"
    "shle-elf"
    "sparc-elf"
    "sparc64-elf"
    "spu-elf"
    "tic30-unknown-coff"
    "tic4x-unknown-coff"
    "tic54x-unknown-coff" # c54x only supports COFF
    "tic6x-elf"
    "tilegx-elf"
    "tilegxbe-elf"
    "tilepro-elf"
    "v850-elf"
    "visium-elf"
    "xgate-elf"
    "xstormy16-elf"
    "xtensa-elf"
    "z80-unknown-coff"
    "z8k-unknown-coff"
  ];
in
(binutils-unwrapped-all-targets.overrideAttrs (old: {
  pname = "binutils-all";

  # binutils configure scripts hardcode /usr/bin/file, which doesn't exist on
  # non-FHS systems (NixOS). Point them at nixpkgs' file instead so the output
  # format detection (and thus gas builds) works everywhere.
  postPatch = (old.postPatch or "") + ''
    for f in $(find . -type f -name configure); do
      substituteInPlace "$f" --replace '/usr/bin/file' '${file}/bin/file'
    done
  '';

  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ file ];
  # sanity.sh expects unprefixed names like `$out/bin/size`; with the `all-`
  # prefix the binaries are all-size etc., so the install check cannot pass.
  doInstallCheck = false;

  # Prefix every non-gas program with `all-`. The per-target gas builds pass
  # `--program-prefix "$target-"` after this flag, so gas keeps its target
  # prefix instead of `all-`.
  configureFlags = map (
    f: if lib.hasPrefix "--program-prefix=" f then "--program-prefix=all-" else f
  ) old.configureFlags;

  # Configure a separate gas build for every target.
  postConfigure = ''
    for target in ${lib.escapeShellArgs gasTargets}; do
      mkdir -p "$NIX_BUILD_TOP/build-$target"
      env -C "$NIX_BUILD_TOP/build-$target" \
        "$configureScript" $configureFlags "''${configureFlagsArray[@]}" \
        --enable-targets="$target" --enable-gas --disable-ld --disable-gold \
        --disable-gprofng --program-prefix "$target-" \
        --target "$target"
    done
  '';

  # Build gas for every target.
  postBuild = ''
    for target in ${lib.escapeShellArgs gasTargets}; do
      make -C "$NIX_BUILD_TOP/build-$target" -j"$NIX_BUILD_CORES" \
        $makeFlags "''${makeFlagsArray[@]}" $buildFlags "''${buildFlagsArray[@]}" \
        TARGET-gas=as-new all-gas
    done
  '';

  # Install gas into $out/bin with its target prefix.
  postInstall = ''
    for target in ${lib.escapeShellArgs gasTargets}; do
      make -C "$NIX_BUILD_TOP/build-$target/gas" -j"$NIX_BUILD_CORES" \
        $makeFlags "''${makeFlagsArray[@]}" $installFlags "''${installFlagsArray[@]}" \
        install-exec-bindir
    done
  '';
}))
