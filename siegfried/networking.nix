_: {
  networking = {
    defaultGateway = "37.187.6.254";

    ## Use Google's public DNS servers
    nameservers = [ "8.8.8.8" "8.8.4.4" ];

    interfaces.eth0.ipv4.addresses = [{
      address = "37.187.6.180";
      prefixLength = 24;
    }];

    ## TODO: Open ports in the firewall.
    #firewall.allowedTCPPorts = [ ... ];
    #firewall.allowedUDPPorts = [ ... ];
    ## Or disable the firewall altogether.
    firewall.enable = false;
  };
}
