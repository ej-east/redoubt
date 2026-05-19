# syntax=docker/dockerfile:1.24
FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:12db9874bd753eb98b1ab3d840e75de5d6842ac0604fbd68c012adefe97140be AS builder

ARG TARGETARCH
ENV GOFIPS140=v1.0.0 \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=${TARGETARCH}

RUN microdnf install -y --nodocs \
    golang \
 && go version \
 && microdnf clean all \
 && rm -rf /var/cache/yum /var/cache/dnf

LABEL org.opencontainers.image.title="golang-build" \
      org.opencontainers.image.source="https://github.com/ej-east/bedrock" \
      org.opencontainers.image.base.name="registry.access.redhat.com/ubi9/ubi-minimal" \
      org.opencontainers.image.description="UBI9-minimal Go toolchain for FIPS 140-3 builds (GOFIPS140=v1.0.0, CGO_ENABLED=0)"
