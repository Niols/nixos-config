{ self, inputs, ... }:

{
  flake.nixosModules.wallace = {
    _module.args = {
      inherit (inputs) nixpkgs;
    };

    imports = [
      (import ../_common).laptop
      ../_modules/niols-motd.nix

      self.nixosModules.keys
      self.nixosModules.secrets

      inputs.agenix.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.nix-index-database.nixosModules.nix-index
      inputs.home-manager.nixosModules.home-manager
      ## Specific hardware optimisations for Lenovo ThinkPad X1 9th gen
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen

      ./hardware-configuration.nix
      ./network.nix
      ./storage.nix
      ./legacy-configuration.nix
      ./syncthing.nix
    ];

    x_niols.hostPublicKey = self.keys.machines.wallace;

    services.picom.enable = true;
    services.autorandr.x_niols.thisLaptopsFingerprint = "00ffffffffffff000e6f031400000000001e0104b51e1378032594af5042b0250d4e550000000101010101010101010101010101010180e800a0f0605090302036002ebd10000018000000fd00303c95953c010a202020202020000000fe0043534f542054330a2020202020000000fe004d4e453030375a41312d320a2001a102030f00e3058000e60605016a6a24000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a";

    ## Force opt-out of Pipewire, the default, that doesn't work so well for us.
    ## Use good old pulseaudio instead.
    services = {
      pipewire.enable = false;
      pulseaudio.enable = true;
    };

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

    home-manager.users = {
      niols = import ../home { inherit inputs; };
      root = import ../home { inherit inputs; };
    };
  };
}
