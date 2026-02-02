{
  inputs = {
    nixops4.follows = "nixops4-nixos/nixops4";
    nixops4-nixos.url = "github:nixops4/nixops4-nixos";
  };

  outputs =
    inputs:
    import ./mkFlake.nix inputs (
      {
        inputs,
        sources,
        lib,
        ...
      }:
      {
        imports = [
          inputs.nixops4.modules.flake.default
        ];

        nixops4Deployments = import ./deployment/check/cli/deployments.nix {
          inherit inputs sources lib;
        };
      }
    );
}
