{ config, pkgs, lib, ... }:

let
  vpnClients = [
    # Add client names here, e.g. "laptop" "phone"
  ];

  vpnRemote = "vpn.husmann.me";
  vpnPort = 1194;

  mkClientService = clientName: {
    name = "openvpn-client-${clientName}";
    value = {
      description = "Generate OpenVPN client config for ${clientName}";
      after = [ "openvpn-pki-init.service" ];
      requires = [ "openvpn-pki-init.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "/var/lib/openvpn";
      };

      path = [ pkgs.easyrsa pkgs.gawk ];

      script = ''
        if [ ! -f "pki/issued/${clientName}.crt" ]; then
          # Set EASYRSA_PKI to avoid X509_TYPES copy issue
          export EASYRSA_PKI="$PWD/pki"
          
          easyrsa --batch build-client-full ${clientName} nopass
        fi

        cat > /var/lib/openvpn/${clientName}.ovpn <<EOF
        client
        dev tun
        proto udp
        remote ${vpnRemote} ${toString vpnPort}
        resolv-retry infinite
        nobind
        persist-key
        persist-tun
        remote-cert-tls server
        cipher AES-256-GCM
        auth SHA256
        key-direction 1
        verb 3

        <ca>
        $(cat pki/ca.crt)
        </ca>
        <cert>
        $(cat pki/issued/${clientName}.crt)
        </cert>
        <key>
        $(cat pki/private/${clientName}.key)
        </key>
        <tls-auth>
        $(cat ta.key)
        </tls-auth>
        EOF

        chmod 600 /var/lib/openvpn/${clientName}.ovpn
      '';
    };
  };

in
{
  services.openvpn.servers.home = {
    config = ''
      port ${toString vpnPort}
      proto udp
      dev tun
      
      topology subnet
      server 10.8.0.0 255.255.255.0
      
      push "route 192.168.3.0 255.255.255.0"
      push "redirect-gateway def1 bypass-dhcp"
      push "dhcp-option DNS 192.168.3.100"
      
      ca /var/lib/openvpn/ca.crt
      cert /var/lib/openvpn/server.crt
      key /var/lib/openvpn/server.key
      dh /var/lib/openvpn/dh.pem
      tls-auth /var/lib/openvpn/ta.key 0
      
      cipher AES-256-GCM
      auth SHA256
      
      user nobody
      group nogroup
      persist-key
      persist-tun
      
      keepalive 10 120
      verb 3
    '';
  };

  systemd.services = {
    openvpn-pki-init = {
      description = "Initialize OpenVPN PKI and server certificates";
      wantedBy = [ "multi-user.target" ];
      before = [ "openvpn-home.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "openvpn";
        WorkingDirectory = "/var/lib/openvpn";
      };

      path = [ pkgs.easyrsa pkgs.openvpn pkgs.gawk ];

      script = ''
        # Only initialize if CA doesn't exist
        if [ ! -f "/var/lib/openvpn/ca.crt" ]; then
          # Set EASYRSA_PKI before any easyrsa commands
          export EASYRSA_PKI="/var/lib/openvpn/pki"
          
          # Initialize PKI
          easyrsa --batch init-pki
          
          # Build CA
          easyrsa --batch --req-cn="OpenVPN CA" build-ca nopass
          
          # Build server certificate
          easyrsa --batch build-server-full server nopass
          
          # Generate DH parameters
          easyrsa gen-dh
          
          # Generate TLS auth key
          openvpn --genkey secret /var/lib/openvpn/ta.key
          
          # Copy certificates to /var/lib/openvpn/
          cp /var/lib/openvpn/pki/ca.crt /var/lib/openvpn/
          cp /var/lib/openvpn/pki/issued/server.crt /var/lib/openvpn/
          cp /var/lib/openvpn/pki/private/server.key /var/lib/openvpn/
          cp /var/lib/openvpn/pki/dh.pem /var/lib/openvpn/
          
          # Set permissions
          chmod 600 /var/lib/openvpn/server.key /var/lib/openvpn/ta.key
          
          echo "OpenVPN PKI initialized successfully"
        else
          echo "OpenVPN PKI already initialized"
        fi
      '';
    };
  } // builtins.listToAttrs (map mkClientService vpnClients);

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.nat = {
    enable = true;
    externalInterface = "eth0";
    internalInterfaces = [ "tun" ];
  };

  networking.firewall.trustedInterfaces = [ "tun" ];
}
