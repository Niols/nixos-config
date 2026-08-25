{ self, lib, ... }:

let
  inherit (lib)
    attrNames
    mapAttrsToList
    toJSON
    toFile
    concatStringsSep
    filterAttrs
    ;

  machines = import ../../machines.nix;

  aarch64Machines = attrNames (
    filterAttrs (
      _: nixosConfiguration: nixosConfiguration.pkgs.stdenv.hostPlatform.system == "aarch64-linux"
    ) self.nixosConfigurations
  );

  basicSetupSteps = [
    {
      name = "Check out repository";
      uses = "actions/checkout@v7";
    }
    {
      name = "Install Nix";
      uses = "cachix/install-nix-action@v31";
      "with".extra_nix_config = ''
        access-tokens = github.com=''${{ secrets.GITHUB_TOKEN }}
        download-attempts = 10 # more than usual because nix-cache might be down
      '';
    }
  ];

  atticSetupSteps = [
    {
      name = "Install Attic";
      run = "nix profile add .#attic";
    }
    {
      name = "Set up Attic cache";
      uses = "ryanccn/attic-action@v0.4.1";
      "with" = {
        endpoint = "https://nix-cache.niols.fr/";
        cache = "nixos-config";
        token = "\${{ secrets.ATTIC_TOKEN }}";
      };
    }
  ];

  ## NOTE: Laptops have a very large closure that doesn't necessarily
  ## fit on the GitHub runners, so we make extra space by deleting
  ## pre-installed stuff that we don't need.
  ##
  freeExtraSpaceStep = {
    name = "Free some extra space";
    "if" = "\${{ contains(fromJSON('${toJSON (attrNames machines.laptops)}'), matrix.nixos) }}";
    run = ''
      echo 'Available storage before:'
      sudo df -h
      echo
      sudo rm -rf /usr/share/dotnet
      sudo rm -rf /usr/local/lib/android
      sudo rm -rf /opt/ghc
      sudo rm -rf /opt/hostedtoolcache/CodeQL
      echo 'Available storage after:'
      sudo df -h
      echo
    '';
  };

  remainingSpaceStep = {
    name = "Remaining space";
    run = ''
      echo 'Available storage:'
      sudo df -h
    '';
  };

  ## NOTE: Orianne is an ARM machine, but the GitHub runners are Intel
  ## machines, so we detect that, install the emulation binaries for
  ## QEMU and tell Nix to behave as an `aarch64-linux` machine.
  ##
  setupEmulationLayerStep = {
    name = "Set up emulation layer";
    "if" = "\${{ contains(fromJSON('${toJSON aarch64Machines}'), matrix.nixos) }}";
    run = ''
      echo "system = aarch64-linux" > nix-config
      sudo apt-get update -y && sudo apt-get install -y qemu-user-static
    '';
  };

  makeGithubWorkflowsFor =
    pkgs:
    "${pkgs.writeShellScript "make-github-workflows" (
      concatStringsSep "\n" (
        mapAttrsToList (name: workflow: ''
          ${pkgs.yq}/bin/yq \
            --yaml-output --width 100 \
            . ${toFile "github-workflow-${name}.yml" (toJSON workflow)} \
            > .github/workflows/${name}.yml
        '') self.github-workflows
      )
    )}";

in
{
  perSystem =
    { pkgs, ... }:
    {
      ## A pre-commit hook that generates the GitHub workflows from Nix code.
      ## This will also run in CI (see `jobs.checks` below) to check that
      ## everything is in sync.
      ##
      ## NOTE: We could generate it by iterating in Nix rather than calling `nix
      ## eval` then processing with `for` + `jq`, but the latter will catch
      ## changes without having to reload the `direnv` every time.
      ##
      pre-commit.settings.hooks = {
        github-workflows = {
          enable = true;
          files = "\\.nix$";
          pass_filenames = false;
          entry = makeGithubWorkflowsFor pkgs;
        };
        prettier.excludes = [ ".github/workflows/.*\\.yml$" ];
      };

      ## Standalone version of `make-github-workflows`.
      ##
      apps.make-github-workflows = {
        type = "app";
        program = makeGithubWorkflowsFor pkgs;
      };
    };

  flake.github-workflows.ci = {
    name = "CI";

    on = {
      push.branches = [ "main" ];
      pull_request = { };
    };

    ## We specify a concurrency group with automated cancellation. This means that
    ## other pushes on the same `github.ref` (eg. other pushes to the same pull
    ## request) cancel previous occurrences of the CI.
    concurrency = {
      group = "\${{ github.workflow }}-\${{ github.ref }}";
      cancel-in-progress = true;
    };

    jobs = {
      summarise = {
        name = "Summarise";
        runs-on = "ubuntu-latest";
        needs = [
          "check"
          "home"
          "nixos"
          "deploy"
        ];
        "if" = "always()";
        steps = [
          {
            uses = "re-actors/alls-green@release/v1";
            "with" = {
              jobs = "\${{ toJSON(needs) }}";
              allowed-skips = "check, home, nixos, deploy";
            };
          }
        ];
      };

      home = {
        name = "Home";
        runs-on = "ubuntu-latest";
        strategy = {
          matrix.include = map (home: { inherit home; }) (attrNames self.homeConfigurations);
          fail-fast = false;
        };
        steps =
          basicSetupSteps
          ++ atticSetupSteps
          ++ [
            {
              ## NOTE: We build the home configurations as impure because they get
              ## their `home.username` and `home.homeDirectory` from the environment
              ## when they are not used via the Home Manager NixOS module.
              name = "Build Home configuration “\${{ matrix.home }}”";
              run = "nix build .#homeConfigurations.\${{ matrix.home }}.activationPackage --impure --print-build-logs";
            }
          ];
      };

      nixos = {
        name = "NixOS";
        runs-on = "ubuntu-latest";
        strategy = {
          matrix.nixos = attrNames machines.all;
          fail-fast = false;
        };
        steps =
          basicSetupSteps
          ++ atticSetupSteps
          ++ [
            freeExtraSpaceStep
            setupEmulationLayerStep
            {
              name = "Build NixOS configuration “\${{ matrix.nixos }}”";
              run = ''
                export NIX_CONFIG=$(cat nix-config)
                nix build .#nixosConfigurations.''${{ matrix.nixos }}.config.system.build.toplevel --print-build-logs
              '';
            }
            remainingSpaceStep
          ];
      };

      deploy = {
        name = "Deploy";
        runs-on = "ubuntu-latest";
        needs = [ "nixos" ];
        steps =
          basicSetupSteps
          ++ atticSetupSteps
          ++ [
            ## NOTE: No emulation layer because we already built the
            ## configuration so everything should be in Attic. If not,
            ## we might as well fail.
            {
              name = "Deploy machines";
              "if" = "\${{ github.ref == 'refs/heads/main' }}";
              run = ''
                echo "''${{ secrets.DEPLOY_KEY }}" > deploy-key
                chmod 600 deploy-key
                ssh-agent bash -c '
                  ssh-add deploy-key
                  export NIX_CONFIG=$(cat nix-config)
                  nix run .#rebuild -- deploy --action boot --reboot --flake cwd --log raw
                '
              '';
              ## FIXME: It is very brutal to reboot the machine
              ## always, but it avoids the problem of bricked
              ## configurations that I have had lately. I think we
              ## should detect “significant” changes of configuration,
              ## somehow, and only reboot then. (Now even a README
              ## change will reboot all my servers.)  Alternatively,
              ## we can push the update but not reboot the machine and
              ## only have a reboot happen in the middle of the night.
            }
          ];
      };

      check = {
        name = "Check";
        runs-on = "ubuntu-latest";
        strategy = {
          matrix.check = attrNames self.checks.x86_64-linux;
          fail-fast = false;
        };
        steps =
          basicSetupSteps
          ++ atticSetupSteps
          ++ [
            setupEmulationLayerStep
            {
              name = "Run check “\${{ matrix.check }}”";
              run = ''
                export NIX_CONFIG=$(cat nix-config)
                nix build .#checks.x86_64-linux.''${{ matrix.check }} --print-build-logs
              '';
            }
          ];

      };
    };
  };

  flake.github-workflows.bump-dancelor = {
    name = "Bump Dancelor";

    on = {
      workflow_dispatch = { }; # manual triggering
      repository_dispatch.types = [ "bump-dancelor" ]; # when Dancelor changes
    };

    jobs.bump-dancelor = {
      name = "Bump Dancelor";
      runs-on = "ubuntu-latest";

      steps = basicSetupSteps ++ [
        {
          name = "Update flake.lock and create the pull request";
          id = "update";
          uses = "determinatesystems/update-flake-lock@v28";
          "with" = {
            token = "\${{ secrets.GH_TOKEN_FOR_UPDATES }}";
            inputs = "dancelor";
            pr-title = "Bump Dancelor";
            branch = "dancelor/bump-dancelor";
            git-author-name = "Dancelor";
            git-author-email = "dancelor@dancelor.org";
            git-committer-name = "Dancelor";
            git-committer-email = "dancelor@dancelor.org";
          };
        }
        {
          name = "Set up auto-merge for the pull request";
          run = "gh pr merge --auto --squash \${{ steps.update.outputs.pull-request-number }}";
          env.GH_TOKEN = "\${{ secrets.GH_TOKEN_FOR_UPDATES }}";
        }
      ];
    };
  };
}
