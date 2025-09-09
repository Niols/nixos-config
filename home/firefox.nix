{
  programs.firefox = {
    enable = true;

    languagePacks = [ "en-GB" ];

    profiles.default = {
      # force = true; # REVIEW: only when ready
      bookmarks = {
        settings = [
          {
            name = "wikipedia";
            tags = [ "wiki" ];
            keyword = "wiki";
            url = "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
          }
        ];
      };

      extensions = {
        # force = true; # REVIEW: only when ready
        packages = { };
      };

      search = {
        force = true;
        order = [ "ddg" ]; # `ddg`, not `duckduckgo` - built-in search engine
      };
    };

    ## The current policies can be seen with `about:policies`.
    policies = {
      OfferToSaveLogins = false;
    };
  };
}
