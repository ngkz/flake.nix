# NixOS VM test for overlayfs-tools: runs the upstream test fixtures against
# `overlay diff|merge` and mounts the merged layer. `trusted.overlay.*` xattrs
# and overlayfs mounts require CAP_SYS_ADMIN in init_user_ns, so the test runs
# as root in a VM (not in a user namespace, not in the build sandbox).
{ pkgs, ovl }:
let
  fixtures = "${ovl.src}/test_cases";
  # tmpfs in the VM: supports trusted xattrs and overlayfs upper layers
  w = "/dev/shm/t";
in
pkgs.testers.nixosTest {
  name = "overlayfs-tools";
  nodes.vm = {
    boot.kernelModules = [ "overlay" ];
    environment.systemPackages = [
      ovl
      pkgs.attr
    ];
    virtualisation = {
      memorySize = 4096;
      diskSize = 12;
    };
  };
  testScript = ''
    vm.start()
    vm.wait_for_unit("multi-user.target")
    vm.succeed("overlay --version; fsck.overlay -V")
    vm.succeed("modprobe overlay && lsmod | grep -q overlay")

    with subtest("fixture"):
        vm.succeed("rm -rf ${w} && mkdir -p ${w}")
        vm.succeed("cd ${w} && tar xf ${fixtures}/lower.tar")
        vm.succeed("cd ${w} && tar xf ${fixtures}/upper.tar --strip-components=2")
        # same fixture post-processing as upstream meson.build
        vm.succeed(
            "cd ${w}"
            + " && setfattr -n trusted.overlay.opaque -v y changes/removed_tests/replaced_by_opaque"
            + " && setfattr -n trusted.overlay.opaque -v y changes/normal_merged_dir/more_test/by_opaque"
            + " && setfattr -n trusted.overlay.metacopy -v y changes/permission/file"
            + " && truncate -s 0 changes/permission/file && truncate -s 95 changes/permission/file"
            + " && mkdir -p changes/renamed_dir"
            + " && setfattr -n trusted.overlay.redirect -v /removed_tests/removed_dir changes/renamed_dir"
        )

    with subtest("diff"):
        vm.succeed("cd ${w} && overlay -l permanent -u changes diff | sort -u > diff.out")
        vm.succeed("diff -u ${fixtures}/diff.saved ${w}/diff.out")
        print("diff == upstream diff.saved")

    with subtest("diff -v"):
        vm.succeed("cd ${w} && overlay -l permanent -u changes diff -v | sort -u > verbose.out")
        vm.succeed("diff -u ${fixtures}/verbose.saved ${w}/verbose.out")
        print("diff -v == upstream verbose.saved")

    with subtest("diff -b"):
        vm.succeed("cd ${w} && overlay -l permanent -u changes diff -b | sort -u > brief.out")
        print("brief entries:", vm.succeed("wc -l < ${w}/brief.out"))
        for pat in [
            "Only in ${w}/changes/modified_dir: created",
            "Only in ${w}/changes/modified_dir/sub_1/sub_2: added_file",
            "Only in ${w}/changes/normal_merged_dir: only_new",
            "Only in ${w}/permanent/removed_tests: removed_dir",
            "Files ${w}/permanent/modified_dir/sub_1/sub_2/sub_3/file and ${w}/changes/modified_dir/sub_1/sub_2/sub_3/file differ",
            "Symbolic links ${w}/permanent/normal_merged_dir/changed_symlink and ${w}/changes/normal_merged_dir/changed_symlink differ",
        ]:
            vm.succeed("grep -F '" + pat + "' ${w}/brief.out")
        added = int(vm.succeed("grep -c '^Added: ' ${w}/diff.out"))
        removed = int(vm.succeed("grep -c '^Removed: ' ${w}/diff.out"))
        brief_added = int(vm.succeed("grep -c '^Only in ${w}/changes/' ${w}/brief.out"))
        brief_removed = int(vm.succeed("grep -c '^Only in ${w}/permanent/' ${w}/brief.out"))
        assert added > 0 and removed > 0 and brief_added > 0 and brief_removed > 0
        print(
            "diff: added=" + str(added) + " removed=" + str(removed)
            + " | diff -b: only-in-upper=" + str(brief_added) + " only-in-lower=" + str(brief_removed)
        )
        # expected merged tree, plus the directory the redirect dir renames to
        vm.succeed("cd ${w} && tar xf ${fixtures}/overlayed.tar")
        vm.succeed("cd ${w} && cp -a permanent/removed_tests/removed_dir overlayed/renamed_dir")

    with subtest("merge"):
        # upstream drops the redirect dir before merging
        vm.succeed("cd ${w} && rm -rf changes/renamed_dir && overlay -l permanent -u changes merge -f")
        out = vm.succeed(
            "cd ${w} && diff -qr --no-dereference --exclude=renamed_dir permanent overlayed 2>&1 || true"
        )
        print("merged tree vs expected:", repr(out))
        assert out.strip() == "", out
        print("merged upperdir == expected merged tree")

    with subtest("merged upperdir is mountable"):
        vm.succeed(
            "cd ${w} && mkdir -p work lower mnt"
            + " && mount -t overlay -o lowerdir=lower,upperdir=permanent,workdir=work overlay mnt"
        )
        print("files visible:", vm.succeed("find ${w}/mnt -type f | wc -l"))
        vm.succeed("find ${w}/mnt -type f -exec cat {} + > /dev/null")
        vm.succeed("umount ${w}/mnt")

    print("ALL OK")
  '';
}
