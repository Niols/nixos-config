_: {
  services.nfs.server = {
    enable = true;
    exports = ''
      /srv         158.178.195.191(rw,fsid=0,no_subtree_check)
      /srv/tvshows 158.178.195.191(rw,nohide,insecure,no_subtree_check)
    '';
    ##             ^^^ Orianne ^^^
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];
}
