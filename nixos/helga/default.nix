{ self, ... }:

{
  flake.nixosModules.helga =
    {
      config,
      keys,
      inputs,
      ...
    }:
    {
      imports = [
        ../_common/server.nix
        ../../_modules/dancelor.nix
        ../../_modules/matrix.nix
        ../../_modules/teamspeak.nix
        ../../_modules/torrent.nix
        ../../_modules/web.nix

        inputs.dancelor.nixosModules.dancelor

        ./hardware-configuration.nix
        ./motd.nix
        ./nginx.nix
        ./starship.nix
      ];

      x_niols.thisDevicesName = "Helga";
      x_niols.hostPublicKey = self.keys.machines.${config.x_niols.thisDevicesNameLower};

      ## FIXME: This is an experiment to improve responsiveness of the system
      ## when Dancelor uses the Nix builds so intensely. It might however starve
      ## the Nix builds, and in particular the `nixos-rebuild`. Hopefully,
      ## though, since it come from NixOps4, that is not a problem.
      nix.daemonCPUSchedPolicy = "idle";
      nix.daemonIOSchedClass = "idle";

      users.users = {
        niols.hashedPasswordFile =
          config.age.secrets."password-${config.x_niols.thisDevicesNameLower}-niols".path;
        root.openssh.authorizedKeys.keys = [ keys.github-actions ];
      };
    };
}
