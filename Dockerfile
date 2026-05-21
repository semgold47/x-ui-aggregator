FROM openresty/openresty:alpine-fat

ARG SITE_PORT=443
ARG SERVERS

ENV SITE_HOST=localhost
ENV SITE_PORT=${SITE_PORT}
ENV SERVERS=${SERVERS}
ENV SUB=sub
ENV TLS_MODE=off

EXPOSE ${SITE_PORT}/tcp

RUN rm /usr/local/openresty/nginx/conf/nginx.conf

COPY nginx.conf.esh /usr/local/openresty/nginx/conf/
COPY config_fetcher.lua /etc/nginx/lua/

RUN apk upgrade && apk add --no-cache esh \
    && luarocks install lua-resty-http

RUN chmod -R 755 /usr/local/openresty/nginx/conf/

CMD ["/bin/sh", "-c", "esh -o /usr/local/openresty/nginx/conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf.esh && exec nginx -g 'daemon off;'"]