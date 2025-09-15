{ self, inputs, ... }:

{
  flake.nixosModules.orianne =
    { config, keys, ... }:
    {
      imports = [
        ../_common/server.nix

        self.nixosModules.keys
        self.nixosModules.secrets

        inputs.agenix.nixosModules.default

        ./cloud.nix
        ./hardware-configuration.nix
        ./medias.nix
        ./motd.nix
        ./nginx.nix
        ./starship.nix
        ./storage.nix
      ];

      x_niols.thisDevicesName = "Orianne";
      x_niols.hostPublicKey = self.keys.machines.${config.x_niols.thisDevicesNameLower};

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      users.users = {
        niols.hashedPasswordFile =
          config.age.secrets."password-${config.x_niols.thisDevicesNameLower}-niols".path;
        root.openssh.authorizedKeys.keys = [
          keys.github-actions."deploy-${config.x_niols.thisDevicesNameLower}"
        ];
      };
    };

  flake.nixops4Resources.orianne =
    { providers, ... }:
    {
      type = providers.local.exec;
      imports = [ inputs.nixops4-nixos.modules.nixops4Resource.nixos ];

      ssh = {
        host = "89.168.38.231";
        opts = "";
        hostPublicKey = self.keys.machines.orianne;
      };

      nixpkgs = inputs.nixpkgs;
      nixos.module = {
        imports = [ self.nixosModules.orianne ];
      };
    };
}
