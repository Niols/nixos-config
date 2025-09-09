{ self, inputs, ... }:

{
  flake.nixosModules.wallace = {
    imports = [
      (import ../_common).laptop

      ./graphics.nix
      ./hardware-configuration.nix
      ./motd.nix
      ./network.nix
      ./sound.nix
      ./storage.nix
      ./weylus.nix

      ./legacy-configuration.nix
      ./syncthing.nix
      ./udev.nix
      ./xserver.nix

      ## Specific hardware optimisations for Lenovo ThinkPad X1 9th gen
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen

      inputs.agenix.nixosModules.default
      {
        _module.args = {
          inherit (inputs) nixpkgs;
        };
      }

      self.nixosModules.keys
      self.nixosModules.secrets
      { x_niols.hostPublicKey = self.keys.machines.wallace; }

      inputs.nix-index-database.nixosModules.nix-index

      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          ## By default, Home Manager uses a private pkgs instance that is
          ## configured via the `home-manager.users.<name>.nixpkgs` options.
          ## The following option instead uses the global pkgs that is
          ## configured via the system level nixpkgs options; This saves an
          ## extra Nixpkgs evaluation, adds consistency, and removes the
          ## dependency on `NIX_PATH`, which is otherwise used for importing
          ## Nixpkgs.
          useGlobalPkgs = true;

          ## By default packages will be installed to `$HOME/.nix-profile` but
          ## they can be installed to `/etc/profiles` if the following is
          ## added to the system configuration. This option may become the
          ## default value in the future.
          useUserPackages = true;

          users = {
            niols = import ../home { inherit inputs; };
            root = import ../home { inherit inputs; };
          };
        };
      }
    ];
  };
}
