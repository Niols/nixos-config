{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    extraOptionOverrides = {
      AddKeysToAgent = "yes";
    };

    ## My machines
    ##
    ## TODO: This part should be generated (except Hester), and we should
    ## generate a `userKnownHostsFile` based on the keys in the `keys/`
    ## directory.
    matchBlocks = {
      helga = {
        host = "helga";
        hostname = "helga.niols.fr";
        user = "root";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519";
      };
      orianne = {
        host = "orianne";
        hostname = "orianne.niols.fr";
        user = "root";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519";
      };
      siegfried = {
        host = "siegfried";
        hostname = "siegfried.niols.fr";
        user = "root";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519";
      };
      hester = {
        host = "hester";
        user = "u363090";
        hostname = "hester.niols.fr";
        port = 23;
      };
    };

    ## Mions
    matchBlocks = {
      nasgul = {
        host = "nasgul";
        hostname = "nasgul.jeannerod.me";
        port = 40022;
        user = "niols";
      };
      gimli = {
        user = "root";
        hostname = "192.168.1.11";
        extraOptions.PubkeyAuthentication = "no";
        extraOptions.PreferredAuthentications = "password";
      };
    };

    ## Youth Branch VPS
    matchBlocks = {
      vpsyb = {
        host = "vpsyb";
        user = "root";
        hostname = "137.74.166.97";
        extraOptions.PubkeyAuthentication = "no";
        extraOptions.PreferredAuthentications = "password";
      };
    };

    ## For things on localhost, we should not check the host's key, and we
    ## should just not keep the keys at all.
    matchBlocks = {
      localhost = {
        host = "localhost";
        extraOptions.StrictHostKeyChecking = "no";
        extraOptions.UserKnownHostsFile = "/dev/null";
      };
      localhost_star = {
        host = "*.localhost";
        extraOptions.StrictHostKeyChecking = "no";
        extraOptions.UserKnownHostsFile = "/dev/null";
      };
    };
  };
}
