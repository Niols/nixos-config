{ inputs, ... }:

{
  flake.homeConfigurations.laptop-niols = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [ ./laptop-niols ];
    extraSpecialArgs = { inherit inputs; };
  };

  flake.homeConfigurations.laptop-work = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [ ./laptop-work ];
    extraSpecialArgs = { inherit inputs; };
  };
}
