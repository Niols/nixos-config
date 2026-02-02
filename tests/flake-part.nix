{ inputs, ... }:

{
  _class = "flake";

  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        nixops4-deployment = import ./nixops4-deployment/basic {
          inherit (pkgs.testers) runNixOSTest;
          inherit inputs;
        };
      };
    };
}
