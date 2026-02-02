{
  lib,
  modulesPath,
  ...
}:

{
  _class = "nixos";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/../lib/testing/nixos-test-base.nix")
  ];

  ## Test framework disables switching by default. That might be OK by itself,
  ## but we also use this config for getting the dependencies in
  ## `deployer.system.extraDependencies`.
  system.switch.enable = true;

  nix = {
    ## Not used; save a large copy operation
    channel.enable = false;
    registry = lib.mkForce { };
  };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  ## Test VMs don't have a bootloader by default.
  boot.loader.grub.enable = false;
}
