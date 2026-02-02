{
  runNixOSTest,
  inputs,
}:

runNixOSTest {
  imports = [ ./nixosTest.nix ];
  _module.args = { inherit inputs; };
  inherit (import ./constants.nix) targetMachines pathToRoot pathFromRoot;
}
