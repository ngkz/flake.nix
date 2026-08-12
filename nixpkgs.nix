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
  ];
}
