let
  personal = "age1x8xm9pg9yjvtd9drsptkvxwegcxshhpd04zskmjq3k35s4tplqespe4uhn";
  server = "age1geztsywkkzt69lfsz75cznt3r2f0rl4d8qtxvra6mh36zcy075pqzpaan9";
in {
  "cloudflare-token.age".publicKeys = [ personal server ];
  "cloudflare-env.age".publicKeys = [ personal server ];
  "traefik-auth.age".publicKeys = [ personal server ];
}
