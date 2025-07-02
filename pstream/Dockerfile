FROM alpine:3.22.0 AS builder

WORKDIR /opt

RUN apk add --no-cache \
    build-base \
    linux-headers \
    openssl-dev \
    openssl-libs-static \
    zlib-dev \
    zlib-static \
    pcre-dev \
    pcre-static \
    pcre2-dev \
    wget

ARG NGINX_VERSION=1.20.0
ARG NGINX_RTMP_MODULE_VERSION=1.2.2

RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz && \
    rm nginx-${NGINX_VERSION}.tar.gz

RUN wget https://github.com/arut/nginx-rtmp-module/archive/refs/tags/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    tar zxf v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    rm v${NGINX_RTMP_MODULE_VERSION}.tar.gz

WORKDIR /opt/nginx-${NGINX_VERSION}
RUN ./configure \
    --prefix=/usr/local/nginx \
    --sbin-path=/usr/local/nginx/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/dev/stdout \
    --http-log-path=/dev/stdout \
    --pid-path=/tmp/nginx.pid \
    --lock-path=/tmp/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-http_ssl_module \
    --with-threads \
    --add-module=/opt/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} \
    --with-cc-opt='-Os -fomit-frame-pointer -static' \
    --with-ld-opt='-static'

RUN make -j$(nproc) && make install && \
    strip /usr/local/nginx/sbin/nginx

FROM alpine:3.22.0

# RUN addgroup -S nginx && \
#     adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

RUN mkdir -p /var/cache/nginx/client_temp \
             /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp \
             /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp \
             /var/www/localhost/htdocs

COPY --from=builder /usr/local/nginx/sbin/nginx /usr/local/nginx/sbin/nginx
COPY --from=builder /opt/nginx-*/conf/mime.types /etc/nginx/mime.types
COPY stat.xsl /var/www/localhost/htdocs/stat.xsl
COPY nginx.conf /etc/nginx/nginx.conf

RUN ln -sf /usr/local/nginx/sbin/nginx /usr/sbin/nginx

EXPOSE 80 1935

CMD ["nginx"]
