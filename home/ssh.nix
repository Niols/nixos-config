{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      siegfried = {
        host = "siegfried";
        hostname = "siegfried.niols.fr";
        user = "root";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
