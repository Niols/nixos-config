{ inputs, lib, ... }:

{
  _class = "flake";

  perSystem =
    { pkgs, system, ... }:
    {
      ## Only run the test on `x86_64-linux`.
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        nixops-deployment = import ./nixops-deployment {
          inherit (pkgs.testers) runNixOSTest;
          inherit inputs;
        };
      };
    };
}
