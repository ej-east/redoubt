# syntax=docker/dockerfile:1.24
FROM debian:bookworm-slim AS builder 

ARG SWS_VERSION=2.42.0
ARG SWS_SHA256_ARM64=f269f706042991f50d6478ea7743a4f2c38a23c1de10654208eec6832adebfd3
ARG SWS_SHA256_AMD64=ed32ff29cdcafb37b5cc4efa89147918bc837fbe308a2a6c438c8b9047b71956
ARG TARGETARCH 

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* 

WORKDIR /tmp
RUN set -eux; \
    case "${TARGETARCH}" in \
    amd64) ARCH="x86_64-unknown-linux-musl"; EXPECTED_SHA="${SWS_SHA256_AMD64}" ;; \
    arm64) ARCH="aarch64-unknown-linux-musl"; EXPECTED_SHA="${SWS_SHA256_ARM64}" ;; \
    *) echo "unsupported: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    BASE="https://github.com/static-web-server/static-web-server/releases/download/v${SWS_VERSION}" ; \
    TARBALL="static-web-server-v${SWS_VERSION}-${ARCH}.tar.gz" ; \
    curl -fsSL "${BASE}/${TARBALL}" -o "${TARBALL}"; \
    echo "${EXPECTED_SHA}  ${TARBALL}" | sha256sum -c; \
    tar -xzf "${TARBALL}" --strip-components=1; \
    chmod +x static-web-server

FROM gcr.io/distroless/static-debian13:nonroot
ARG SWS_VERSION

LABEL org.opencontainers.image.title="static-base" \ 
      org.opencontainers.image.source="https://github.com/ej-east/bedrock" \ 
      org.opencontainers.image.version="${SWS_VERSION}"

COPY --from=builder --chown=65532:65532 /tmp/static-web-server /usr/local/bin/static-web-server 

USER 65532:65532
WORKDIR /var/www
EXPOSE 8080

ENV SERVER_HOST=0.0.0.0 \
    SERVER_PORT=8080 \
    SERVER_ROOT="/var/www" \
    SERVER_DIRECTORY_LISTING=false

ENTRYPOINT [ "/usr/local/bin/static-web-server" ]