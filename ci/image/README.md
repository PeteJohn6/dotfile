# `ubuntu-dotfile` Image

`ci/image/` contains the Dockerfile and image-specific assets for the published `ubuntu-dotfile` image.

## Purpose

This directory defines the repository's prebuilt Ubuntu runtime image that already ran the container workflow during `docker build`. The resulting image contains installed software plus the selected dotfiles as ordinary files in the container home directory. That runtime-safe filesystem is produced by running `bash bootstrap-up.sh` during the build and then finalizing the deployed Dotter outputs so they no longer point back into the repository workspace. Do not place validation-only assets or devcontainer configuration here.

The Docker build context is the repository root, not `ci/image/`, because the build consumes the real workflow inputs under `.dotter/`, `packages/`, `bootstrap/`, `script/`, `justfile`, and `bootstrap-up.sh`.

## Runtime Layout

The finalized image keeps the deployed zsh source modules under `/root/.config/zsh/conf.d` and also copies them to `/root/conf.d`. `/root/.zshrc` loads that `/root/conf.d` runtime directory, so zsh starts with the same modules after `/workspace` has been removed from the image.

## Local Build

From the repository root:

    docker build -f ci/image/Dockerfile -t ubuntu-dotfile:local .

## Published Image

GitHub Actions publishes this image to:

    ghcr.io/petejohn6/ubuntu-dotfile

`master` branch pushes publish:

    ghcr.io/petejohn6/ubuntu-dotfile:master

When `master` is the default branch, the release workflow also publishes:

    ghcr.io/petejohn6/ubuntu-dotfile:latest

Published tags are multi-architecture images for `linux/amd64` and `linux/arm64`.
