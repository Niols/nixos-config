_: {
  programs.rust-motd = {
    enable = true;

    settings = {
      global = {
        progress_full_character = "#";
        progress_empty_character = "-";
        progress_prefix = "[";
        progress_suffix = "]";
        time_format = "%Y-%m-%d %H:%M:%S";
      };

      banner = {
        color = "green";
        command = "echo Siegfried | figlet -f standard";
      };

      update = {
        prefix = "Up";
      };

      user_service_status = {
        gpg-agent = "gpg-agent";
      };

      filesystems = {
        root = "/";
          boot = "/boot";
      };

      memory = {
        swap_pos = "below";
      };

      last_login = {
        root = 5;
        niols = 5;
      };

      last_run = {};
    };
  };
}
