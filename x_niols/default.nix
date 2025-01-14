{
  flake.nixosModules.x_niols = {
    imports = [ ./autoreboot.nix ];
  };
}
