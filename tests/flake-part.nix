{ inputs, ... }:

{
  _class = "flake";

  perSystem =
    { pkgs, ... }:
    {
      checks = {
        deployment-basic = import ./deployment/basic {
          inherit (pkgs.testers) runNixOSTest;
          inherit inputs;
        };

        deployment-cli = import ./deployment/cli {
          inherit (pkgs.testers) runNixOSTest;
          inherit inputs;
        };
      };
    };
}
