{ pkgs, ... }:

{
  programs.ssh = {
    ## NOTE: With pkgs.openssh and Ahrefs's nspawn configuration, I get GSS API
    ## errors. https://github.com/NixOS/nixops/issues/395 suggested to instead
    ## use `pkgs.opensshWithKerberos`.
    package = pkgs.opensshWithKerberos;

    ## NOTE: A lot of things in the following configuration require the the
    ## correct symbolic link has been set up from `~/.ssh` into the right place
    ## on the Ahrefs monorepo.

    includes = [
      "~/.ssh/ahrefs/config"
    ];

    matchBlocks = {
      nspawn.extraOptions.Include = "~/.ssh/ahrefs/per-user/spawnbox-devbox-uk-nicolasjeannerod";
      hop.user = "nicolas.jeannerod";

      ## catch-all
      "*" = {
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ahrefs";
      };
    };
  };
}
