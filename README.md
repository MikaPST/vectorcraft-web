<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/vectorcraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.vectorcraft.png" width="128" height="128" alt="VectorCraft application icon">
</p>

<h1 align="center">VectorCraft Web — Docker Image</h1>
<p align="center">
  A community-maintained Docker image for
  <a href="https://github.com/storytold/vectorcraft">VectorCraft</a>,
  bringing its Rust and WebAssembly-based vector illustration editor to a self-hosted web interface.
  <br>
  Automated builds and image publication to GitHub Container Registry (GHCR).
</p>
<p align="center">
  <a href="https://github.com/MikaPST/vectorcraft-web/actions/workflows/publish-image.yml"><img src="https://github.com/MikaPST/vectorcraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish VectorCraft Web"></a>
  <a href="https://github.com/MikaPST/vectorcraft-web/releases/latest"><img src="https://img.shields.io/github/v/release/MikaPST/vectorcraft-web?label=Release&logo=github&color=blue" alt="Latest Release"></a>
  <a href="https://github.com/MikaPST/vectorcraft-web/pkgs/container/vectorcraft-web"><img src="https://ghcr-badge.egpl.dev/mikapst/vectorcraft-web/latest_tag?trim=major&label=GHCR" alt="GHCR image tag"></a>
  <a href="docker-compose.yml"><img src="https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white" alt="Docker Compose configuration"></a>
</p>

---

## Why this repository?

The official VectorCraft project provides a browser-based vector illustration editor built with Rust and WebAssembly. This repository packages the official web build into a Docker image served by NGINX for straightforward self-hosting.

The goals are to:

- Build VectorCraft Web from a specific official upstream release.
- Publish a ready-to-run Docker image to GHCR for AMD64 and ARM64.
- Automatically detect and package new official VectorCraft releases.
- Publish a matching GitHub Release **only after the Docker image is successfully pushed**.
- Include the official shared web font resources from [storytold/craft-fonts](https://github.com/storytold/craft-fonts).
- Offer Docker Compose and Unraid Community Applications deployment options.
- Keep the Dockerfile, NGINX configuration, `.dockerignore`, and GitHub Actions workflow version-controlled in this repository.

This is a packaging and distribution project, not a fork intended to develop a separate vector editor.

## How it works

VectorCraft Web runs directly in the browser using WebAssembly. The Docker container serves static assets; it is not a remote desktop or a document-storage backend.

- **Browser-based editor:** create and edit vector artwork using a modern browser.
- **Local file selection:** open files through the browser file picker or supported drag-and-drop actions.
- **Browser downloads:** Save, Save As and Export use browser downloads.
- **GPU rendering:** WebGPU where supported, with WebGL2 fallback; `?webgl` can force WebGL2.
- **Self-hosted:** use the app on your LAN or behind a secure HTTPS reverse proxy.
- **Fonts:** the build includes the external web font assets generated from `craft-fonts`.

WebGPU and clipboard features require a secure context (`https://` or `http://localhost`). Ordinary HTTP network addresses may fall back to WebGL2.

## Docker image

The image is published to GitHub Container Registry:

```text
ghcr.io/mikapst/vectorcraft-web:latest
```

Official upstream releases are published with matching version tags, for example `ghcr.io/mikapst/vectorcraft-web:v0.12.0` when that release has been successfully packaged.

### Option 1 — Docker Compose (recommended)

The root `docker-compose.yml` contains:

```yaml
services:
  vectorcraft-web:
    image: ghcr.io/mikapst/vectorcraft-web:latest
    container_name: vectorcraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

From the repository root, start the application:

```bash
docker compose up -d
```

Open `http://YOUR_SERVER_IP:8080`, or `http://localhost:8080` when Docker runs on your computer.

#### Useful Compose commands

```bash
# View logs
docker compose logs -f

# Update the image
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

No `.env` file or persistent volume is needed for basic use. To change the host port, replace `8080:8080` with, for example, `8081:8080`.

### Option 2 — Run directly with Docker

```bash
docker pull ghcr.io/mikapst/vectorcraft-web:latest

docker run -d \
  --name vectorcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/vectorcraft-web:latest
```

### Network access and reverse proxies

NGINX listens on port `8080`. For remote access, use a reverse proxy such as Traefik to terminate HTTPS. WebGPU needs HTTPS except on localhost. Avoid exposing unprotected HTTP directly to the public Internet.

The NGINX configuration serves `.wasm` as `application/wasm`, `.ttf` as `font/ttf`, compresses supported content, caches hashed application assets and web fonts, and prevents stale `index.html` caching. A `/healthz` endpoint is available for container health checks.

## Repository structure

```text
vectorcraft-web/
├── .github/
│   └── workflows/
│       └── publish-image.yml
├── .dockerignore
├── Dockerfile
├── nginx.conf
├── docker-compose.yml
└── README.md
```

| File | Purpose |
|---|---|
| `Dockerfile` | Defines the lightweight, non-root NGINX runtime image. |
| `nginx.conf` | Configures WebAssembly, font MIME types, compression, caching, security headers and health checks. |
| `.dockerignore` | Restricts the generated Docker build context to compiled assets and required packaging files. |
| `docker-compose.yml` | Provides a ready-to-use deployment configuration. |
| `.github/workflows/publish-image.yml` | Automates upstream release detection, Rust/Trunk compilation, multi-platform GHCR publishing and GitHub Releases. |
| `README.md` | Documents the project, build architecture and deployment options. |

### Docker build architecture

This repository keeps its own packaging configuration while retrieving the official VectorCraft source during automated builds.

1. GitHub Actions resolves the latest official upstream release, or the requested `upstream_tag`.
2. It checks out `storytold/vectorcraft` at that release tag and checks out `storytold/craft-fonts`.
3. Rust, the `wasm32-unknown-unknown` target and Trunk build `apps/vectorcraft-web` using `trunk build --release`.
4. The upstream `Trunk.toml` writes static files to `dist/web`; its post-build hook copies the required web fonts.
5. The workflow assembles a temporary `docker-context/` containing `site/`, upstream legal notices, and the version-controlled `Dockerfile`, `nginx.conf`, and `.dockerignore` from this repository.
6. Docker Buildx packages the already compiled site into an NGINX runtime image for `linux/amd64` and `linux/arm64`, without recompiling Rust per architecture.
7. GHCR receives the image tags; only then is the corresponding GitHub Release created or updated.

The `docker-context/` folder is generated by GitHub Actions and is **not** committed to this repository. This packaging approach differs from PhotoCraft's multi-stage Dockerfile because VectorCraft's WebAssembly build is performed once by the workflow before Docker packaging.

The runtime container serves static files, runs NGINX as a non-root user on port `8080`, and requires no database, persistent application volume or GPU passthrough.

> [!NOTE]
> VectorCraft is under active development. Future upstream releases may change Rust, Trunk, font requirements or application paths and require packaging updates.

## Automated builds

| Trigger | Behaviour |
|---|---|
| Daily schedule | Checks the latest official VectorCraft release and skips it if already packaged |
| Manual workflow dispatch | Builds the latest official release or a specific `upstream_tag` |
| Force rebuild | Rebuilds an already published version with `force_rebuild: true` |
| Packaging changes on `main` | Rebuilds the latest official upstream release when the workflow, Dockerfile, NGINX configuration or `.dockerignore` changes |

Each successful build publishes these GHCR tags:

- `latest` — the most recently packaged upstream release.
- `<upstream-version>` — the exact upstream release tag, for example `v0.12.0`.
- `upstream-<commit>` — the first 12 characters of the upstream source commit.

Images target `linux/amd64` and `linux/arm64`. The workflow records both the VectorCraft source revision and the `craft-fonts` revision. The fonts checkout follows the default branch and is not pinned to a release-specific commit.

After a successful GHCR push, the workflow creates or updates the corresponding GitHub Release with the official release notes, upstream source commit, font revision, image tags and Docker image digest.

> [!IMPORTANT]
> A new upstream release is not published until the Docker build and push succeed. The `latest` tag is mutable; use a specific version tag for repeatable deployments.

## Unraid Community Applications

This image is intended for distribution through the maintainer's existing Unraid Community Applications repository.

- **Unraid Community Applications repository:** [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps)
- **VectorCraft Web template:** [vectorcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/vectorcraft-web.xml)

The Unraid template is maintained separately from this Docker packaging repository.

## Upstream project

VectorCraft is an open-source vector illustration editor developed by the ArtCraft Team and contributors.

- **Source code:** [storytold/vectorcraft](https://github.com/storytold/vectorcraft)
- **Official website:** [getartcraft.com/apps/vectorcraft](https://getartcraft.com/apps/vectorcraft)
- **Official web hosting guide:** [packaging/web/README.md](https://github.com/storytold/vectorcraft/blob/main/packaging/web/README.md)
- **Official releases:** [VectorCraft releases](https://github.com/storytold/vectorcraft/releases)
- **Shared fonts:** [storytold/craft-fonts](https://github.com/storytold/craft-fonts)

This repository is independent community-maintained Docker packaging, not an official VectorCraft distribution.

## License and attribution

VectorCraft is dual-licensed under the **MIT License or Apache License 2.0**, at the user's option. Copyright belongs to the ArtCraft Team and contributors.

The workflow preserves upstream `LICENSE-MIT`, `LICENSE-APACHE`, `NOTICE` and `ATTRIBUTION.md` in the published image's `/legal/` directory, together with available `craft-fonts` license files.

- [Upstream MIT License](https://github.com/storytold/vectorcraft/blob/main/LICENSE-MIT)
- [Upstream Apache License 2.0](https://github.com/storytold/vectorcraft/blob/main/LICENSE-APACHE)
- [Upstream NOTICE](https://github.com/storytold/vectorcraft/blob/main/NOTICE)
- [Upstream asset attributions](https://github.com/storytold/vectorcraft/blob/main/ATTRIBUTION.md)

Upstream licenses do not automatically license the independent packaging files in this repository. The VectorCraft name and ArtCraft branding remain with their respective owners.

## Disclaimer

VectorCraft is under active development. Features, compatibility and behaviour may change between builds. This independent community packaging is not affiliated with or endorsed by the official project maintainers.
