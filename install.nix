{
  perSystem =
    { pkgs, ... }:
    {
      apps.install = {
        type = "app";
        program = pkgs.writeShellApplication {
          name = "install";
          runtimeInputs = with pkgs; [ disko ];
          text = ''
            #!${pkgs.runtimeShell}
            set -euC

            if [ $# -ne 1 ]; then
              printf 'Usage: install <machine>\n'
              exit 2
            fi

            printf 'Partitioning...\n'
            disko --flake .#"$1"
            printf 'Partitioning done.\n'

            printf 'Installing system...\n'
            nixos-install --flake .#"$1"
            printf 'System installation done.\n'
          '';
        };
      };
    };
}
