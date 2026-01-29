{ config, pkgs, lib, ... }:

{
  services.ddclient = {
    enable = true;
    protocol = "cloudflare";
    zone = "husmann.me";
    username = "token";
    passwordFile = config.age.secrets.cloudflare-token.path;
    interval = "5min";
    use = "web, web=checkipv4.dedyn.io/";
    usev6 = "webv6, webv6=checkipv6.dedyn.io/";
    domains = [ "*.husmann.me" ];
    ssl = true;
  };

  systemd.services.ddclient = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };
}
