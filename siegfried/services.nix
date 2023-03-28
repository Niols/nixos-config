_: {
  services = {
    openssh = {
      enable = true;
      ports = [ 22 2222 3000 9100 ];
    };
  };
}
