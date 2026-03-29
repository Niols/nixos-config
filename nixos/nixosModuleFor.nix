{
  self,
  inputs,
  lib,
  machines,
}:

let
  inherit (lib)
    mapAttrs'
    mkForce
    ;

  ## The special arguments that we need to propagate throughout the whole
  ## codebase and all the modules, specialised for the given machine.
  specialArgsFor = name: {
    inherit inputs;
    machines = machines // {
      this = machines.all.${name};
    };
  };

  nixosModuleFor =
    name:
    (
      { config, ... }:
      {
        imports = [
          self.nixosModules.keys
          self.nixosModules.secrets
          self.nixosModules.${name}
          inputs.home-manager.nixosModules.home-manager
        ];

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

          sharedModules = [ self.homeModules.secrets ];

          extraSpecialArgs = specialArgsFor name;
        };

        ## The default timeout for Home Manager services is 5 minutes. This is
        ## extremely reasonable, except that we may compile all of Doom Emacs
        ## in that time, so we need to bump it for all our HM users.
        systemd.services = mapAttrs' (user: _: {
          name = "home-manager-${user}";
          value.serviceConfig.TimeoutStartSec = mkForce "20m";
        }) config.home-manager.users;
      }
    );

in

{
  inherit
    specialArgsFor
    nixosModuleFor
    ;
}
