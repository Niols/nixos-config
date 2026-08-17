{
  runNixOSTest,
  inputs,
}:

runNixOSTest {
  imports = [ ./nixosTest.nix ];
  _module.args = { inherit inputs; };
}
