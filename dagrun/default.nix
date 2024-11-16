{ self, inputs, ... }:

{
  flake.nixosModules.dagrun = {
    imports = [
      ./boot.nix
      ./dancelor.nix
      ./databases.nix
      ./hardware-configuration.nix
      ./hostname.nix
      ./matrix.nix
      ./motd.nix
      ./nginx.nix
      ./nix.nix
      ./packages.nix
      ./ssh.nix
      ./starship.nix
      ./storage.nix
      ./system.nix
      ./users.nix
      inputs.agenix.nixosModules.default
      inputs.dancelor.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      ./home-manager.nix
      {
        _module.args = {
          inherit (inputs) secrets nixpkgs;
        };
      }
    ];
  };

  flake.nixops4Resources.dagrun =
    { providers, ... }:
    {
      type = providers.local.exec;
      imports = [ inputs.nixops4-nixos.modules.nixops4Resource.nixos ];

      ssh = {
        host = "141.145.213.115";
        opts = "";
        hostPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKVmK67fRJIc826wSfR3Thi+mUTZCwucaM4gnKiw6c4J";
      };

      nixpkgs = inputs.nixpkgs;
      nixos.module = {
        imports = [ self.nixosModules.dagrun ];
      };
    };
}
