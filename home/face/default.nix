{ config, ... }:

{
  home.file.".face".source = if config.x_niols.isWork then ./work.jpg else ./niols.jpg;
}
