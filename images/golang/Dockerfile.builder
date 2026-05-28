# syntax=docker/dockerfile:1.24@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:24650313873554b6ba16c1a1b6b9f9142604f6ab735113e1695faf2dd07fdede AS builder

ARG TARGETARCH
ENV GOFIPS140=v1.0.0 \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=${TARGETARCH}

RUN microdnf update -y \
 && microdnf install -y --nodocs golang \
 && go version \
 && microdnf clean all \
 && rm -rf /var/cache/yum /var/cache/dnf

LABEL org.opencontainers.image.base.name="registry.access.redhat.com/ubi9/ubi-minimal" \
      org.opencontainers.image.description="UBI9-minimal Go toolchain for FIPS 140-3 builds (GOFIPS140=v1.0.0, CGO_ENABLED=0)"
