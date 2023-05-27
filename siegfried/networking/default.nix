_: {
  imports = [ ./hostName.nix ];

  networking = {
    defaultGateway = "37.187.6.254";
    defaultGateway6 = "2001:41d0:a:6ff:ff:ff:ff:ff";

    ## Use Google's public DNS servers
    nameservers =
      [ "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844" ];

    interfaces.eth0.ipv4.addresses = [{
      address = "37.187.6.180";
      prefixLength = 24;
    }];

    interfaces.eth0.ipv6.addresses = [{
      address = "2001:41d0:a:6b4::1";
      prefixLength = 56;
    }];

    ## TODO: Open ports in the firewall.
    #firewall.allowedTCPPorts = [ ... ];
    #firewall.allowedUDPPorts = [ ... ];
    ## Or disable the firewall altogether.
    firewall.enable = false;
  };
}
