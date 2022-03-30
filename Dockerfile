FROM golang:latest AS builder

LABEL org.opencontainers.image.source https://github.com/layfolk007/derper

WORKDIR /app

# ========= CONFIG =========
# - download links
ENV MODIFIED_DERPER_GIT=https://github.com/tailscale/tailscale
ENV BRANCH=main
# ==========================

# build modified derper
RUN git clone -b $BRANCH $MODIFIED_DERPER_GIT tailscale --depth 1 && \
    cd /app/tailscale/cmd/derper && \
    /usr/local/go/bin/go build -ldflags "-s -w" -o /app/derper && \
    cd /app && \
    rm -rf /app/tailscale

FROM ubuntu:20.04
WORKDIR /app

# ========= CONFIG =========
# - derper args
ENV DERP_DOMAIN=your-hostname.com
ENV DERP_CERT_MODE=letsencrypt
ENV DERP_CERT_DIR=/app/certs
ENV DERP_ADDR=:443
ENV DERP_STUN=true
ENV DERP_HTTP_PORT=80
ENV DERP_VERIFY_CLIENTS=false
# ==========================

# apt
RUN apt-get update && \
    apt-get install -y openssl curl

COPY build_cert.sh /app/
COPY --from=builder /app/derper /app/derper

# start derper
CMD /app/derper --hostname=$DERP_DOMAIN --certmode=$DERP_CERT_MODE \
    --certdir=$DERP_CERT_DIR --a=$DERP_ADDR --stun=$DERP_STUN \
    --http-port=$DERP_HTTP_PORT --verify-clients=$DERP_VERIFY_CLIENTS
