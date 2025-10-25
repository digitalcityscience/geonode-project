###############################################################################

# 🌍 HH DEV DEPLOYMENT (behind external proxy at /geonode)

###############################################################################

COMPOSE_PROJECT_NAME=dcs_geonode
DOCKER_ENV=production
DOCKER_API_VERSION=1.24

# Docker image versions

GEONODE_BASE_IMAGE_VERSION=4.3.x
NGINX_BASE_IMAGE_VERSION=1.25.3-latest
LETSENCRYPT_BASE_IMAGE_VERSION=2.6.0-latest
GEOSERVER_BASE_IMAGE_VERSION=2.24.4-v1
GEOSERVER_DATA_BASE_IMAGE_VERSION=2.24.4-v1
POSTGRES_BASE_IMAGE_VERSION=15.3-latest

###############################################################################

# 🌐 NETWORK & ACCESS

###############################################################################

# Internal Nginx base URL (no trailing slash)

NGINX_BASE_URL=https://hh.hcu-hamburg.de

# Public-facing site URL (as seen by users, always end with /)

SITEURL={NGINX_BASE_URL}/

# Host & port mapping between server and containers

HTTP_HOST=hh.hcu-hamburg.de
HTTPS_HOST=hh.hcu-hamburg.de
HTTP_PORT=8787
HTTPS_PORT=8443

# Optional external access for GeoServer & Postgres

GEOSERVER_MACHINE_PORT=8080
POSTGRES_MACHINE_PORT=55432

# Docker internal routing

GEONODE_LB_HOST_IP=django
GEONODE_LB_PORT=8000
GEOSERVER_LB_HOST_IP=geoserver
GEOSERVER_LB_PORT=8080

RESOLVER=127.0.0.11

###############################################################################

# 🔒 HTTPS / CERTIFICATES

###############################################################################

# External reverse proxy handles HTTPS, so disabled inside Docker

LETSENCRYPT_MODE=disabled

# If you decide to serve HTTPS directly from this stack:

# LETSENCRYPT_MODE=production

# HTTPS_HOST=hh.hcu-hamburg.de

###############################################################################

# 🗃️ DATABASE

###############################################################################
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

GEONODE_DATABASE=geonode
GEONODE_DATABASE_USER=geonode
GEONODE_DATABASE_PASSWORD=postgres

GEONODE_GEODATABASE=geonode_data
GEONODE_GEODATABASE_USER=geonode_data
GEONODE_GEODATABASE_PASSWORD=postgres

DATABASE_HOST=db
DATABASE_PORT=5432

DATABASE_URL=postgis://${GEONODE_DATABASE_USER}:${GEONODE_DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${GEONODE_DATABASE}
GEODATABASE_URL=postgis://${GEONODE_GEODATABASE_USER}:${GEONODE_GEODATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${GEONODE_GEODATABASE}

###############################################################################

# 🛰️ GEOSERVER

###############################################################################
GEOSERVER_WEB_UI_LOCATION=${SITEURL}geoserver/
GEOSERVER_PUBLIC_LOCATION=${SITEURL}geoserver/
GEOSERVER_LOCATION=http://${GEOSERVER_LB_HOST_IP}:${GEOSERVER_LB_PORT}/geoserver/
GEOSERVER_ADMIN_USER=admin
GEOSERVER_ADMIN_PASSWORD=geoserver

###############################################################################

# ⚙️ DJANGO / GEONODE CORE

###############################################################################
DJANGO_SETTINGS_MODULE=dcs_geonode.settings
GEONODE_INSTANCE_NAME=dcs_geonode
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin
ADMIN_EMAIL=admin@hh.hcu-hamburg.de
ALLOWED_HOSTS="['django','localhost','hh.hcu-hamburg.de']"
DEBUG=False
SECRET_KEY='CHANGE_ME_SECURELY'

###############################################################################

# 📦 PATHS

###############################################################################
STATIC_ROOT=/mnt/volumes/statics/static/
MEDIA_ROOT=/mnt/volumes/statics/uploaded/
GEOIP_PATH=/mnt/volumes/statics/geoip.db
