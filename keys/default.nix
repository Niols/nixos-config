let
  keys = import ./keys.nix;
in
{
  flake = {
    inherit keys;
    nixosModules.keys._module.args = { inherit keys; };
  };
}
