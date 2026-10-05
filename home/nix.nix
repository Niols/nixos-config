{
  osConfig,
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkMerge;

in
{
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  config = mkMerge [
    (mkIf (osConfig == null) {
      ## This is the default in NixOS configurations. However, in Home
      ## configurations, this instructs HM to generate the configuration.
      nix.package = pkgs.nix;

      ## Outside NixOS, Nix defaults to building one derivation at a time. The
      ## static options would only allow to have max-jobs = auto = number of
      ## cores and cores = 0 = number of cores. On a 512 cores machine, that is
      ## up to 512 parallel builds each using up to 512 processes, so we instead
      ## detect reasonable numbers around √(2 × nproc) at activation time.
      ##
      nix.extraOptions = ''
        !include ${config.xdg.configHome}/nix/parallelism.conf
      '';
      home.activation.nixParallelism = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        n=$(${pkgs.gawk}/bin/awk -v nproc="$(${pkgs.coreutils}/bin/nproc)" \
          'BEGIN { printf "%d", sqrt(2 * nproc) + 0.5 }')
        run ${pkgs.coreutils}/bin/install -D -m 644 /dev/stdin \
          ${config.xdg.configHome}/nix/parallelism.conf <<EOF
        max-jobs = $n
        cores = $n
        EOF
      '';
    })

    ## Set up Attic for authentication to private substituters. This can contain
    ## sensitive tokens, and we do not trust standalone installations with this,
    ## because they exist on machines that we don't control.
    (mkIf (osConfig != null) {
      xdg.configFile."attic/config.toml".source = pkgs.runCommand "config.toml" { } ''
        ln -s ${config.age.secrets.attic-client-config.path} $out
      '';
    })

    {
      programs.nix-index.enable = true;
      programs.nix-index.symlinkToCacheHome = true;
      programs.nix-index-database.comma.enable = true;
    }
  ];
}
