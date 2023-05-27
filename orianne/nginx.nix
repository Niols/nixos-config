_: {
  services.nginx.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "niols@niols.fr";
  };
}
