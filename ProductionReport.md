# Production Report — GeoNode behind a Front (Corporate) NGINX

Date: 2025-10-26
Environment: Dockerized GeoNode 4.4.x stack (django / nginx / geoserver / postgis / rabbitmq / memcached)
Goal: Run GeoNode behind a front/corporate NGINX reverse proxy, keep user-facing HTTPS, and make uploads/api calls work without mixed-content or proxy loop errors.

⸻

1. Final Architecture We Landed On

Internet (HTTPS 443)
↓
Front/Corporate NGINX (terminates public TLS, proxies inward over HTTP 8085)
↓
GeoNode NGINX (listens on 8085 HTTP; optional internal 8443 unused today)
↓
Django (uwsgi :8000) + GeoServer (:8080)

Public URL used everywhere: https://test.lab.de/

⸻

2. Symptoms We Fought
   • Uploads hitting /proxy/?url=... were generated as HTTP (mixed content), returning 502 from the front proxy.
   • Attempts to flip everything to internal HTTPS surfaced certificate path / symlink errors inside GeoNode NGINX (/certificate_symlink/\*.pem not found), causing NGINX to fail to start.
   • At one point, front NGINX ACME/SSL issuance failed for the original hostname, yet succeeded for a test hostname (suggesting stale/locked cert data or rate/limits).

⸻

3. Root Causes (Short & Sweet) 1. Django didn’t know it was behind HTTPS.
   Without the proper forwarded-proto/host handling, Django/GeoNode generated absolute HTTP URLs (not HTTPS), breaking uploads and redirects through the front proxy. 2. Certificate symlink expectations in GeoNode NGINX.
   The bundled entrypoint expects /certificate_symlink/ to point to either autoissued self-signed certs or letsencrypt/<mode>/live/<host>/…. When that path wasn’t present or got deleted/recreated at the wrong time, NGINX crashed.

⸻

4. What Actually Fixed It

4.1 Critical Django/GeoNode settings (the real heroes)

# .env (effective)

USE_X_FORWARDED_HOST=True
SECURE_PROXY_SSL_HEADER=HTTP_X_FORWARDED_PROTO,https # <-- CRITICAL
CSRF_TRUSTED_ORIGINS="['https://test.lab.de/']"

# Make GeoNode generate external URLs properly

NGINX_BASE_URL=https://test.lab.de/
SITEURL=${NGINX_BASE_URL}/

# Optional but helpful for proxy-based features / email links

PROXY_BASE_URL=https://test.lab.de/
ACCOUNT_DEFAULT_HTTP_PROTOCOL=https

# Security / proxy-specific knobs (not the root fix, but kept)

SESSION_COOKIE_SECURE=True
PROXY_ALLOWED_HOSTS = ('test.lab.de',)
PROXY_URL = '/proxy/'
ALLOWED_HOSTS="['localhost','127.0.0.1','django','test.lab.de']"

# Ports (internal publish)

HTTP_HOST=test.lab.de
HTTP_PORT=8085

# HTTPS_HOST/HTTPS_PORT left unused today

TL;DR: The two must-have lines are:
• SECURE_PROXY_SSL_HEADER=('HTTP_X_FORWARDED_PROTO','https')
• USE_X_FORWARDED_HOST=True

Full list as :

USE_X_FORWARDED_HOST=True
SECURE_PROXY_SSL_HEADER=HTTP_X_FORWARDED_PROTO,https
CSRF_TRUSTED_ORIGINS="['https://test.lab.de']"
PROXY_BASE_URL=https://test.lab.de
ACCOUNT_DEFAULT_HTTP_PROTOCOL=https
SESSION_COOKIE_SECURE=True
PROXY_ALLOWED_HOSTS = ('test.lab.de',)
PROXY_URL = '/proxy/'

These make Django treat requests as HTTPS and respect the external host, so it emits https://… URLs and the proxy no longer chokes.

4.2 NGINX entrypoint (our hardened version)

We kept HTTP mode internally (port 8085) and stopped forcing internal HTTPS.
We also stabilized cert handling so NGINX always finds a certificate (self-signed if Let’s Encrypt is not present), without racing or wiping the mount unexpectedly.

Key behaviors in our entrypoint.sh:
• Ensure /geonode-certificates/<mode> exists.
• Create/refresh self-signed cert in /geonode-certificates/autoissued/ if missing/old.
• Point /certificate_symlink/ to:
• Let’s Encrypt live certs if present, otherwise
• autoissued self-signed certs.
• Compute PUBLIC_HOST dynamically depending on HTTP_PORT/HTTPS_PORT.
• Generate config from \*.envsubst templates and enable HTTPS section only if HTTPS_HOST is set. (We left it unset, so internal remains HTTP.)

Result: GeoNode NGINX boots reliably, even without Let’s Encrypt, while the front NGINX is the only public TLS endpoint.

⸻

5. Front NGINX headers (reference)

We initially thought these were required; with the Django settings fixed, they’re nice-to-have but not the sole fix. Still, keep them as a stable pattern:

proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto https; # helps reinforce scheme
proxy_set_header X-Forwarded-Host $http_host;
proxy_set_header X-Forwarded-Port 443;

⸻

6. Verification Checklist
   • curl -I http://<front-nginx>/ → 301 to https://test.lab.de/ (if you force redirect).
   • Browser Network tab during upload:
   • Requests go to https://test.lab.de/proxy/?url=https://… (no http:// leaks).
   • Response codes 2xx/3xx; no 502.
   • Django shell quick sanity:

⸻

1. Open Items / Next Steps

   1. Minimal .env audit:
      Now that it works, trim to the smallest set required (keep the two critical lines + SITEURL/ALLOWED_HOSTS). Confirm whether PROXY_BASE_URL is still needed for your plugins/workflows.
   2. Let’s Encrypt, later:
      If you ever want the container to terminate TLS (not recommended while you have a strong front NGINX), set LETSENCRYPT_MODE=production(we should try on local workstation with https://ip:port) and ensure HTTPS_HOST is set and port 443 is published. For now you don’t need this—the front proxy already handles certs.
   3. Geoserver proxyBaseUrl:
      Double-check GeoServer’s proxyBaseUrl points to https://test.lab.de/geoserver/ to avoid any absolute http references from WMS/WFS capabilities.
      ⸻

1. Lessons Learned
   • In proxy setups, Django must be told it’s under HTTPS. Without SECURE_PROXY_SSL_HEADER + USE_X_FORWARDED_HOST, you’ll chase ghosts (HTTP URLs, 502 on upload, CSRF noise).

⸻

1. Quick “Known-Good” Snippets

.env core

USE_X_FORWARDED_HOST=True
SECURE_PROXY_SSL_HEADER=HTTP_X_FORWARDED_PROTO,https
CSRF_TRUSTED_ORIGINS="['https://test.lab.de']"

NGINX_BASE_URL=https://test.lab.de
SITEURL=${NGINX_BASE_URL}/

ALLOWED_HOSTS="['localhost','127.0.0.1','django','test.lab.de']"

PROXY_BASE_URL=https://test.lab.de
ACCOUNT_DEFAULT_HTTP_PROTOCOL=https
SESSION_COOKIE_SECURE=True
PROXY_ALLOWED_HOSTS = ('test.lab.de',)
PROXY_URL = '/proxy/'

HTTP_HOST=test.lab.dev
HTTP_PORT=8085

# HTTPS_HOST/PORT left unset (internal TLS disabled)

Front NGINX (reference headers)

proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto https;
proxy_set_header X-Forwarded-Host $http_host;
proxy_set_header X-Forwarded-Port 443;

Entrypoint (what we used)
• Generates/refreshes self-signed certs.
• Symlinks /certificate_symlink to the right place.
• Enables HTTPS block only if HTTPS_HOST is defined.
• Works fine with internal HTTP (current mode).
