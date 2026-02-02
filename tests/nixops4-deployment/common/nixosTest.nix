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
    types
    fileset
    mkOption
    genAttrs
    attrNames
    optionalString
    ;
  inherit (hostPkgs)
    runCommand
    writeText
    system
    ;

  forConcat = xs: f: concatStringsSep "\n" (map f xs);

  ## We will need to override some inputs by the empty flake, so we make one.
  emptyFlake = runCommand "empty-flake" { } ''
    mkdir $out
    echo "{ outputs = { self }: {}; }" > $out/flake.nix
  '';

  sourceFileset = fileset.unions [
    ## NOTE: our custom flake-under-test but with the official lock
    ./flake-under-test.nix
    ../../../flake.lock

    ./sharedOptions.nix
    ./targetNode.nix
    ./targetResource.nix
    ../basic/constants.nix
    ../basic/deployment.nix
  ];

in
{
  _class = "nixosTest";

  imports = [
    ./sharedOptions.nix
  ];

  config = {
    name = "nixops4-deployment";

    nodes = {
      deployer =
        { pkgs, ... }:
        {
          imports = [ ./deployerNode.nix ];
          _module.args = { inherit inputs; };

          environment.systemPackages = [
            inputs.nixops4.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
          # FIXME: sad times
          system.extraDependencies = with pkgs; [
            jq
            jq.inputDerivation
          ];
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

    // genAttrs config.targetMachines (_: {
      imports = [ ./targetNode.nix ];
      _module.args = { inherit inputs; };
    });

    testScript = ''
      ${forConcat (attrNames config.nodes) (n: ''
        ${n}.start()
      '')}

      ${forConcat (attrNames config.nodes) (n: ''
        ${n}.wait_for_unit("multi-user.target")
      '')}

      ## A subset of the repository that is necessary for this test. It will be
      ## copied inside the test. The smaller this set, the faster our CI, because we
      ## won't need to re-run when things change outside of it.
      with subtest("Unpacking"):
        deployer.succeed("cp -r --no-preserve=mode ${
          fileset.toSource {
            root = ../../..;
            fileset = sourceFileset;
          }
        }/* .")

      with subtest("Configure the network"):
        ${forConcat config.targetMachines (
          tm:
          let
            targetNetworkJSON = writeText "target-network.json" (
              toJSON config.nodes.${tm}.system.build.networkConfig
            );
          in
          ''
            deployer.copy_from_host("${targetNetworkJSON}", "${config.pathFromRoot}/${tm}-network.json")
          ''
        )}

      with subtest("Configure the deployer key"):
        deployer.succeed("""mkdir -p ~/.ssh && ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa""")
        deployer_key = deployer.succeed("cat ~/.ssh/id_rsa.pub").strip()
        ${forConcat config.targetMachines (tm: ''
          ${tm}.succeed(f"mkdir -p /root/.ssh && echo '{deployer_key}' >> /root/.ssh/authorized_keys")
        '')}

      with subtest("Configure the target host key"):
        ${forConcat config.targetMachines (tm: ''
          host_key = ${tm}.succeed("ssh-keyscan ${tm} | grep -v '^#' | cut -f 2- -d ' ' | head -n 1")
          deployer.succeed(f"echo '{host_key}' > ${config.pathFromRoot}/${tm}_host_key.pub")
        '')}

      ## NOTE: This is super slow. It could probably be optimised in Nix, for
      ## instance by allowing to grab things directly from the host's store.
      ##
      ## NOTE: We use the repository as-is (cf `src` above), overriding only
      ## `flake.nix` by our `flake-under-test.nix`. We also override the flake
      ## lock file to use locally available inputs, as we cannot download them.
      ##
      with subtest("Override the flake and its lock"):
        deployer.succeed("cp tests/nixops4-deployment/common/flake-under-test.nix flake.nix")
        deployer.succeed("""
          nix flake lock --extra-experimental-features 'flakes nix-command' \
            --offline -v \
            --override-input nixpkgs ${inputs.nixpkgs} \
            \
            --override-input nixops4 ${inputs.nixops4.packages.${system}.flake-in-a-bottle} \
            --override-input nixops4-nixos ${inputs.nixops4-nixos} \
            --override-input nixops4-nixos/flake-parts ${inputs.nixops4-nixos.inputs.flake-parts} \
            --override-input nixops4-nixos/flake-parts/nixpkgs-lib ${inputs.nixops4-nixos.inputs.flake-parts.inputs.nixpkgs-lib} \
            --override-input nixops4-nixos/nixops4-nixos ${emptyFlake} \
            --override-input nixops4-nixos/git-hooks-nix ${emptyFlake} \
            \
            --override-input home-manager ${inputs.home-manager} \
            --override-input nixos-hardware ${inputs.nixos-hardware} \
            --override-input flake-parts ${inputs.flake-parts} \
            --override-input git-hooks ${inputs.git-hooks} \
            --override-input nix-index-database ${inputs.nix-index-database} \
            --override-input agenix ${inputs.agenix} \
            --override-input dancelor ${inputs.dancelor} \
            --override-input doomemacs ${inputs.doomemacs} \
            ;
        """)

      with subtest("Check the status before deployment"):
        hello.fail("hello 1>&2")
        cowsay.fail("cowsay 1>&2")

      with subtest("Run the deployment"):
        deployer.succeed("nixops4 apply check-deployment --show-trace --no-interactive 1>&2")

      with subtest("Check the deployment"):
        hello.succeed("hello 1>&2")
        cowsay.succeed("cowsay hi 1>&2")
    '';
  };
}
