# Nixpkgs config
{
  self,
  devshell,
  ...
}@inputs:
{
  overlays = with self.overlays; [
    devshell.overlays.default
    unstable
    packages
  ];
  config.allowUnfree = true;
  config.permittedInsecurePackages = [
    "pnpm-9.15.9"
    # umap2 / kittyfuzzer require python2
    "python-2.7.18.12"
    "python2.7-setuptools-44.0.0"
    "python2.7-pip-20.3.4"
  ];
}
