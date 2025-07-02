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
    git \
    wget

ARG NGINX_VERSION=1.28.0
ARG RTMP_MODULE_VERSION=master

RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz

RUN git clone https://github.com/arut/nginx-rtmp-module.git --depth=1

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
    --add-module=/opt/nginx-rtmp-module \
    --with-cc-opt='-Os -fomit-frame-pointer -ffunction-sections -fdata-sections -static' \
    --with-ld-opt='-static -Wl,--gc-sections' \
    --user=nginx \
    --group=nginx

RUN make -j$(nproc) && make install && \
    strip -s /usr/local/nginx/sbin/nginx

# Create minimal mime.types file with only essential types
RUN awk 'BEGIN{p=0} /^types/,/^}/{p=1} p' /opt/nginx-*/conf/mime.types | grep -v "#" > /tmp/minimal_mime.types

# Create directories required for nginx
RUN mkdir -p /var/cache/nginx/client_temp \
             /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp \
             /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp \
             /var/www/localhost/htdocs

# Copy stat.xsl for RTMP stats
RUN cp /opt/nginx-rtmp-module/stat.xsl /var/www/localhost/htdocs/stat.xsl

FROM scratch

# Copy files from builder
COPY --from=builder /usr/local/nginx/sbin/nginx /usr/sbin/nginx
COPY --from=builder /var/www/localhost/htdocs/stat.xsl /var/www/localhost/htdocs/stat.xsl
COPY --from=builder /tmp/minimal_mime.types /etc/nginx/mime.types
COPY --from=builder /var/cache /var/cache
COPY --from=builder /var/www /var/www
COPY --from=builder /tmp /tmp

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80 1935

CMD ["/usr/sbin/nginx"]
