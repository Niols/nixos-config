{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib)
    mkOption
    mkForce
    types
    ;

in
{
  _class = "nixos";

  options.system.extraDependenciesFromModule = mkOption {
    type = types.deferredModule;
    description = ''
      Grab the derivations needed to build the given module and dump them in
      system.extraDependencies. You want to put in this module a superset of
      all the things that you will need on your target machines.

      NOTE: This will work as long as the union of all these configurations do
      not have conflicts that would prevent evaluation.
    '';
    default = { };
  };

  config = {
    virtualisation = {
      ## NOTE: The deployer machines needs more RAM and default than the
      ## default. These values have been trimmed down to the gigabyte.
      ## Memory use is expected to be dominated by the NixOS evaluation,
      ## which happens on the deployer.
      memorySize = 4 * 1024;
      diskSize = 4 * 1024;
      cores = 2;
    };

    nix.settings = {
      substituters = mkForce [ ];
      hashed-mirrors = null;
      connect-timeout = 1;
      extra-experimental-features = "flakes";
    };

    ## We build a whole NixOS system that contains the module
    ## `system.extraDependenciesFromModule`, only to grab its
    ## configuration and the store paths needed to build it and
    ## dump them in `system.extraDependencies`.
    system.extraDependencies =
      let
        machine =
          (pkgs.nixos [
            ./targetNode.nix
            config.system.extraDependenciesFromModule
            {
              nixpkgs.hostPlatform = "x86_64-linux";
              _module.args = { inherit inputs; };
              ## NOTE: This system is only evaluated for its store paths, never
              ## actually booted, but NixOS requires a root filesystems entry.
              fileSystems."/" = {
                device = "/dev/dummy";
                fsType = "dummy";
              };
            }
          ]).config;
      in
      [ (pkgs.closureInfo { rootPaths = [ machine.system.build.toplevel.drvPath ]; }) ];
  };
}
