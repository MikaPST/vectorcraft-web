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
  <a href="https://github.com/MikaPST/vectorcraft-web/actions/workflows/publish-image.yml">
    <img src="https://github.com/MikaPST/vectorcraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish VectorCraft Web">
  </a>
  <a href="https://github.com/MikaPST/vectorcraft-web/releases/latest">
    <img src="https://img.shields.io/github/v/release/MikaPST/vectorcraft-web?label=Release&logo=github&color=blue" alt="Latest Release">
  </a>
  <a href="https://github.com/MikaPST/vectorcraft-web/pkgs/container/vectorcraft-web">
    <img src="https://ghcr-badge.egpl.dev/mikapst/vectorcraft-web/latest_tag?trim=major&label=GHCR" alt="GHCR image tag">
  </a>
  <a href="docker-compose.yml">
    <img src="https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white" alt="Docker Compose configuration">
  </a>
</p>

---

## Why this repository?

The official VectorCraft project provides a WebAssembly-based version of its vector illustration editor that can be hosted as a static website. This repository automates building that web application from the upstream source code and packages the generated files into a Docker image served by NGINX.

The goals are to:

- Publish a matching GitHub Release only after the Docker build and push succeed.
- Build VectorCraft Web from the upstream source code.
- Include the shared web font resources from [storytold/craft-fonts](https://github.com/storytold/craft-fonts).
- Publish a ready-to-run Docker image to GHCR.
- Automatically rebuild the image every week to incorporate upstream changes.
- Provide a convenient deployment option for Unraid Community Applications.
- Offer a simple Docker Compose configuration for users who prefer managing containers with Compose.
- Keep the packaging and deployment configuration separate from the upstream VectorCraft project.

This is a packaging and distribution project, not a fork intended to develop a separate vector editor.

## How it works

VectorCraft Web runs directly in the user's browser using WebAssembly. The Docker container serves the compiled static web application through NGINX; it does not provide a remote Linux desktop or perform document processing on the server.

- **Browser-based editor:** access the vector illustration editor through a modern web browser.
- **Local file selection:** opening files uses the browser's file picker.
- **Browser downloads:** Save, Save As and Export generate browser downloads.
- **Drag and drop:** supported files can be dropped into the browser application.
- **No remote desktop:** no VNC, remote desktop session or Linux graphical environment is required.
- **Self-hosted:** run the application on your own server and access it over your local network or through a properly configured reverse proxy.

The container serves the application files and web fonts. Document opening, editing and exporting take place in the browser; the container is not a document-storage service.

## Docker image

The image is published to GitHub Container Registry:

```text
ghcr.io/mikapst/vectorcraft-web:latest
```

Each official upstream release is also published under its exact version tag, for example:

```text
ghcr.io/mikapst/vectorcraft-web:vX.Y.Z
```

Use a versioned tag if you want to keep a deployment on a specific release. The `latest` tag updates when an image is published.

### Option 1 — Docker Compose (recommended)

A `docker-compose.yml` file is provided at the root of this repository. It is the simplest way to start and maintain VectorCraft Web with Docker Compose.

```yaml
services:
  vectorcraft-web:
    image: ghcr.io/mikapst/vectorcraft-web:latest
    container_name: vectorcraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

From the repository root, start the application with:

```bash
docker compose up -d
```

Open the application in your browser:

```text
http://YOUR_SERVER_IP:8080
```

Replace `YOUR_SERVER_IP` with the IP address or hostname of your server. If Docker is running on your own computer, you can use `http://localhost:8080`.

#### Useful Compose commands

```bash
# View container logs
docker compose logs -f

# Pull the latest image and recreate the container
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

No `.env` file or persistent volume is required for the default setup. The host port is configured in `docker-compose.yml`; by default, port `8080` on the host is mapped to port `8080` in the container. To use a different host port, change the left-hand side of the mapping. For example, `8081:8080` exposes the application on host port `8081`.

### Option 2 — Run directly with Docker

If you prefer not to use Docker Compose, you can run the container directly:

```bash
docker pull ghcr.io/mikapst/vectorcraft-web:latest

docker run -d \
  --name vectorcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/vectorcraft-web:latest
```

Open the application at:

```text
http://YOUR_SERVER_IP:8080
```

### Network access and browser requirements

The container listens for HTTP traffic on port `8080`. For external access, use a reverse proxy such as Traefik to terminate HTTPS and forward requests to the container over HTTP.

Do not expose an unencrypted HTTP port directly to the public Internet. Restrict access to your intended network or protect external access with HTTPS and appropriate access controls.

VectorCraft uses WebGPU where available and falls back to WebGL2. The application also provides a CPU rendering path for more compatible, but slower, operation:

- No query flag: use WebGPU where available, otherwise WebGL2.
- `?webgl`: force the WebGL2 backend.
- `?cpu`: force the CPU canvas path.

WebGPU requires a secure browser context (HTTPS, or localhost). Browser and graphics-driver support can affect performance and compatibility.

### Fonts and static hosting

VectorCraft's web build uses the shared `craft-fonts` repository for additional font resources. The generated `fonts/` directory must be served alongside the WebAssembly files.

The NGINX configuration used for the image:

- serves `.wasm` files with the `application/wasm` MIME type;
- serves `.ttf` files with the `font/ttf` MIME type;
- enables gzip compression for WebAssembly, JavaScript, CSS, HTML and other supported text resources;
- revalidates `index.html` so clients can discover the latest application build;
- applies long-lived caching to hash-addressed JavaScript, WebAssembly and font assets.

The application checks the integrity of downloaded web fonts. Font files must therefore be served unchanged; a rewritten or incorrectly served font may be rejected by the browser application.

## Automated builds

GitHub Actions checks the official [VectorCraft releases](https://github.com/storytold/vectorcraft/releases), builds the WebAssembly application from the selected upstream tag and publishes the image to GHCR.

| Trigger | Behaviour |
|---|---|
| Weekly schedule | Checks the latest official VectorCraft release and builds it if it has not already been published here |
| Manual workflow dispatch | Builds the latest official release, or a specified `upstream_tag` |
| Force rebuild | Rebuilds an already published version with `force_rebuild: true` |
| Changes to packaging files on `main` | Rebuilds the current official upstream release with the updated workflow |

### Published tags

- `latest` — the latest successfully published image (mutable tag).
- `<upstream-version>` — the exact official upstream tag, for example `vX.Y.Z`.
- `upstream-<commit>` — the upstream source commit used for the image (first 12 hexadecimal characters).

The image targets both `linux/amd64` and `linux/arm64`. The workflow checks out **the official upstream release tag**, rather than compiling `main` as the versioned source.

### GitHub Releases

After a successful Docker build and GHCR push, the workflow creates or updates a [GitHub Release](https://github.com/MikaPST/vectorcraft-web/releases) matching the upstream tag. It includes the upstream release notes, source link and commit, Docker tags, supported architectures and (when available) the published image digest.

The Release badge at the top of this README updates automatically. Scheduled runs skip versions already released here. You can force a rebuild from **Actions → Build and publish VectorCraft Web → Run workflow**.

> [!IMPORTANT]
> A GitHub Release is created only after the Docker image has been successfully published. The `latest` tag may change after a rebuild; pin a versioned image tag for a stable deployment. Auxiliary source repositories (for example `craft-fonts`) may be checked out separately and are not necessarily pinned to the upstream release commit.

### Build pipeline

The workflow:

1. Checks out this packaging repository.
2. Checks out the current upstream `storytold/vectorcraft` source.
3. Checks out the shared `storytold/craft-fonts` repository.
4. Installs the stable Rust toolchain, the `wasm32-unknown-unknown` target and Trunk.
5. Runs `trunk build --release` from `apps/vectorcraft-web`, with `CRAFT_FONTS_DIR` set to the fonts checkout and `CRAFT_FONTS_REQUIRED=1`.
6. Verifies that the generated static site contains its HTML entry point and WebAssembly module.
7. Packages the generated site into an NGINX image and publishes it to GHCR.

The web build writes its static site to `dist/web`. The upstream Trunk post-build hook also copies the web font files listed by VectorCraft into the generated `fonts/` directory when `craft-fonts` is supplied. The build is configured to fail rather than publish if the required fonts checkout is unavailable.

The Docker image is built directly inside the GitHub Actions workflow using an inline Dockerfile. The repository therefore does not need a separate `Dockerfile`, `nginx.conf` or `.dockerignore`.

The workflow records the exact VectorCraft and `craft-fonts` commits used for each image in the GitHub Actions summary and image labels.

## Unraid Community Applications

This image is intended to be distributed through the maintainer's Unraid Community Applications repository.

The Unraid template will reference the published GHCR image and provide configuration for the web port and other container settings.

- **Unraid Community Applications repository:** [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps)
- **VectorCraft Web template:** to be added after the image has been tested and validated.

This repository contains the image build, publication workflow and Docker Compose configuration. The Unraid Community Applications template is maintained separately.
- **Template:** [vectorcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/vectorcraft-web.xml)

## Upstream project

VectorCraft is an open-source vector illustration application developed by the ArtCraft Team and its contributors.

- **Source code:** [storytold/vectorcraft](https://github.com/storytold/vectorcraft)
- **Web build instructions:** [Development — Web build](https://github.com/storytold/vectorcraft/blob/main/docs/development.md)
- **Web hosting guide:** [Hosting VectorCraft for the web](https://github.com/storytold/vectorcraft/blob/main/packaging/web/README.md)
- **Shared font assets:** [storytold/craft-fonts](https://github.com/storytold/craft-fonts)
- **Official releases:** [VectorCraft releases](https://github.com/storytold/vectorcraft/releases)

The MikaPST GitHub Release tracks the upstream version but represents independent Docker packaging, not an official VectorCraft distribution.

## License and attribution

VectorCraft is dual-licensed under the **MIT License or Apache License 2.0**, at the user's option. The upstream project includes notices and attribution information for bundled third-party assets. Fonts supplied by `craft-fonts` retain their own licences, including SIL Open Font License notices where applicable.

- [Upstream MIT License](https://github.com/storytold/vectorcraft/blob/main/LICENSE-MIT)
- [Upstream Apache License 2.0](https://github.com/storytold/vectorcraft/blob/main/LICENSE-APACHE)
- [Upstream NOTICE](https://github.com/storytold/vectorcraft/blob/main/NOTICE)
- [Upstream asset attributions](https://github.com/storytold/vectorcraft/blob/main/ASSETS.md)

The licences for the upstream application do not automatically determine the licence of the packaging files maintained in this repository. Refer to the repository's own `LICENSE` file for the terms applicable to those files.

The VectorCraft name, ArtCraft branding and logos remain subject to their respective trademark and usage terms. This repository is an independent community-maintained packaging project and is **not an official VectorCraft release**, nor is it affiliated with or endorsed by the VectorCraft or ArtCraft maintainers.

## Disclaimer

VectorCraft is actively developed. Features, compatibility and behaviour may change between upstream builds. Test new images before relying on the application for important work. Use the application and its generated artwork at your own discretion.
