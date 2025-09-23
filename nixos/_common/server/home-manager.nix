{ config, ... }:

## FIXME: Merge laptop and server home managers.

## FIXME: This is really only for starship, which is quite ridiculous. Make the
## starship configuration user-agnostic, and get rid of home manager except on
## machines where it really makes sense.

## NOTE: It is important to enable Bash so that Home Manager active
## properly. Otherwise, see Home Manager's documentation.
{
  home-manager.users =
    (
      if config.x_niols.enableNiolsUser then
        {
          niols = {
            home.stateVersion = "21.05";
            programs.home-manager.enable = true;
            programs.bash.enable = true;
          };
        }
      else
        { }
    )
    // {
      root = {
        home.stateVersion = "21.05";
        programs.home-manager.enable = true;
        programs.bash.enable = true;
      };
    };
}
