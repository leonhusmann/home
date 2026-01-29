{ config, pkgs, ... }:

{
  services.traefik = {
    enable = true;
    group = "acme";

    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
            permanent = true;
          };
        };
        
        websecure = {
          address = ":443";
        };
      };

      certificatesResolvers.letsencrypt.acme = {
        email = "leon@husmann.me";
        storage = "${config.services.traefik.dataDir}/acme.json";
        dnsChallenge = {
          provider = "cloudflare";
          resolvers = [ "1.1.1.1:53" ];
        };
      };

      api.dashboard = true;

      log = {
        level = "INFO";
        filePath = "${config.services.traefik.dataDir}/traefik.log";
        format = "json";
      };
    };

    dynamicConfigOptions = {
      http = {
        middlewares = {
          auth.basicAuth.usersFile = config.age.secrets.traefik-auth.path;
          
          allow-local.ipAllowList.sourceRange = [
            "192.168.3.0/24"
            "10.8.0.0/24"
          ];
          
          allow-public.ipAllowList.sourceRange = [
            "0.0.0.0/0"
            "::/0"
          ];
        };

        routers = {
          dashboard = {
            rule = "Host(`traefik.husmann.me`)";
            service = "api@internal";
            middlewares = [ "allow-local@file" "auth@file" ];
            entryPoints = [ "websecure" ];
            tls = {
              certResolver = "letsencrypt";
              domains = [{
                main = "husmann.me";
                sans = [ "*.husmann.me" ];
              }];
            };
          };
        };
      };
    };

    environmentFiles = [ config.age.secrets.cloudflare-env.path ];
  };

  users.users.traefik.extraGroups = [ "acme" ];
}


