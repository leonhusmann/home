# NixOS Home Server

Declarative NixOS configuration with RAID1+LVM storage, OpenVPN, Dynamic DNS, HTTPS, and Traefik.

## Creating Secrets

### One-Time Setup

1. Get server SSH public key and save to file:

```bash
ssh leon@192.168.3.100 "cat /etc/ssh/ssh_host_ed25519_key.pub" > /tmp/server-ssh.pub
```

2. Verify `secrets/secrets.nix` lists the correct recipients (already configured for this repo)

### Creating a New Secret

1. Create a temporary file with your secret content:

```bash
echo "your_secret_value" > /tmp/my-secret
```

2. Encrypt using SSH public keys directly:

```bash
cat /tmp/my-secret | nix-shell -p age --run 'age --encrypt -R ~/.ssh/home.pub -R /tmp/server-ssh.pub -o secrets/my-secret.age'
```

3. Clean up and add to secrets.nix:

```bash
rm /tmp/my-secret
```

Add to `secrets/secrets.nix`:

```nix
"my-secret.age".publicKeys = [ personal server ];
```

4. Reference in configuration:

```nix
age.secrets.my-secret = {
  file = ./secrets/my-secret.age;
  mode = "400";
};
```

### Important Notes

- Always use `-R <ssh-public-key-file>` NOT `-r age1...` when encrypting
- Encrypt to BOTH your local SSH key (`~/.ssh/home.pub`) and server key (`/tmp/server-ssh.pub`)
- For secrets with env var format (like Traefik), include the prefix: `CF_DNS_API_TOKEN=value`
- For secrets as raw values (like ddclient), just the value: `value`
- Never commit unencrypted secrets or `/tmp/` files

## What Should Be Secret?

**YES (encrypted with agenix)**:
- API tokens (CloudFlare, etc.)
- Private keys
- Passwords (plain text)
- Database credentials

**NO (safe to commit)**:
- SSH public keys (public by design)
- Email addresses
- Domain names
- Hashed passwords (already hashed with argon2)

## Router Setup

Forward these ports to 192.168.3.100:
- UDP 1194 (OpenVPN)
- TCP 80 (ACME challenges)
- TCP 443 (HTTPS)

## CloudFlare DNS Setup

Add these records:
- A `*` → your public IPv4
- AAAA `*` → your public IPv6 (if available)

ddclient will auto-update them.

## Service Access

| Service | Domain | Access |
|---------|--------|--------|
| OpenVPN | vpn.husmann.me:1194 | Internet |
| Traefik | traefik.husmann.me | Local + VPN (default) |
| Future | *.husmann.me | Add `middlewares = [ "allow-public" ];` for internet access |

## Updates

```bash
nix run nixpkgs#nixos-rebuild -- --flake .#home --target-host leon@192.168.3.100 --build-host leon@192.168.3.100 --sudo boot
ssh leon@192.168.3.100 "sudo reboot"
```
