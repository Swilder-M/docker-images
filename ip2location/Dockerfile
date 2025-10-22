# 构建阶段
FROM golang:1.24-alpine AS builder

# 设置工作目录
WORKDIR /build

# 复制 go.mod 和 go.sum
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY *.go ./

# 编译（静态链接，压缩）
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -a -installsuffix cgo -ldflags="-s -w -extldflags '-static'" -o ip2location-server .

# 运行阶段 - 使用 scratch 最小化镜像
FROM scratch

# 从构建阶段复制 CA 证书
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# 从构建阶段复制二进制文件
COPY --from=builder /build/ip2location-server /ip2location-server

# 暴露端口（通过环境变量 PORT 配置，默认 5000）
EXPOSE 5000

# 运行
ENTRYPOINT ["/ip2location-server"]