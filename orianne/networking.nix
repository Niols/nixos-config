_: {
  networking = {
    defaultGateway = "141.145.193.254";

    ## Use Google's public DNS servers
    nameservers = [ "8.8.8.8" "8.8.4.4" ];

    interfaces.eth0.ipv4.addresses = [{
      address = "141.145.193.23";
      prefixLength = 24;
    }];

    ## TODO: Open ports in the firewall.
    #firewall.allowedTCPPorts = [ ... ];
    #firewall.allowedUDPPorts = [ ... ];
    ## Or disable the firewall altogether.
    firewall.enable = false;
  };
}
