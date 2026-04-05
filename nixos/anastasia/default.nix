{
  flake.nixosModules.anastasia =
    { modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ../_common/server.nix
        ./hardware.nix
      ];

      x_niols.thisMachinesName = "anastasia";
      x_niols.thisMachinesColour = "purple";
      x_niols.enableNiolsUser = true;

      nixpkgs.hostPlatform = "x86_64-linux";
    };
}
