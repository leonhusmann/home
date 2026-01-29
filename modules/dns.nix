{ config, pkgs, ... }:

{
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      listen-address = "127.0.0.1,192.168.3.100";
      address = "/husmann.me/192.168.3.100";
    };
  };

  networking.nameservers = [ "127.0.0.1" "1.1.1.1" ];
  networking.search = [ "husmann.me" ];
}