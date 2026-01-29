{ config, pkgs, lib, ... }:

{
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "10m";
    
    ignoreIP = [
      "127.0.0.0/8"
      "192.168.3.0/24"
    ];
  };
}
