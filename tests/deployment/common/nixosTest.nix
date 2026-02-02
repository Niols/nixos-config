{
  inputs,
  lib,
  config,
  hostPkgs,
  sources,
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
    runCommandNoCC
    writeText
    system
    ;

  forConcat = xs: f: concatStringsSep "\n" (map f xs);

  ## We will need to override some inputs by the empty flake, so we make one.
  emptyFlake = runCommandNoCC "empty-flake" { } ''
    mkdir $out
    echo "{ outputs = { self }: {}; }" > $out/flake.nix
  '';

in
{
  _class = "nixosTest";

  imports = [
    ./sharedOptions.nix
  ];

  options = {
    ## FIXME: I wish I could just use `testScript` but with something like
    ## `mkOrder` to put this module's string before something else.
    extraTestScript = mkOption { };

    sourceFileset = mkOption {
      ## FIXME: grab `lib.types.fileset` from NixOS, once upstreaming PR
      ## https://github.com/NixOS/nixpkgs/pull/428293 lands.
      type = types.mkOptionType {
        name = "fileset";
        description = "fileset";
        descriptionClass = "noun";
        check = (x: (builtins.tryEval (fileset.unions [ x ])).success);
        merge = (_: defs: fileset.unions (map (x: x.value) defs));
      };
      description = ''
        A fileset that will be copied to the deployer node in the current
        working directory. This should contain all the files that are
        necessary to run that particular test, such as the NixOS
        modules necessary to evaluate a deployment.
      '';
    };
  };

  config = {
    sourceFileset = fileset.unions [
      # NOTE: not the flake itself; it will be overridden.
      ../../../mkFlake.nix
      ../../../flake.lock
      ../../../npins

      ./sharedOptions.nix
      ./targetNode.nix
      ./targetResource.nix

      (config.pathToCwd + "/flake-under-test.nix")
    ];

    acmeNodeIP = config.nodes.acme.networking.primaryIPAddress;

    nodes = {
      deployer = {
        imports = [ ./deployerNode.nix ];
        _module.args = { inherit inputs sources; };
        enableAcme = config.enableAcme;
        acmeNodeIP = config.nodes.acme.networking.primaryIPAddress;
      };
    }

    //

      (
        if config.enableAcme then
          {
            acme = {
              ## FIXME: This makes `nodes.acme` into a local resolver. Maybe this will
              ## break things once we play with DNS?
              imports = [ "${inputs.nixpkgs}/nixos/tests/common/acme/server" ];
              ## We aren't testing ACME - we just want certificates.
              systemd.services.pebble.environment.PEBBLE_VA_ALWAYS_VALID = "1";
            };
          }
        else
          { }
      )

    //

      genAttrs config.targetMachines (_: {
        imports = [ ./targetNode.nix ];
        _module.args = { inherit inputs sources; };
        enableAcme = config.enableAcme;
        acmeNodeIP = if config.enableAcme then config.nodes.acme.networking.primaryIPAddress else null;
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
            fileset = config.sourceFileset;
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
        deployer.succeed("cp ${config.pathFromRoot}/flake-under-test.nix flake.nix")
        deployer.succeed("""
          nix flake lock --extra-experimental-features 'flakes nix-command' \
            --offline -v \
            --override-input nixops4 ${inputs.nixops4.packages.${system}.flake-in-a-bottle} \
            \
            --override-input nixops4-nixos ${inputs.nixops4-nixos} \
            --override-input nixops4-nixos/flake-parts ${inputs.nixops4-nixos.inputs.flake-parts} \
            --override-input nixops4-nixos/flake-parts/nixpkgs-lib ${inputs.nixops4-nixos.inputs.flake-parts.inputs.nixpkgs-lib} \
            --override-input nixops4-nixos/nixops4-nixos ${emptyFlake} \
            --override-input nixops4-nixos/nixpkgs ${inputs.nixops4-nixos.inputs.nixpkgs} \
            --override-input nixops4-nixos/nixops4 ${
              inputs.nixops4-nixos.inputs.nixops4.packages.${system}.flake-in-a-bottle
            } \
            --override-input nixops4-nixos/git-hooks-nix ${emptyFlake} \
            ;
        """)

      ${optionalString config.enableAcme ''
        with subtest("Set up handmade DNS"):
          deployer.succeed("echo '${config.nodes.acme.networking.primaryIPAddress}' > ${config.pathFromRoot}/acme_server_ip")
      ''}

      ${config.extraTestScript}
    '';
  };
}
