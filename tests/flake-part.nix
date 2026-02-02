{ inputs, ... }:

{
  _class = "flake";

  perSystem =
    { pkgs, system, ... }:
    {
      ## Only run the test on `x86_64-linux`. NOTE: It would be cleaner to use
      ## `lib.optionalAttrs` rather than provider a dummy derivation, but our CI
      ## expects the same names in all `checks.*` attribute sets.
      checks.nixops4-deployment =
        if system == "x86_64-linux" then
          import ./nixops4-deployment {
            inherit (pkgs.testers) runNixOSTest;
            inherit inputs;
          }
        else
          pkgs.hello;
    };
}
