{
  inputs,
  lib,
}:

let
  inherit (builtins) fromJSON readFile listToAttrs;
  inherit (import ./constants.nix)
    targetMachines
    pathToRoot
    pathFromRoot
    enableAcme
    ;

  makeTargetResource = nodeName: {
    imports = [ ../common/targetResource.nix ];
    _module.args = { inherit inputs; };
    inherit
      nodeName
      pathToRoot
      pathFromRoot
      enableAcme
      ;
  };

  ## The deployment function - what we are here to test!
  ##
  ## TODO: Modularise `deployment/default.nix` to get rid of the nested
  ## function calls.
  makeTestDeployment =
    args:
    (import ../..)
      {
        inherit lib;
        inherit (inputs) nixops4 nixops4-nixos;
        fediversity = import ../../../services/fediversity;
      }
      (listToAttrs (
        map (nodeName: {
          name = "${nodeName}ConfigurationResource";
          value = makeTargetResource nodeName;
        }) targetMachines
      ))
      (fromJSON (readFile ../../configuration.sample.json) // args);

in
{
  check-deployment-cli-nothing = makeTestDeployment { };

  check-deployment-cli-mastodon-pixelfed = makeTestDeployment {
    mastodon.enable = true;
    pixelfed.enable = true;
  };

  check-deployment-cli-peertube = makeTestDeployment {
    peertube.enable = true;
  };
}
