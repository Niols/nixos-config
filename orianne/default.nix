{ self, inputs, ... }:

{
  flake.nixosModules.orianne =
    { config, keys, ... }:
    {
      _module.args = {
        inherit (inputs) nixpkgs;
      };

      imports = [
        (import ../_common).server

        self.nixosModules.keys
        self.nixosModules.secrets

        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.home-manager

        ./cloud.nix
        ./hardware-configuration.nix
        ./medias.nix
        ./motd.nix
        ./nginx.nix
        ./starship.nix
        ./storage.nix
      ];

      x_niols.hostPublicKey = self.keys.machines.orianne;

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      networking.hostName = "orianne";

      users.users = {
        niols.hashedPasswordFile = config.age.secrets.password-orianne-niols.path;
        root.openssh.authorizedKeys.keys = [ keys.github-actions.deploy-orianne ];
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
