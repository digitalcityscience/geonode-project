###############################################################################

# 💻 LOCAL DEVELOPMENT CONFIGURATION

# Direct access from http://localhost:8085 without external proxy

###############################################################################

COMPOSE_PROJECT_NAME=dcs_geonode
DOCKER_ENV=development
DOCKER_API_VERSION=1.24
BACKUPS_VOLUME_DRIVER=local

# Docker image versions

GEONODE_BASE_IMAGE_VERSION=4.4.x
NGINX_BASE_IMAGE_VERSION=1.28.0-v1
LETSENCRYPT_BASE_IMAGE_VERSION=2.6.0-latest
GEOSERVER_BASE_IMAGE_VERSION=2.27.x-latest
GEOSERVER_DATA_BASE_IMAGE_VERSION=2.27.2-latest
POSTGRES_BASE_IMAGE_VERSION=15-3.5-latest

C_FORCE_ROOT=1
FORCE_REINIT=false
INVOKE_LOG_STDOUT=true

###############################################################################

# 🌐 NETWORK & ACCESS

###############################################################################

# Internal Nginx base address (no trailing slash!)

NGINX_BASE_URL=http://localhost:8085

# Public-facing site URL shown in browser (always end with /)

SITEURL=${NGINX_BASE_URL}/

# Host and ports

HTTP_HOST=localhost
HTTPS_HOST=
HTTP_PORT=8085
HTTPS_PORT=8444

# Optional external access for GeoServer & Postgres

GEOSERVER_MACHINE_PORT=8080
POSTGRES_MACHINE_PORT=55432

# Docker internal service routing

GEONODE_LB_HOST_IP=django
GEONODE_LB_PORT=8000
GEOSERVER_LB_HOST_IP=geoserver
GEOSERVER_LB_PORT=8080

# Docker DNS resolver

RESOLVER=127.0.0.11

###############################################################################

# 🔒 HTTPS / CERTIFICATES

###############################################################################

# Local dev → disabled. Can be 'staging' or 'production' for real certs.

LETSENCRYPT_MODE=disabled

# LETSENCRYPT_MODE=staging

# LETSENCRYPT_MODE=production

###############################################################################

# 🗃️ DATABASE

###############################################################################
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
GEONODE_DATABASE=dcs_geonode
GEONODE_DATABASE_USER=dcs_geonode
GEONODE_DATABASE_PASSWORD=postgres
GEONODE_GEODATABASE=dcs_geonode_data
GEONODE_GEODATABASE_USER=dcs_geonode_data
GEONODE_GEODATABASE_PASSWORD=postgres
GEONODE_DATABASE_SCHEMA=public
GEONODE_GEODATABASE_SCHEMA=public
DATABASE_HOST=db
DATABASE_PORT=5432
DATABASE_URL=postgis://${GEONODE_DATABASE_USER}:${GEONODE_DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${GEONODE_DATABASE}
GEODATABASE_URL=postgis://${GEONODE_GEODATABASE_USER}:${GEONODE_GEODATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${GEONODE_GEODATABASE}
POSTGRESQL_MAX_CONNECTIONS=200
GEONODE_DB_CONN_MAX_AGE=0
GEONODE_DB_CONN_TOUT=5
DEFAULT_BACKEND_DATASTORE=datastore

###############################################################################

# 🛰️ GEOSERVER

###############################################################################
GEOSERVER_WEB_UI_LOCATION=${SITEURL}geoserver/
GEOSERVER_PUBLIC_LOCATION=${SITEURL}geoserver/
GEOSERVER_LOCATION=http://${GEOSERVER_LB_HOST_IP}:${GEOSERVER_LB_PORT}/geoserver/
GEOSERVER_ADMIN_USER=admin
GEOSERVER_ADMIN_PASSWORD=geoserver
OGC_REQUEST_TIMEOUT=30
OGC_REQUEST_MAX_RETRIES=1
OGC_REQUEST_BACKOFF_FACTOR=0.3
OGC_REQUEST_POOL_MAXSIZE=10
OGC_REQUEST_POOL_CONNECTIONS=10
ENABLE_JSONP=true
outFormat=text/javascript
GEOSERVER_JAVA_OPTS=-Djava.awt.headless=true -Xms4G -Xmx4G -Dgwc.context.suffix=gwc -XX:+UnlockDiagnosticVMOptions -XX:+LogVMOutput -XX:LogFile=/var/log/jvm.log -XX:PerfDataSamplingInterval=500 -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:-UseGCOverheadLimit -XX:ParallelGCThreads=4 -Dfile.encoding=UTF8 -Djavax.servlet.request.encoding=UTF-8 -Djavax.servlet.response.encoding=UTF-8 -Duser.timezone=GMT -Dorg.geotools.shapefile.datetime=false -DGS-SHAPEFILE-CHARSET=UTF-8 -DGEOSERVER_CSRF_DISABLED=true -DPRINT_BASE_URL=http://localhost/geoserver/pdf -DALLOW_ENV_PARAMETRIZATION=true -Xbootclasspath/a:/usr/local/tomcat/webapps/geoserver/WEB-INF/lib/marlin-0.9.3-Unsafe.jar -Dsun.java2d.renderer=org.marlin.pisces.MarlinRenderingEngine

###############################################################################

# ⚙️ DJANGO / GEONODE CORE

###############################################################################
DJANGO_SETTINGS_MODULE=dcs_geonode.settings
GEONODE_INSTANCE_NAME=dcs_geonode
ADMIN_USERNAME=admin
ADMIN_PASSWORD=geonode_password
ADMIN_EMAIL=admin@localhost.local
ALLOWED_HOSTS="['localhost','127.0.0.1','django']"
DEBUG=True
SECRET_KEY='CHANGE_ME_IN_DEV'

###############################################################################

# ⚙️ ASYNC / CELERY

###############################################################################
BROKER_URL=amqp://guest:guest@rabbitmq:5672/
CELERY_BEAT_SCHEDULER=celery.beat:PersistentScheduler
ASYNC_SIGNALS=True

###############################################################################

# 📧 EMAIL SETTINGS

###############################################################################
EMAIL_ENABLE=False
DJANGO_EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
DJANGO_EMAIL_HOST=localhost
DJANGO_EMAIL_PORT=25
DJANGO_EMAIL_HOST_USER=
DJANGO_EMAIL_HOST_PASSWORD=
DJANGO_EMAIL_USE_TLS=False
DJANGO_EMAIL_USE_SSL=False
DEFAULT_FROM_EMAIL='admin@localhost.local'

###############################################################################

# 🔐 SECURITY

###############################################################################
LOCKDOWN_GEONODE=False
X_FRAME_OPTIONS="SAMEORIGIN"
SESSION_EXPIRED_CONTROL_ENABLED=True
DEFAULT_ANONYMOUS_VIEW_PERMISSION=True
DEFAULT_ANONYMOUS_DOWNLOAD_PERMISSION=True
CORS_ALLOW_ALL_ORIGINS=True
GEOSERVER_CORS_ENABLED=True
GEOSERVER_CORS_ALLOWED_ORIGINS=_
GEOSERVER_CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,HEAD,OPTIONS
GEOSERVER_CORS_ALLOWED_HEADERS=_

###############################################################################

# 👥 USERS / AUTH

###############################################################################
ACCOUNT_OPEN_SIGNUP=True
ACCOUNT_EMAIL_REQUIRED=True
ACCOUNT_APPROVAL_REQUIRED=False
ACCOUNT_CONFIRM_EMAIL_ON_GET=False
ACCOUNT_EMAIL_VERIFICATION=none
ACCOUNT_EMAIL_CONFIRMATION_EMAIL=False
ACCOUNT_EMAIL_CONFIRMATION_REQUIRED=False
ACCOUNT_AUTHENTICATION_METHOD=username_email
AUTO_ASSIGN_REGISTERED_MEMBERS_TO_REGISTERED_MEMBERS_GROUP_NAME=True
OAUTH2_API_KEY=
OAUTH2_CLIENT_ID=dcs_client_id
OAUTH2_CLIENT_SECRET=dcs_client_secret

###############################################################################

# 🧭 API / SEARCH / MONITORING

###############################################################################
API_LOCKDOWN=False
TASTYPIE_APIKEY=
HAYSTACK_SEARCH=False
HAYSTACK_ENGINE_URL=http://elasticsearch:9200/
HAYSTACK_ENGINE_INDEX_NAME=haystack
HAYSTACK_SEARCH_RESULTS_PER_PAGE=200
MONITORING_ENABLED=False
MONITORING_DATA_TTL=365
USER_ANALYTICS_ENABLED=True
USER_ANALYTICS_GZIP=True
CENTRALIZED_DASHBOARD_ENABLED=False
MONITORING_SERVICE_NAME=dcs-geonode-local
MONITORING_HOST_NAME=dcs-geonode

###############################################################################

# 🧱 CACHE / PERFORMANCE

###############################################################################
CACHE_BUSTING_STATIC_ENABLED=False
MEMCACHED_ENABLED=False
MEMCACHED_BACKEND=django.core.cache.backends.memcached.MemcachedCache
MEMCACHED_LOCATION=memcached:11211
MEMCACHED_LOCK_EXPIRE=3600
MEMCACHED_LOCK_TIMEOUT=10
MEMCACHED_OPTIONS=

###############################################################################

# 🖼️ FRONTEND CLIENT

###############################################################################
GEONODE_CLIENT_LAYER_PREVIEW_LIBRARY=mapstore
MAPBOX_ACCESS_TOKEN=
BING_API_KEY=
GOOGLE_API_KEY=

###############################################################################

# ⚙️ WORKFLOW / FEATURES

###############################################################################
MODIFY_TOPICCATEGORY=True
AVATAR_GRAVATAR_SSL=True
EXIF_ENABLED=True
CREATE_LAYER=True
FAVORITE_ENABLED=True
RESOURCE_PUBLISHING=False
ADMIN_MODERATE_UPLOADS=False

###############################################################################

# 🧬 LDAP (disabled)

###############################################################################
LDAP_ENABLED=False
LDAP_SERVER_URL=ldap://<the_ldap_server>
LDAP_BIND_DN=uid=ldapinfo,cn=users,dc=ad,dc=example,dc=org
LDAP_BIND_PASSWORD=<something_secret>
LDAP_USER_SEARCH_DN=dc=ad,dc=example,dc=org
LDAP_USER_SEARCH_FILTERSTR=(&(uid=%(user)s)(objectClass=person))
LDAP_GROUP_SEARCH_DN=cn=groups,dc=ad,dc=example,dc=org
LDAP_GROUP_SEARCH_FILTERSTR=(|(cn=abt1)(cn=abt2))
LDAP_GROUP_PROFILE_MEMBER_ATTR=uniqueMember

###############################################################################

# ⚙️ RESTART POLICY

###############################################################################
RESTART_POLICY_CONDITION="on-failure"
RESTART_POLICY_DELAY="5s"
RESTART_POLICY_MAX_ATTEMPTS="3"
RESTART_POLICY_WINDOW=120s

###############################################################################

# 📦 UPLOADS / LIMITS

###############################################################################
MAX_DOCUMENT_SIZE=200
CLIENT_RESULTS_LIMIT=5
API_LIMIT_PER_PAGE=1000
DEFAULT_MAX_UPLOAD_SIZE=5368709120
DEFAULT_MAX_PARALLEL_UPLOADS_PER_USER=5
