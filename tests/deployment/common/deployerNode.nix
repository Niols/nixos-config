{
  inputs,
  lib,
  pkgs,
  config,
  sources,
  ...
}:

let
  inherit (lib)
    mkOption
    mkForce
    concatLists
    types
    ;

in
{
  _class = "nixos";

  imports = [ ./sharedOptions.nix ];

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

    system.extraDependencies = [
      inputs.nixops4
      inputs.nixops4-nixos
      inputs.nixpkgs

      sources.flake-parts
      sources.flake-inputs
      sources.git-hooks

      pkgs.stdenv
      pkgs.stdenvNoCC
    ]
    ++ (
      let
        ## We build a whole NixOS system that contains the module
        ## `system.extraDependenciesFromModule`, only to grab its
        ## configuration and the store paths needed to build it and
        ## dump them in `system.extraDependencies`.
        machine =
          (pkgs.nixos [
            ./targetNode.nix
            config.system.extraDependenciesFromModule
            {
              nixpkgs.hostPlatform = "x86_64-linux";
              _module.args = { inherit inputs sources; };
              enableAcme = config.enableAcme;
              acmeNodeIP = config.acmeNodeIP;
            }
          ]).config;

      in
      [
        machine.system.build.toplevel.inputDerivation
        machine.system.build.etc.inputDerivation
        machine.system.build.etcBasedir.inputDerivation
        machine.system.build.etcMetadataImage.inputDerivation
        machine.system.build.extraUtils.inputDerivation
        machine.system.path.inputDerivation
        machine.system.build.setEnvironment.inputDerivation
        machine.system.build.vm.inputDerivation
        machine.system.build.bootStage1.inputDerivation
        machine.system.build.bootStage2.inputDerivation
      ]
      ++ concatLists (
        lib.mapAttrsToList (
          _k: v: if v ? source.inputDerivation then [ v.source.inputDerivation ] else [ ]
        ) machine.environment.etc
      )
    );
  };
}
