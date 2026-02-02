{
  runNixOSTest,
  inputs,
  sources,
}:

runNixOSTest {
  imports = [
    ../common/nixosTest.nix
    ./nixosTest.nix
  ];
  _module.args = { inherit inputs sources; };
  inherit (import ./constants.nix) targetMachines pathToRoot pathFromRoot;
}
