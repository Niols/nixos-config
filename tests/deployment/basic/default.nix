{
  runNixOSTest,
  inputs,
}:

runNixOSTest {
  imports = [
    ../common/nixosTest.nix
    ./nixosTest.nix
  ];
  _module.args = { inherit inputs; };
  inherit (import ./constants.nix) targetMachines pathToRoot pathFromRoot;
}
