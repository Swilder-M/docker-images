ARG ALPINE_VERSION=3.14

### Builder stage ###
FROM alpine:${ALPINE_VERSION} AS builder

ARG NGINX_VERSION=1.21.1
ARG NGINX_RTMP_MODULE_VERSION=1.2.2

RUN apk update && \
    apk --no-cache add \
        bash \
        build-base \
        ca-certificates \
        openssl \
        openssl-dev \
        make \
        gcc \
        libgcc \
        libc-dev \
        rtmpdump-dev \
        zlib-dev \
        musl-dev \
        pcre \
        pcre-dev \
        lame-dev \
        yasm \
        pkgconf \
        pkgconfig \
        libtheora-dev \
        libvorbis-dev \
        libvpx-dev \
        freetype-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz && \
    rm nginx-${NGINX_VERSION}.tar.gz

RUN cd /tmp/build && \
    wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    tar zxf v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    rm v${NGINX_RTMP_MODULE_VERSION}.tar.gz

RUN cd /tmp/build/nginx-${NGINX_VERSION} && \
    ./configure \
        --sbin-path=/usr/local/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --http-client-body-temp-path=/tmp/nginx-client-body \
        --with-http_ssl_module \
        --with-threads \
        --add-module=/tmp/build/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} && \
    make CFLAGS=-Wno-error -j $(getconf _NPROCESSORS_ONLN) && \
    make install

COPY stat.xsl /usr/local/nginx/html/stat.xsl

### Runtime stage ###
FROM alpine:${ALPINE_VERSION}

RUN apk update && \
    apk --no-cache add pcre && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local /usr/local
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /var/log/nginx /var/log/nginx
COPY --from=builder /var/lock /var/lock
COPY --from=builder /var/run/nginx /var/run/nginx

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 1935
EXPOSE 8080

CMD ["nginx"]
