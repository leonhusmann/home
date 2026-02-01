{ config, pkgs, ... }:

{
  services.adguardhome = {
    enable = true;
    mutableSettings = true;

    settings = {

      dns = {
        bind_host = "0.0.0.0";
        port = 53;

        upstream_dns = [
          "https://cloudflare-dns.com/dns-query"
          "https://dns.google/dns-query"
        ];

        bootstrap_dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];

        # blocking_mode = "null_ip"; # Commented out to disable ad-blocking for now.
        dnssec_enabled = true;
        cache_size = 10000000;
      };

      http = {
        address = "0.0.0.0";
        port = 3000;
      };

      filters = [ ];

      filtering = {
        rewrites_enabled = true;
        rewrites = [
          { domain = "husmann.me"; answer = "192.168.3.100"; enabled = true; }
          { domain = "*.husmann.me"; answer = "192.168.3.100"; enabled = true; }
        ];
      };

      filter_update_interval = 24;
      querylog_enabled = true;
      querylog_file_enabled = true;
      statistics_enabled = true;
    };
  };
}
