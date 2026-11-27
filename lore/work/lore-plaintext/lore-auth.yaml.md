cat lore-auth.yaml 
# Unknown keys are parse errors. Remove typos or unsupported keys instead of
# leaving them in this file.

server:
  # This example assumes a reverse proxy or load balancer exposes
  # https://auth.example.com:8080 (HTTP) and :8081 (gRPC), and forwards
  # to these loopback listeners.
  # If bridge is exposed directly, bind to a non-loopback address instead.
  # Apply rate limits for login and device-flow endpoints at the public proxy.
  # Configure proxy access logs to omit or redact query strings such as
  # OAuth code and device user_code values.
  # When exposing gRPC through a public proxy, restrict /ucs.auth.RebacApi/*
  # at the proxy so only loreserver can call ReBAC resource sync.
  listen: "127.0.0.1:18080"
  grpc_listen: "127.0.0.1:18081"
  # gRPC must be TLS for the lore CLI (it always dials https:// for ucs-auth).
  # Provide a cert trusted by the CLI/loreserver, or terminate TLS at a proxy.
  grpc_tls_cert_file: "/datadrive/lore/certs/lore-server.crt"
  grpc_tls_key_file: "/datadrive/lore/certs/lore-server.key"
  public_base_url: "https://172.20.11.216:8080"

identity_providers:
  # Provider instance IDs are part of the bridge identity key; keep this ID stable.
  default: entra
  providers:
    entra:
      type: oidc
      profile: entra
      display_name: "Microsoft Entra ID"
      # Replace this tenant ID in both issuer and subject.required_tid.
      issuer: "https://login.microsoftonline.com/ec5c9760-1e1d-4de3-a9ff-c2fcf61d617f/v2.0"
      client_id: "980c48a2-e30f-4fee-a8c6-21b831de9979"
      # Store the secret itself in this file, not in YAML.
      client_secret_file: "/datadrive/lore/auth/entra-client-secret"
      # Must exactly match a redirect URI registered in the Entra application.
      redirect_url: "https://172.20.11.216:8080/auth/entra/callback"
      scopes:
        - openid
        - email
        - profile
      pkce: required
      subject:
        strategy: entra_oid_tid
        required_tid: "ec5c9760-1e1d-4de3-a9ff-c2fcf61d617f"
      trust:
        email_binding: verified_email_invitation

database:
  path: "/datadrive/lore/auth/data/lore-auth.sqlite3"

authz:
  # rebac is the default authorization backend. It evaluates grants and nested
  # groups through the authz-core based ReBAC adapter.
  # Omit this section or keep backend: rebac.
  backend: rebac

jwt:
  issuer: "https://172.20.11.216:8080"
  audience:
    - "lore-service"
    - "172.20.11.216"
  ttl_seconds: 32400
  signing_key_dir: "/datadrive/lore/auth/keys"
  active_kid: "lore-216-01"

lore:
  # default_remote_url: "lore://lore.example.com:41337"
  # Auth gRPC endpoint advertised to Lore.
  # Use an HTTPS gRPC endpoint here.
  auth_url: "https://172.20.11.216:8081"

admin:
  admin_emails: ["ueno.s@gamestudio.co.jp","kobayashi.y@gamestudio.co.jp"]

# Admin Web UI is disabled when admin.admin_emails is omitted or empty.
# Production deployments should still put /admin behind nginx/caddy and
# Cloudflare access controls; this in-process guard is not a public edge ACL.
# admin:
#   admin_emails:
#     - "admin@example.com"
#   # Opt in to read/write/admin access to all existing and future repositories.
#   global_repository_admin: false

security:
  device_code_ttl_seconds: 600
  device_poll_interval_seconds: 3
  session_ttl_seconds: 3600
  # ReBAC is a service-to-service API called by loreserver.
  # If omitted, bridge allows only loopback peers for ReBAC gRPC methods.
  # This check sees the immediate TCP peer; behind a public reverse proxy,
  # enforce the loreserver-only rule at the proxy as well.
  rebac_allowed_peer_cidrs:
    - "127.0.0.1/32"
    - "::1/128"
  # Optional extra existence-hiding peer allowlist for /admin.
  # This sees the immediate TCP peer only; do not rely on X-Forwarded-For.
  # Behind a reverse proxy, enforce the public admin ACL at that proxy too.
  # admin_allowed_peer_cidrs:
  #   - "127.0.0.1/32"
root@gspcd581:/datadrive/lore/config# root@gspcd581:/datadrive/lore/config# root@gspcd581:/datadrive/lore/config# root@gspcd581:/datadrive/lore/config# 