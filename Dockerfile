FROM golang:1.24-bookworm AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y git ca-certificates gcc-aarch64-linux-gnu && rm -rf /var/lib/apt/lists/*
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -o build/linux_amd64/image-api .
RUN CGO_ENABLED=1 GOOS=linux GOARCH=arm64 CC=aarch64-linux-gnu-gcc go build -o build/linux_arm64/image-api .

FROM debian:bookworm-slim
LABEL name="custom-image-gateway-b2"
LABEL version="latest"
LABEL description="Backblaze B2 / S3-compatible image gateway for Obsidian."
LABEL maintainer="lascivea"
LABEL org.opencontainers.image.title="Obsidian Image API Gateway (B2)"
LABEL org.opencontainers.image.authors="lascivea"
LABEL org.opencontainers.image.url="https://github.com/lascivea/custom-image-gateway-b2"
LABEL org.opencontainers.image.source="https://github.com/lascivea/custom-image-gateway-b2"
LABEL org.opencontainers.image.licenses="Apache-2.0"

ENV TZ=Asia/Shanghai
ENV P_NAME=api
ENV P_BIN=image-api
RUN apt-get update && apt-get install -y ca-certificates tzdata curl bash && \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 9000 9001
RUN mkdir -p /${P_NAME}/
VOLUME /${P_NAME}/config
VOLUME /${P_NAME}/storage
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ARG TARGETOS
ARG TARGETARCH
COPY --from=builder /app/build/${TARGETOS}_${TARGETARCH}/${P_BIN} /${P_NAME}/
ENTRYPOINT ["/entrypoint.sh"]
