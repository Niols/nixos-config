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

      ## In lack of a better place, here are Anastasia's ethernet ports,
      ## physically from left to right:
      ##
      ## | 1 | enp1s0 | 2.5G | e4:3a:6e:85:83:3f |
      ## | 2 | enp2s0 |  10G | e4:3a:6e:85:83:40 |
      ## | 3 | enp5s0 | 2.5G | e4:3a:6e:85:84:38 |
    };
}
