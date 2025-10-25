#!/bin/sh
set -e

echo ""
echo "-----------------------------------------------------"
echo "STARTING NGINX ENTRYPOINT ---------------------------"
date

# ────────────────────────────────────────────────
# 1. Certificates Setup
# ────────────────────────────────────────────────
mkdir -p "/geonode-certificates/$LETSENCRYPT_MODE"

echo "Creating autoissued certificates for HTTP host"
if [ ! -f "/geonode-certificates/autoissued/privkey.pem" ] || \
   find /geonode-certificates/autoissued/privkey.pem -mtime +365 | grep -q .; then
    echo "Autoissued certificate does not exist or is too old, generating new one..."
    mkdir -p "/geonode-certificates/autoissued/"
    openssl req -x509 -nodes -days 1825 -newkey rsa:2048 \
        -keyout "/geonode-certificates/autoissued/privkey.pem" \
        -out "/geonode-certificates/autoissued/fullchain.pem" \
        -subj "/CN=${HTTP_HOST:-$HTTPS_HOST}"
else
    echo "Autoissued certificate already exists."
fi

# ────────────────────────────────────────────────
# 2. Symlink for Certificates
# ────────────────────────────────────────────────
echo "Creating symbolic link for HTTPS certificate"
rm -rf /certificate_symlink
mkdir -p /certificate_symlink

if [ -f "/geonode-certificates/$LETSENCRYPT_MODE/live/$HTTPS_HOST/fullchain.pem" ] && \
   [ -f "/geonode-certificates/$LETSENCRYPT_MODE/live/$HTTPS_HOST/privkey.pem" ]; then
    echo "Certbot certificate exists, linking to live cert."
    ln -sf "/geonode-certificates/$LETSENCRYPT_MODE/live/$HTTPS_HOST" /certificate_symlink
else
    echo "Certbot certificate missing, linking to autoissued cert."
    ln -sf "/geonode-certificates/autoissued" /certificate_symlink
fi

# ────────────────────────────────────────────────
# 3. Environment Defaults
# ────────────────────────────────────────────────
if [ -z "$HTTPS_HOST" ]; then
    HTTP_SCHEME="http"
else
    HTTP_SCHEME="https"
fi

export HTTP_SCHEME=${HTTP_SCHEME:-http}
export GEONODE_LB_HOST_IP=${GEONODE_LB_HOST_IP:-django}
export GEONODE_LB_PORT=${GEONODE_LB_PORT:-8000}
export GEOSERVER_LB_HOST_IP=${GEOSERVER_LB_HOST_IP:-geoserver}
export GEOSERVER_LB_PORT=${GEOSERVER_LB_PORT:-8080}

defined_envs=$(printf '${%s} ' $(env | cut -d= -f1))

# ────────────────────────────────────────────────
# 4. Generate NGINX Configs
# ────────────────────────────────────────────────
echo "Replacing environment variables with envsubst..."
envsubst "$defined_envs" < /etc/nginx/nginx.conf.envsubst > /etc/nginx/nginx.conf
envsubst "$defined_envs" < /etc/nginx/nginx.https.available.conf.envsubst > /etc/nginx/nginx.https.available.conf

# HTTP port-specific configuration
if [ -n "$HTTP_PORT" ] && [ "$HTTP_PORT" -ne 80 ]; then
    echo "Custom HTTP port ($HTTP_PORT) detected, using geonode_diff_port.envsubst"
    envsubst "$defined_envs" < /etc/nginx/sites-enabled/geonode_diff_port.envsubst > /etc/nginx/sites-enabled/geonode.conf
else
    envsubst "$defined_envs" < /etc/nginx/sites-enabled/geonode.conf.envsubst > /etc/nginx/sites-enabled/geonode.conf
fi

# ────────────────────────────────────────────────
# 5. HTTPS Enable / Disable
# ────────────────────────────────────────────────
echo "Enabling or disabling HTTPS configuration..."
if [ -z "$HTTPS_HOST" ]; then
    echo "" > /etc/nginx/nginx.https.enabled.conf
else
    ln -sf /etc/nginx/nginx.https.available.conf /etc/nginx/nginx.https.enabled.conf
fi

# ────────────────────────────────────────────────
# 6. Auto-reload background watcher
# ────────────────────────────────────────────────
echo "Starting nginx autoreloader..."
sh /docker-autoreload.sh &

echo "-----------------------------------------------------"
echo "FINISHED NGINX ENTRYPOINT ---------------------------"
echo "-----------------------------------------------------"

# ────────────────────────────────────────────────
# 7. Start NGINX
# ────────────────────────────────────────────────
exec "$@"