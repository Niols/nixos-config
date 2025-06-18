{ self, inputs, ... }:

{
  flake.nixosModules.orianne =
    { config, keys, ... }:
    {
      imports = [
        (import ../_common).server

        ./cloud.nix
        ./hardware-configuration.nix
        ./hostname.nix
        ./medias.nix
        ./motd.nix
        ./nginx.nix
        ./starship.nix
        ./storage.nix
        ./system.nix
        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        ./home-manager.nix
        {
          _module.args = {
            inherit (inputs) nixpkgs;
          };
        }
        self.nixosModules.x_niols
        self.nixosModules.keys
        self.nixosModules.secrets
        { x_niols.hostPublicKey = self.keys.machines.orianne; }
      ];

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

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
