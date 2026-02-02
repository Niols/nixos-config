{ inputs, ... }:

{
  _class = "flake";

  perSystem =
    { pkgs, ... }:
    {
      checks.nixops4-deployment = import ./nixops4-deployment/basic {
        inherit (pkgs.testers) runNixOSTest;
        inherit inputs;
      };
    };
}
