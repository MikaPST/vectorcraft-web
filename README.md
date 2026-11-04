# VectorCraft Web

[![Build and publish](https://github.com/MikaPST/vectorcraft-web/actions/workflows/publish-image.yml/badge.svg)](https://github.com/MikaPST/vectorcraft-web/actions/workflows/publish-image.yml)
[![GHCR](https://img.shields.io/badge/GHCR-vectorcraft--web-2496ED?logo=docker&logoColor=white)](https://github.com/MikaPST/vectorcraft-web/pkgs/container/vectorcraft-web)

A community-maintained Docker image for the browser-based version of [VectorCraft](https://github.com/storytold/vectorcraft), an open-source vector illustration application written in Rust.

This repository builds the official VectorCraft Web application from source, includes the upstream `craft-fonts` resources, and publishes a multi-platform Docker image to GitHub Container Registry.

## Docker image

```text
ghcr.io/mikapst/vectorcraft-web:latest
```

## Docker Compose

```yaml
services:
  vectorcraft-web:
    image: ghcr.io/mikapst/vectorcraft-web:latest
    container_name: vectorcraft-web
    restart: unless-stopped
    ports:
      - "8080:8080"
```

Open `http://YOUR_SERVER_IP:8080`.

## Build automation

GitHub Actions checks out the latest commits of:

- [storytold/vectorcraft](https://github.com/storytold/vectorcraft)
- [storytold/craft-fonts](https://github.com/storytold/craft-fonts)

It installs the stable Rust toolchain, the `wasm32-unknown-unknown` target and Trunk, then runs the upstream Web build from `apps/vectorcraft-web`:

```bash
CRAFT_FONTS_DIR=/absolute/path/to/craft-fonts CRAFT_FONTS_REQUIRED=1 trunk build --release
```

The workflow copies the generated `dist/web` site into a temporary Docker build context and builds the image using an inline Dockerfile. No Dockerfile, NGINX configuration file or `.dockerignore` is required in this repository.

The workflow runs every Monday at 04:17 UTC, when packaging files change on `main`, or manually through **Actions → Build and publish VectorCraft Web → Run workflow**.

Each build records the exact VectorCraft and craft-fonts commit SHAs in the GitHub Actions summary and image labels. Published tags include:

- `latest`
- `upstream-<short-commit>`

Images are published for `linux/amd64` and `linux/arm64`.

## Fonts

`craft-fonts` is checked out as a separate build input. `CRAFT_FONTS_DIR` points VectorCraft's build scripts to that checkout, and `CRAFT_FONTS_REQUIRED=1` makes the build fail if the fonts checkout is missing or invalid.

The upstream Trunk post-build hook copies the web fonts listed by VectorCraft into `dist/web/fonts`. The font files and their hash-addressed paths must be served unchanged. The image's NGINX configuration serves `.ttf` as `font/ttf`, enables compression, and applies long-lived caching to hash-addressed WebAssembly, JavaScript and font assets.

## Browser requirements

VectorCraft uses WebGPU where available and WebGL2 otherwise. WebGPU requires a secure browser context (HTTPS, or localhost). Append `?webgl` to the URL to force the WebGL2 backend.

## Upstream projects

- Application: https://github.com/storytold/vectorcraft
- Shared fonts: https://github.com/storytold/craft-fonts
- Web build documentation: https://github.com/storytold/vectorcraft/blob/main/docs/development.md
- Static hosting notes: https://github.com/storytold/vectorcraft/blob/main/packaging/web/README.md

## Disclaimer

This is an independent community packaging project maintained by MikaPST. It is not an official VectorCraft image or distribution. VectorCraft is dual-licensed under MIT or Apache-2.0; bundled assets and fonts retain their respective licences. See the upstream `NOTICE`, `ASSETS.md` and licence files for details.
