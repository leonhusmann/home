{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.disko.nixosModules.default
    ./disko.nix
    ./modules/openvpn.nix
    ./modules/traefik.nix
    ./modules/ddns.nix
    ./modules/fail2ban.nix
    ./modules/adguardhome.nix
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.swraid.mdadmConf = ''
    MAILADDR root
  '';

  networking.hostName = "home";
  networking.networkmanager.enable = true;

  networking.nameservers = [ "127.0.0.1" ];

  services.dnsmasq.enable = false; # Explicitly disable dnsmasq to avoid port conflict with AdGuard Home.

  users.groups.acme = {};

  security.sudo.wheelNeedsPassword = false;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ 1194 ];
    extraCommands = ''
      # Allow DNS from localhost
      iptables -A nixos-fw -p udp -s 127.0.0.1 -d 127.0.0.1 --dport 53 -j ACCEPT
      iptables -A nixos-fw -p tcp -s 127.0.0.1 -d 127.0.0.1 --dport 53 -j ACCEPT
      # Allow DNS from local network to local DNS server
      iptables -A nixos-fw -p udp -s 192.168.3.0/24 -d 192.168.3.100 --dport 53 -j ACCEPT
      iptables -A nixos-fw -p tcp -s 192.168.3.0/24 -d 192.168.3.100 --dport 53 -j ACCEPT
    '';
  };

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  users.users.leon = {
    isNormalUser = true;
    extraGroups = [ "wheel" "acme" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAtGkUIb85pLJDLTeFE0OvnZCDAJzr4O7HIbWwuNLnnT leon@husmann.me"
    ];
    hashedPassword = "$y$j9T$R5gMPeLXNSX2U2TNZOrPS0$VCD0YYAcX4ZiGqMMdBALYlxhb7Mu3qz1NPxa391VGx0";
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    htop
    atop
    iotop
    ncdu
    duf
    iftop
    nethogs
    mtr
    lnav
    tmux
    curl
    dig
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  system.stateVersion = "25.11";

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets = {
    cloudflare-token = {
      file = ./secrets/cloudflare-token.age;
      mode = "400";
    };
    cloudflare-env = {
      file = ./secrets/cloudflare-env.age;
      mode = "400";
    };
    traefik-auth = {
      file = ./secrets/traefik-auth.age;
      mode = "400";
      owner = "traefik";
    };
  };
}
