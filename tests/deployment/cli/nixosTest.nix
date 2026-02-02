{
  inputs,
  hostPkgs,
  lib,
  ...
}:

let
  ## Some places need a dummy file that will in fact never be used. We create
  ## it here.
  dummyFile = hostPkgs.writeText "dummy" "";
in

{
  _class = "nixosTest";

  name = "deployment-cli";

  sourceFileset = lib.fileset.unions [
    ./constants.nix
    ./deployments.nix

    # REVIEW: I would like to be able to grab all of `/deployment` minus
    # `/deployment/check`, but I can't because there is a bunch of other files
    # in `/deployment`. Maybe we can think of a reorg making things more robust
    # here? (comment also in panel test)
    ../../default.nix
    ../../options.nix
    ../../configuration.sample.json

    ../../../services/fediversity
  ];

  nodes.deployer =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.nixops4.packages.${pkgs.system}.default
      ];

      ## FIXME: The following dependencies are necessary but I do not
      ## understand why they are not covered by the fake node.
      system.extraDependencies = with pkgs; [
        peertube
        peertube.inputDerivation
        gixy
        gixy.inputDerivation
      ];

      system.extraDependenciesFromModule = {
        imports = [ ../../../services/fediversity ];
        fediversity = {
          domain = "fediversity.net"; # would write `dummy` but that would not type
          garage.enable = true;
          mastodon = {
            enable = true;
            s3AccessKeyFile = dummyFile;
            s3SecretKeyFile = dummyFile;
          };
          peertube = {
            enable = true;
            secretsFile = dummyFile;
            s3AccessKeyFile = dummyFile;
            s3SecretKeyFile = dummyFile;
          };
          pixelfed = {
            enable = true;
            s3AccessKeyFile = dummyFile;
            s3SecretKeyFile = dummyFile;
          };
          temp.cores = 1;
          temp.initialUser = {
            username = "dummy";
            displayName = "dummy";
            email = "dummy";
            passwordFile = dummyFile;
          };
        };
      };
    };

  ## NOTE: The target machines may need more RAM than the default to handle
  ## being deployed to, otherwise we get something like:
  ##
  ##     pixelfed # [  616.785499 ] sshd-session[1167]: Conection closed by 2001:db8:1::2 port 45004
  ##     deployer # error: writing to file: No space left on device
  ##     pixelfed # [  616.788538 ] sshd-session[1151]: pam_unix(sshd:session): session closed for user port
  ##     pixelfed # [  616.793929 ] systemd-logind[719]: Session 4 logged out. Waiting for processes to exit.
  ##     deployer # Error: Could not create resource
  ##
  ## These values have been trimmed down to the gigabyte.
  nodes.mastodon.virtualisation.memorySize = 4 * 1024;
  nodes.pixelfed.virtualisation.memorySize = 4 * 1024;
  nodes.peertube.virtualisation.memorySize = 5 * 1024;

  ## FIXME: The test of presence of the services are very simple: we only
  ## check that there is a systemd service of the expected name on the
  ## machine. This proves at least that NixOps4 did something, and we cannot
  ## really do more for now because the services aren't actually working
  ## properly, in particular because of DNS issues. We should fix the services
  ## and check that they are working properly.

  extraTestScript = ''
    with subtest("Check the status of the services - there should be none"):
      garage.fail("systemctl status garage.service")
      mastodon.fail("systemctl status mastodon-web.service")
      peertube.fail("systemctl status peertube.service")
      pixelfed.fail("systemctl status phpfpm-pixelfed.service")

    with subtest("Run deployment with no services enabled"):
      deployer.succeed("nixops4 apply check-deployment-cli-nothing --show-trace --no-interactive 1>&2")

    with subtest("Check the status of the services - there should still be none"):
      garage.fail("systemctl status garage.service")
      mastodon.fail("systemctl status mastodon-web.service")
      peertube.fail("systemctl status peertube.service")
      pixelfed.fail("systemctl status phpfpm-pixelfed.service")

    with subtest("Run deployment with Mastodon and Pixelfed enabled"):
      deployer.succeed("nixops4 apply check-deployment-cli-mastodon-pixelfed --show-trace --no-interactive 1>&2")

    with subtest("Check the status of the services - expecting Garage, Mastodon and Pixelfed"):
      garage.succeed("systemctl status garage.service")
      mastodon.succeed("systemctl status mastodon-web.service")
      peertube.fail("systemctl status peertube.service")
      pixelfed.succeed("systemctl status phpfpm-pixelfed.service")

    with subtest("Run deployment with only Peertube enabled"):
      deployer.succeed("nixops4 apply check-deployment-cli-peertube --show-trace --no-interactive 1>&2")

    with subtest("Check the status of the services - expecting Garage and Peertube"):
      garage.succeed("systemctl status garage.service")
      mastodon.fail("systemctl status mastodon-web.service")
      peertube.succeed("systemctl status peertube.service")
      pixelfed.fail("systemctl status phpfpm-pixelfed.service")
  '';
}
