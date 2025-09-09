{ self, inputs, ... }:

{
  flake.nixosModules.wallace = {
    imports = [
      (import ../_common).laptop
      ../_modules/niols-motd.nix

      ./hardware-configuration.nix
      ./network.nix
      ./sound.nix
      ./storage.nix

      ./legacy-configuration.nix
      ./syncthing.nix

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

    services.picom.enable = true;
    services.autorandr.x_niols.thisLaptopsFingerprint = "00ffffffffffff000e6f031400000000001e0104b51e1378032594af5042b0250d4e550000000101010101010101010101010101010180e800a0f0605090302036002ebd10000018000000fd00303c95953c010a202020202020000000fe0043534f542054330a2020202020000000fe004d4e453030375a41312d320a2001a102030f00e3058000e60605016a6a24000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a";

    niols-motd = {
      enable = true;
      hostname = "Wallace";
      hostcolour = "green";
    };

    programs.weylus = {
      enable = true;
      openFirewall = true;
      users = [ "niols" ];
    };
  };
}
