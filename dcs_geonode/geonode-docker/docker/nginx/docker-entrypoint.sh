#!/bin/sh
set -e

echo ""
echo "-----------------------------------------------------"
echo "STARTING NGINX ENTRYPOINT ---------------------------"
date

# ────────────────────────────────────────────────
# 1️⃣  Certificate Directory Check
# ────────────────────────────────────────────────
# GeoNode expects a directory structure like /geonode-certificates/<mode>.
mkdir -p "/geonode-certificates/${LETSENCRYPT_MODE:-disabled}"

echo "Creating autoissued certificates for HTTP host..."

# Generate a new self-signed certificate if missing or older than one year.
if [ ! -f "/geonode-certificates/autoissued/privkey.pem" ] || \
   find /geonode-certificates/autoissued/privkey.pem -mtime +365 | grep -q .; then
    echo "⏳ Generating new self-signed certificate..."
    mkdir -p "/geonode-certificates/autoissued/"
    openssl req -x509 -nodes -days 1825 -newkey rsa:2048 \
        -keyout "/geonode-certificates/autoissued/privkey.pem" \
        -out "/geonode-certificates/autoissued/fullchain.pem" \
        -subj "/CN=${HTTPS_HOST:-${HTTP_HOST:-localhost}}"
else
    echo "✅ Autoissued certificate already exists."
fi

# ────────────────────────────────────────────────
# 2️⃣  Create Symlink for Active Certificates
# ────────────────────────────────────────────────
echo "Linking certificate directory..."
rm -rf /certificate_symlink || true
mkdir -p /certificate_symlink

# If a Let's Encrypt certificate exists, use it; otherwise fall back to the self-signed cert.
if [ -f "/geonode-certificates/${LETSENCRYPT_MODE}/live/${HTTPS_HOST}/fullchain.pem" ] && \
   [ -f "/geonode-certificates/${LETSENCRYPT_MODE}/live/${HTTPS_HOST}/privkey.pem" ]; then
    echo "🔗 Using Let's Encrypt certificate."
    ln -sf "/geonode-certificates/${LETSENCRYPT_MODE}/live/${HTTPS_HOST}" /certificate_symlink
else
    echo "⚙️ Using autoissued self-signed certificate."
    ln -sf "/geonode-certificates/autoissued" /certificate_symlink
fi

# ────────────────────────────────────────────────
# 3️⃣  Determine HTTP/HTTPS Scheme and Public Host
# ────────────────────────────────────────────────
# By default, GeoNode assumes 80/443. We make this dynamic.

if [ -z "${HTTPS_HOST}" ]; then
    # No HTTPS host defined → HTTP mode
    HTTP_SCHEME="http"
    if [ "${HTTP_PORT:-80}" = "80" ]; then
        PUBLIC_HOST="${HTTP_HOST}"
    else
        PUBLIC_HOST="${HTTP_HOST}:${HTTP_PORT}"
    fi
else
    # HTTPS mode
    HTTP_SCHEME="https"
    if [ "${HTTPS_PORT:-443}" = "443" ]; then
        PUBLIC_HOST="${HTTPS_HOST}"
    else
        PUBLIC_HOST="${HTTPS_HOST}:${HTTPS_PORT}"
    fi
fi

echo "🌐 Public Host set to: ${HTTP_SCHEME}://${PUBLIC_HOST}"

export HTTP_SCHEME=${HTTP_SCHEME:-http}
export PUBLIC_HOST=${PUBLIC_HOST}
export GEONODE_LB_HOST_IP=${GEONODE_LB_HOST_IP:-django}
export GEONODE_LB_PORT=${GEONODE_LB_PORT:-8000}
export GEOSERVER_LB_HOST_IP=${GEOSERVER_LB_HOST_IP:-geoserver}
export GEOSERVER_LB_PORT=${GEOSERVER_LB_PORT:-8080}

defined_envs=$(printf '${%s} ' $(env | cut -d= -f1))

# ────────────────────────────────────────────────
# 4️⃣  Generate NGINX Configs from Templates
# ────────────────────────────────────────────────
echo "🧩 Generating nginx configs from templates..."
envsubst "$defined_envs" < /etc/nginx/nginx.conf.envsubst > /etc/nginx/nginx.conf
envsubst "$defined_envs" < /etc/nginx/nginx.https.available.conf.envsubst > /etc/nginx/nginx.https.available.conf

# Use an alternate template if running on a custom HTTP port.
if [ -n "${HTTP_PORT}" ] && [ "${HTTP_PORT}" != "80" ]; then
    echo "⚙️ Custom HTTP port detected (${HTTP_PORT}), using geonode_diff_port.envsubst"
    envsubst "$defined_envs" < /etc/nginx/sites-enabled/geonode_diff_port.envsubst > /etc/nginx/sites-enabled/geonode.conf
else
    envsubst "$defined_envs" < /etc/nginx/sites-enabled/geonode.conf.envsubst > /etc/nginx/sites-enabled/geonode.conf
fi

# ────────────────────────────────────────────────
# 5️⃣  Enable or Disable HTTPS
# ────────────────────────────────────────────────
echo "🔒 Checking HTTPS configuration..."
if [ -z "${HTTPS_HOST}" ]; then
    echo "❌ HTTPS disabled (no HTTPS_HOST defined)."
    echo "" > /etc/nginx/nginx.https.enabled.conf
else
    echo "✅ HTTPS enabled for ${HTTPS_HOST}"
    ln -sf /etc/nginx/nginx.https.available.conf /etc/nginx/nginx.https.enabled.conf
fi

# ────────────────────────────────────────────────
# 6️⃣  Launch Auto-Reload Watcher
# ────────────────────────────────────────────────
echo "🚀 Starting nginx autoreloader..."
sh /docker-autoreload.sh &

echo "-----------------------------------------------------"
echo "FINISHED NGINX ENTRYPOINT ---------------------------"
echo "-----------------------------------------------------"

# ────────────────────────────────────────────────
# 7️⃣  Start NGINX
# ────────────────────────────────────────────────
exec "$@"