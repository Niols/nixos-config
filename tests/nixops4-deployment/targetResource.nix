{
  inputs,
  lib,
  config,
  ...
}:

let
  inherit (builtins) readFile;
  inherit (lib) trim mkOption types;

in

{
  _class = "nixops4Resource";

  options.nodeName = mkOption {
    type = types.str;
    description = ''
      The name of the node in the NixOS test; needed for recovering the node
      configuration to prepare its deployment.
    '';
  };

  config = {
    ssh = {
      host = config.nodeName;
      hostPublicKey = readFile (./. + "/${config.nodeName}_host_key.pub");
    };

    nixpkgs = inputs.nixpkgs;

    nixos.module = {
      imports = [
        ./targetNode.nix
        (lib.modules.importJSON (./. + "/${config.nodeName}-network.json"))
      ];

      _module.args = { inherit inputs; };

      nixpkgs.hostPlatform = "x86_64-linux";
    };
  };
}
