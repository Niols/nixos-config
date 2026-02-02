{
  inputs = {
    nixops4.follows = "nixops4-nixos/nixops4";
    nixops4-nixos.url = "github:nixops4/nixops4-nixos";
  };

  outputs =
    inputs:
    import ./mkFlake.nix inputs (
      { inputs, sources, ... }:
      {
        imports = [
          inputs.nixops4.modules.flake.default
        ];

        nixops4Deployments.check-deployment-basic = {
          imports = [ ./deployment/check/basic/deployment.nix ];
          _module.args = { inherit inputs sources; };
        };
      }
    );
}
