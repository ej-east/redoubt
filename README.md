# redoubt

`redoubt` is a collection of hardened, reproducible container images and reusable CI workflows for building, scanning, signing, and attestation. `redoubt` makes it easy for downstream services to ship on a known secure foundation without re-inventing the supply-chain wheel.

## Overview

Every image in this repository goes through the same pipeline:

![Pipeline Diagram](diagrams/redoubt-diagram.png)

1. **Build** - [Buildx](https://github.com/docker/buildx) builds multi-architecture images (`linux/amd64`, `linux/arm64`) on a minimal base ([distroless](https://github.com/GoogleContainerTools/distroless) for general images, UBI Micro for FIPS images).
2. **Scan** - [Trivy](https://github.com/aquasecurity/trivy) performs a security scan. It gates on HIGH/CRITICAL CVEs and uploads a [SARIF](https://sarifweb.azurewebsites.net/) to GitHub code scanning
3. **Sign** - [Cosign](https://github.com/sigstore/cosign) keylessly signs images using the workflow's OIDC identity. The signatures are logged to [Rekor](https://docs.sigstore.dev/logging/overview/).
4. **Attest** - [Syft](https://github.com/anchore/syft) generates an SBOM which is subsequently attached to the image as a cosign attestation.

Images are published to GHCR at `ghcr.io/ej-east/<image-name>`. The build pipeline also exposes a reusable workflow at `.github/workflows/build-redoubt-image.yaml` that downstream repos call with `uses:`.

## Quick Start 

### Pull and run

Pull `main` branch image:

```sh
docker run --rm -p 8080:8080 \
  -v "$PWD:/var/www:ro" \
  ghcr.io/ej-east/static-base:main
```

Pin to an immutable digest:

```sh
docker pull ghcr.io/ej-east/static-base@sha256:<digest>
```

### Use a baseline image 

Use the static webserver base image. This runs as nobody(UID 65532) and is distroless. 

```dockerfile
FROM ghcr.io/ej-east/static-base:latest
COPY ./site /var/www
```

### Use the baseline CI

You can add a thin caller in your repo called: `.github/workflows/build-<image-name>.yaml`

```yaml
name: build-<image-name>
on:
  push:
    branches: [main]
    paths:
      - "images/<image-name>/**"
      - ".github/workflows/build-<image-name>.yaml"
    tags:
      - "<image-name>/v*"
  pull_request:
    paths:
      - "images/<image-name>/**"
      - ".github/workflows/build-<image-name>.yaml"
  workflow_dispatch:

jobs:
  build:
    uses: ej-east/redoubt/.github/workflows/build-redoubt-image.yaml@main
    with:
      image-name: <image-name>
    permissions:
      contents: read
      packages: write
      id-token: write
      security-events: write
```

It's recommended to pin to a commit SHA to mitigate possible supply chain attacks.

### Verify a signed image

You need to install [cosign](https://github.com/sigstore/cosign)

```bash
cosign verify ghcr.io/ej-east/static-base:latest \
  --certificate-identity-regexp 'https://github.com/ej-east/redoubt/\.github/workflows/build-redoubt-image\.yaml@.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

Verify/Download SBOM attestation:

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp 'https://github.com/ej-east/redoubt/\.github/workflows/build-redoubt-image\.yaml@.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/ej-east/static-base:latest
```

## Image Catalog

| Image Name                                                | Description                                                                                | Is FIPS? |
|-----------------------------------------------------------|--------------------------------------------------------------------------------------------|----------|
| `ghcr.io/ej-east/static-base`                             | Static webserver image for SPAs and docs sites.                                            | No       |
| `ghcr.io/ej-east/golang` / `ghcr.io/ej-east/golang-build` | This container is designed to build and run golang images within a production environment. | Yes      |


## Design Decisions

### Different base options

Different images use different base options. For example `static-base` uses Google's solution to Distroless while the `golang` image set uses Red Hat's Universal Base Image (UBI). UBI Micro carries FIPS 140-3 validated cryptograph and is the right choice for Federal workloads. 

### Multi-architecture by default 

Every image is built for both `amd64` and `arm64`. Production environments are increasingly using `arm64` devices. It's important to produce production ready images for these machines. 

### SLSA Level

Images currently meet the requirements for **SLSA Build Level 2**. This is achieved through the following: Buildx generates in-toto provenance with `provenance: mode=max`. The resulting attestation is signed by GitHub Actions' OIDC identity, and the build runs on a GitHub-hosted runner. This process satisfies L2's hosted, authenticated, non-falsifiable provenance criteria. 

**SLSA Build Level 3** is on the roadmap. Reaching it means adopting [`slsa-framework/slsa-github-generator`](https://github.com/slsa-framework/slsa-github-generator), instead of the current flow. The driver is that L3 is a FedRAMP requirement for certain workloads.

### OpenSCAP

## License

See [LICENSE.md](LICENSE.md).
