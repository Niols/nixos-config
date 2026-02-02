/**
  This file contains options shared by various components of the integration test, i.e. deployment resources, test nodes, target configurations, etc.
  All these components are declared as modules, but are part of different evaluations, which is the options in this file can't be shared "directly".
  Instead, each component imports this module and the same values are set for each of them from a common call site.
  Not all components will use all the options, which allows not setting all the values.
*/

{ config, lib, ... }:

let
  inherit (lib) mkOption types;

in
# `config` not set and imported from multiple places: no fixed module class
{
  options = {
    targetMachines = mkOption {
      type = with types; listOf str;
      description = ''
        Names of the nodes in the NixOS test that are “target machines”. This is
        used by the infrastructure to extract their network configuration, among
        other things, and re-import it in the deployment.
      '';
    };

    pathToRoot = mkOption {
      type = types.path;
      description = ''
        Path from the location of the working directory to the root of the
        repository.
      '';
    };

    pathFromRoot = mkOption {
      type = types.path;
      description = ''
        Path from the root of the repository to the working directory.
      '';
      apply = x: lib.path.removePrefix config.pathToRoot x;
    };

    pathToCwd = mkOption {
      type = types.path;
      description = ''
        Path to the current working directory. This is a shortcut for
        pathToRoot/pathFromRoot.
      '';
      default = config.pathToRoot + "/${config.pathFromRoot}";
    };

    enableAcme = mkOption {
      type = types.bool;
      description = ''
        Whether to enable ACME in the NixOS test. This will add an ACME server
        to the node and connect all the target machines to it.
      '';
      default = false;
    };

    acmeNodeIP = mkOption {
      type = types.str;
      description = ''
        The IP of the ACME node in the NixOS test. This option will be set
        during the test to the correct value.
      '';
    };
  };
}
