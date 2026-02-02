{ inputs, lib, ... }:

{
  _class = "nixosTest";

  name = "deployment-basic";

  sourceFileset = lib.fileset.unions [
    ./constants.nix
    ./deployment.nix
    ../cli/constants.nix
    ../cli/deployments.nix
  ];

  nodes.deployer =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.nixops4.packages.${pkgs.system}.default
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

  extraTestScript = ''
    with subtest("Check the status before deployment"):
      hello.fail("hello 1>&2")
      cowsay.fail("cowsay 1>&2")

    with subtest("Run the deployment"):
      deployer.succeed("nixops4 apply check-deployment --show-trace --no-interactive 1>&2")

    with subtest("Check the deployment"):
      hello.succeed("hello 1>&2")
      cowsay.succeed("cowsay hi 1>&2")
  '';
}
