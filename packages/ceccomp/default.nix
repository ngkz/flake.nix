# ceccomp - seccomp-tools reimplementation in C: filter assembler, disassembler
# and sandbox inspector, with eBPF-powered filter capture.
{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  asciidoctor,
  bpftools,
  flock,
  gettext,
  libbpf,
  libseccomp,
  llvmPackages,
  pkg-config,
  python3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ceccomp";
  version = "4.3.1";

  src = fetchFromGitHub {
    owner = "ceccomp";
    repo = "ceccomp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-p0LxQccKGyfT4pZJgJ6lW1rNG8MezwIzAICgMc7drKI=";
  };

  # configure is a python script, Makefile progress output needs flock, bpftools
  # dumps vmlinux.h and generates the BPF skeletons, llvm provides llvm-strip for
  # the BPF objects
  nativeBuildInputs = [
    asciidoctor
    bpftools
    flock
    gettext
    llvmPackages.llvm
    pkg-config
    python3
  ];

  # pytest needs the command, not only the importable module
  nativeCheckInputs = [ (python3.withPackages (ps: [ ps.pytest ])) ];

  buildInputs = [
    libbpf
    libseccomp
  ];

  # unwrapped clang: the cc-wrapper hardening flags (-fzero-call-used-regs)
  # are rejected for -target bpf, and the unwrapped compiler needs the libbpf
  # headers spelled out (BPF_CFLAGS for the objects, --includedir for the
  # configure probe)
  env.BPF_CC = "${llvmPackages.clang-unwrapped}/bin/clang";

  env.BPF_CFLAGS = "-isystem ${libbpf}/include";

  configureScript = "${lib.getExe python3} ./configure";

  configureFlags = [
    "--packager=Nix"
    # link with -s instead of -g
    "--debug-level=0"
    "--includedir=${libbpf}/include"
    # The BPF objects are CO-RE: offsets get relocated against the running
    # kernel at program load, so any vmlinux.h with seccomp filter support
    # works. configure dumps it from the packaged kernel's vmlinux because the
    # checked-in header sets in the wild do not: libbpf's snapshots have an
    # empty `struct seccomp` and eunomia-bpf's predate `filter_count`.
    "--vmlinuxdir=${kernel.dev}"
  ];

  # Upstream has no `make check`. pytest runs build/ceccomp directly; the
  # trace-pid and capture cases skip without CAP_SYS_ADMIN.
  doCheck = true;

  checkPhase = "pytest";

  enableParallelBuilding = true;

  meta = {
    description = "seccomp filter assembler, disassembler and sandbox inspector in C";
    homepage = "https://github.com/ceccomp/ceccomp";
    changelog = "https://github.com/ceccomp/ceccomp/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.gpl3Plus;
    mainProgram = "ceccomp";
    platforms = lib.platforms.linux;
  };
})
