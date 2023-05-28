{ ... }:

{
  boot = {
    ## Necessary for predictable names, eg. `eth0` for ethernet.
    ## REVIEW: what about networking.usePredictableInterfaceNames = false?
    kernelParams = [ "net.ifnames=0" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
