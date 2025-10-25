ARG NGINX_VERSION=1.28.0
FROM nginx:${NGINX_VERSION}-alpine

RUN apk add --no-cache openssl inotify-tools vim

WORKDIR /etc/nginx/

RUN mkdir -p /etc/nginx/html &&\
    touch /etc/nginx/html/index.html

ADD geonode_diff_port.envsubst /etc/nginx/sites-enabled/
ADD geonode.conf.envsubst /etc/nginx/sites-enabled/
ADD nginx.conf.envsubst /etc/nginx/
ADD nginx.https.available.conf.envsubst /etc/nginx/

ADD docker-autoreload.sh docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
RUN chmod +x /docker-autoreload.sh
RUN chmod +x /docker-entrypoint.sh

CMD ["nginx", "-g", "daemon off;"]
