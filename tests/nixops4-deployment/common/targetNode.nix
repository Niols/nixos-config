{
  inputs,
  config,
  lib,
  modulesPath,
  ...
}:

let
  testCerts = import "${inputs.nixpkgs}/nixos/tests/common/acme/server/snakeoil-certs.nix";
  inherit (lib) mkIf mkMerge;

in
{
  _class = "nixos";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/../lib/testing/nixos-test-base.nix")
    ./sharedOptions.nix
  ];

  config = mkMerge [
    {
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

    (mkIf config.enableAcme {
      security.acme = {
        acceptTerms = true;
        defaults.email = "test@test.com";
        defaults.server = "https://acme.test/dir";
      };

      security.pki.certificateFiles = [
        ## NOTE: This certificate is the one used by the Pebble HTTPS server.
        ## This is NOT the root CA of the Pebble server. We do add it here so
        ## that Pebble clients can talk to its API, but this will not allow
        ## those machines to verify generated certificates.
        testCerts.ca.cert
      ];

      ## FIXME: it is a bit sad that all this logistics is necessary. look into
      ## better DNS stuff
      networking.extraHosts = "${config.acmeNodeIP} acme.test";
    })
  ];
}
