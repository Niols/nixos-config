{ config, ... }:

{
  environment.systemPackages = config.x_niols.sharedPackages;
}
