{
  inputs,
  lib,
  ...
}:

let
  inherit (lib)
    elem
    mkOption
    types
    concatMapAttrs
    optionalAttrs
    removeSuffix
    ;

  secrets = import ./secrets.nix;
  keys = import ../keys/keys.nix;

  commonModule =
    { config, osConfig, ... }:
    {
      options.x_niols.agePublicKey =
        mkOption ({
          description = ''
            The public key that will allow decrypting secrets. It will be used
            to filter Age secrets and only keep the relevant ones. Defaults to
            `keys.machines.<device name>` on NixOS configurations and
            `keys.homes.<device name>-<user name>` on Home configurations where
            Home Manager is handled by NixOS module. It is mandatory for standalone
            Home configurations.
          '';
          type = types.str;
        })
        // (
          if !(config ? home) then
            ## NixOS configuration
            { default = keys.machines.${config.x_niols.thisMachinesName}; }
          else if osConfig != null then
            ## Home configuration where HM comes from NixOS module
            { default = keys.homes."${osConfig.x_niols.thisMachinesName}-${config.home.username}"; }
          else
            { }
        );

      config.age.secrets = concatMapAttrs (
        name: secret:
        optionalAttrs (elem config.x_niols.agePublicKey secret.publicKeys) ({
          ${removeSuffix ".age" name}.file = ./. + "/${name}";
        })
      ) secrets;
    };

in
{
  flake = {
    inherit secrets;

    nixosModules.secrets.imports = [
      inputs.agenix.nixosModules.default
      commonModule
    ];

    homeModules.secrets =
      { config, ... }:
      {
        imports = [
          inputs.agenix.homeManagerModules.default
          commonModule
        ];
        age.identityPaths = [ "${config.home.homeDirectory}/.ssh/id_hm_age" ];
      };
  };
}
