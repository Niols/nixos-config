{
  flake.nixosModules.helga = {
    imports = [
      ../_common/server.nix
      ../../_modules/teamspeak.nix

      ./hardware-configuration.nix
      ./nginx.nix
    ];

    x_niols.thisMachinesName = "helga";
    x_niols.thisMachinesColour = "blue";
    x_niols.enableNiolsUser = true;

    ## FIXME: This is an experiment to improve responsiveness of the system
    ## when Dancelor uses the Nix builds so intensely. It might however starve
    ## the Nix builds, and in particular the `nixos-rebuild`. Hopefully,
    ## though, since it come from NixOps4, that is not a problem.
    nix.daemonCPUSchedPolicy = "idle";
    nix.daemonIOSchedClass = "idle";
  };
}
