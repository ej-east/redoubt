# bedrock

`bedrock` is a collection of hardened, reproducible container images and reusable CI workflows for building, scanning, signing, and attestation. `bedrock` makes it easy for downstream services to ship on a known secure foundation without re-inventing the supply-chain wheel.

## Overview

Every image in this repository goes through the same pipeline:

[Pipeline Diagram](diagrams/bedrock-diagram.png)

1. **Build** - [Buildx](https://github.com/docker/buildx) builds multi-architecture images (`linux/amd64`, `linux/arm64`) on a [distroless](https://github.com/GoogleContainerTools/distroless) base.
2. **Scan** - [Trivy](https://github.com/aquasecurity/trivy) performs a security scan. It gates on HIGH/CRITICAL CVEs and uploads a [SARIF](https://sarifweb.azurewebsites.net/) to GitHub code scanning
3. **Sign** - [Cosign](https://github.com/sigstore/cosign) keylessly signs images using the workflow's OIDC identity. The signatures are logged to [Rekor](https://docs.sigstore.dev/logging/overview/).
4. **Attest** - [Syft](https://github.com/anchore/syft) generates an SBOM which is subsequently attached to the image as a cosign attestation.

Images are published to GHCR at `ghcr.io/ej-east/<image-name>`. The same pipeline is available as a drop-in workflow template under [`templates/`](templates/) for downstream repos.

## License

See [LICENSE.md](LICENSE.md).
