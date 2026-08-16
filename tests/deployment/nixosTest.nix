{
  inputs,
  lib,
  config,
  hostPkgs,
  ...
}:

let
  inherit (builtins)
    concatStringsSep
    toJSON
    ;
  inherit (lib)
    fileset
    genAttrs
    attrNames
    ;
  inherit (hostPkgs)
    writeText
    ;

  forConcat = xs: f: concatStringsSep "\n" (map f xs);

  ## FIXME: The whole way that we have to have rebuild.nix with us and
  ## we have to override machines.nix is really quite disgusting. It
  ## would just be much easier if we could parameterise rebuild.nix in
  ## a way, and then we could just environment.systemPackages = [
  ## callPackage ./rebuild.nix ] with the right parameters, instead of
  ## having all this gymnastic.

  ## FIXME: We should just add the keys to machines.nix and not bother
  ## with this useless directory.

  sourceFileset = fileset.toSource {
    root = ../..;
    fileset = fileset.unions [
      ## NOTE: our custom flake-under-test.nix and
      ## machines-under-test.nix but with the official flake.lock and
      ## rebuild.nix
      ./flake-under-test.nix
      ../../flake.lock
      ../../rebuild.nix # FIXME: remove once we have a cleaner way to integrate
      ../../rebuild.sh # FIXME: remove once we have a cleaner way to integrate
      ../../pkgs.nix # FIXME: remove once we have a cleaner way to integrate
      ../../keys/keys.nix

      ./deployment.nix
      ./targetNode.nix
      ./targetComponent.nix
    ];
  };

  targetMachines = [
    "hello"
    "cowsay"
  ];

  ## FIXME: Machines in a deployment like this one have an SSH
  ## backdoor so one can connect with user root and an empty
  ## password. Maybe this can simplify the SSH keys handling?

  privateKeys = {
    hello = ''
      -----BEGIN OPENSSH PRIVATE KEY-----
      b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
      QyNTUxOQAAACDeejBz9U3XaCjWPhvkr2VpP1o+JsPh5CIvA5BrIWkrdQAAAJD6HP4S+hz+
      EgAAAAtzc2gtZWQyNTUxOQAAACDeejBz9U3XaCjWPhvkr2VpP1o+JsPh5CIvA5BrIWkrdQ
      AAAEBN03bdO64AKFfX/SCpoaSCrBs4sVCHtSWWdLrC71uc3t56MHP1TddoKNY+G+SvZWk/
      Wj4mw+HkIi8DkGshaSt1AAAACHNuYWtlb2lsAQIDBAU=
      -----END OPENSSH PRIVATE KEY-----
    '';
    cowsay = ''
      -----BEGIN OPENSSH PRIVATE KEY-----
      b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
      QyNTUxOQAAACDVlFNLPPJhNGmZykIzoJs8HPqdpphJXMVW+ugUFI+D/QAAAJCvW4/6r1uP
      +gAAAAtzc2gtZWQyNTUxOQAAACDVlFNLPPJhNGmZykIzoJs8HPqdpphJXMVW+ugUFI+D/Q
      AAAEBe/GCWgY/vc1jRPx//SBn32QVi8fZJkgA+81HPmeIHGNWUU0s88mE0aZnKQjOgmzwc
      +p2mmElcxVb66BQUj4P9AAAACHNuYWtlb2lsAQIDBAU=
      -----END OPENSSH PRIVATE KEY-----
    '';
    deployer = ''
      -----BEGIN OPENSSH PRIVATE KEY-----
      b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
      QyNTUxOQAAACBBlGIMfzHhnPjnn6EAklY0Bpj9ILCMWlOzYOeu60/ksAAAAJAkDaUmJA2l
      JgAAAAtzc2gtZWQyNTUxOQAAACBBlGIMfzHhnPjnn6EAklY0Bpj9ILCMWlOzYOeu60/ksA
      AAAED/xkexT2CQRGYJOIOwgTFzJWr0apkeDY7HcHWN+RPirUGUYgx/MeGc+OefoQCSVjQG
      mP0gsIxaU7Ng567rT+SwAAAACHNuYWtlb2lsAQIDBAU=
      -----END OPENSSH PRIVATE KEY-----
    '';
  };

  publicKeys = {
    hello = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN56MHP1TddoKNY+G+SvZWk/Wj4mw+HkIi8DkGshaSt1";
    cowsay = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWUU0s88mE0aZnKQjOgmzwc+p2mmElcxVb66BQUj4P9";
    deployer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEGUYgx/MeGc+OefoQCSVjQGmP0gsIxaU7Ng567rT+Sw";
  };

  rebuild = hostPkgs.callPackage ../../rebuild.nix {
    flakeRoot = "DUMMY";

    keys = publicKeys;

    servers = {
      hello = {
        name = "hello";
        ipv4 = "hello"; # FIXME: so that rebuild just runs `ssh hello` - unclean
        kind = "server";
        wgPublicKey = "DUMMY";
        cores = 1;
      };

      cowsay = {
        name = "cowsay";
        ipv4 = "cowsay"; # FIXME: so that rebuild just runs `ssh cowsay` - unclean
        kind = "server";
        wgPublicKey = "DUMMY";
        cores = 1;
      };
    };
  };

in
{
  _class = "nixosTest";

  name = "deployment";

  nodes = {
    deployer = {
      imports = [ ./deployerNode.nix ];
      _module.args = { inherit inputs; };
      environment.systemPackages = [ rebuild ];
      system.extraDependenciesFromModule =
        { pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [
            hello
            cowsay
          ];
        };
    };
  }
  // genAttrs targetMachines (m: {
    imports = [ ./targetNode.nix ];
    _module.args = { inherit inputs; };
    environment.etc."ssh/ssh_host_ed25519_key" = {
      text = privateKeys.${m};
      mode = "0600";
    };
    services.openssh.hostKeys = [
      {
        type = "ed25519";
        path = "/etc/ssh/ssh_host_ed25519_key";
      }
    ];
  });

  testScript = ''
    ${forConcat (attrNames config.nodes) (n: ''
      ${n}.start(allow_reboot=True)
    '')}

    ${forConcat (attrNames config.nodes) (n: ''
      ${n}.wait_for_unit("multi-user.target")
    '')}

    ## A subset of the repository that is necessary for this test. It will be
    ## copied inside the test. The smaller this set, the faster our CI, because we
    ## won't need to re-run when things change outside of it.
    with subtest("Unpacking"):
      deployer.succeed("cp -r --no-preserve=mode ${sourceFileset}/* .")
      ## REVIEW: maybe we have the means to go back to using the real flake now?
      deployer.succeed("cp tests/deployment/flake-under-test.nix flake.nix")

    with subtest("Configure the network"):
      ${forConcat targetMachines (
        tm:
        let
          targetNetworkJSON = writeText "target-network.json" (
            toJSON config.nodes.${tm}.system.build.networkConfig
          );
        in
        ''
          deployer.copy_from_host("${targetNetworkJSON}", "${tm}-network.json")
        ''
      )}

    with subtest("Configure the deployer key"):
      deployer.succeed("""mkdir -p ~/.ssh && ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa""")
      deployer_key = deployer.succeed("cat ~/.ssh/id_rsa.pub").strip()
      ${forConcat targetMachines (tm: ''
        ${tm}.succeed(f"mkdir -p /root/.ssh && echo '{deployer_key}' >> /root/.ssh/authorized_keys")
      '')}

    ## NOTE: This is super slow. It could probably be optimised in Nix, for
    ## instance by allowing to grab things directly from the host's store.
    ##
    ## NOTE: We use the repository as-is (cf `src` above), overriding only
    ## `flake.nix` by our `flake-under-test.nix`. We also override the flake
    ## lock file to use locally available inputs, as we cannot download them.
    ##
    with subtest("Override the flake lock"):
      deployer.succeed("""
        nix flake lock --extra-experimental-features 'flakes nix-command' \
          --offline -v \
          --override-input nixpkgs ${inputs.nixpkgs} \
          \
          --override-input home-manager ${inputs.home-manager} \
          --override-input nixos-hardware ${inputs.nixos-hardware} \
          \
          --override-input flake-parts ${inputs.flake-parts} \
          --override-input flake-parts/nixpkgs-lib ${inputs.flake-parts.inputs.nixpkgs-lib} \
          \
          --override-input git-hooks ${inputs.git-hooks} \
          --override-input nix-index-database ${inputs.nix-index-database} \
          --override-input agenix ${inputs.agenix} \
          --override-input disko ${inputs.disko} \
          --override-input dancelor ${inputs.dancelor} \
          --override-input emacs-overlay ${inputs.emacs-overlay} \
          ;
      """)

    with subtest("Check the status before deployment"):
      hello.fail("hello 1>&2")
      cowsay.fail("cowsay 1>&2")

    with subtest("Run the deployment"):
      deployer.succeed("rebuild deploy --action switch --flake cwd --log raw 1>&2")

    with subtest("Check the deployment"):
      hello.succeed("hello 1>&2")
      cowsay.succeed("cowsay hi 1>&2")
  '';
}
