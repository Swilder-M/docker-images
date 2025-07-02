FROM alpine:3.22.0 AS builder

# 设置工作目录
WORKDIR /opt

# 安装构建依赖
RUN apk add --no-cache \
    build-base \
    linux-headers \
    openssl-dev \
    openssl-libs-static \
    zlib-dev \
    zlib-static \
    git \
    wget

# 定义版本
ARG NGINX_VERSION=1.28.0
ARG RTMP_MODULE_VERSION=master

# 下载 nginx 源码
RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz

# 克隆 nginx-rtmp-module
RUN git clone https://github.com/arut/nginx-rtmp-module.git --depth=1

# 编译 nginx（只包含必要模块）
WORKDIR /opt/nginx-${NGINX_VERSION}
RUN ./configure \
    --prefix=/usr/local/nginx \
    --sbin-path=/usr/local/nginx/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/dev/stdout \
    --http-log-path=/dev/stdout \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-http_ssl_module \
    --add-module=/opt/nginx-rtmp-module \
    --with-cc-opt='-Os -fomit-frame-pointer -static' \
    --with-ld-opt='-static' \
    --user=nginx \
    --group=nginx

RUN make -j$(nproc) && make install && \
    strip /usr/local/nginx/sbin/nginx

# 运行时镜像
FROM alpine:3.22.0

# 创建nginx用户（静态编译的nginx无需运行时依赖）
RUN addgroup -S nginx && \
    adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

# 创建必要的目录
RUN mkdir -p /var/cache/nginx/client_temp \
             /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp \
             /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp \
             /var/www/localhost/htdocs && \
    chown -R nginx:nginx /var/cache/nginx /var/www/localhost/htdocs

# 从构建镜像复制nginx二进制文件、配置和资源文件
COPY --from=builder /usr/local/nginx/sbin/nginx /usr/local/nginx/sbin/nginx
COPY --from=builder /opt/nginx-rtmp-module/stat.xsl /var/www/localhost/htdocs/stat.xsl
COPY --from=builder /opt/nginx-*/conf/mime.types /etc/nginx/mime.types

# 创建符号链接
RUN ln -sf /usr/local/nginx/sbin/nginx /usr/sbin/nginx

# 复制配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 测试nginx配置
RUN nginx -t

# 暴露端口
EXPOSE 80 1935

# 设置用户
USER nginx

# 启动命令
CMD ["nginx", "-g", "daemon off;"]
