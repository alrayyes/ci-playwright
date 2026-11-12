# Three FROM lines, each one a thing Dependabot's Docker updater reads (it reads FROM lines
# and no other). scripts/versions.sh reads the first two to derive the image tags and labels.
#
# bun and playwright are named stages and only sources for the COPYs below, never the
# final image. The final image starts from plain Ubuntu, because the Playwright image
# carries Firefox and WebKit plus the libraries they need, roughly 1 GB nothing here
# runs, and deleting them in a later layer would not give the space back (#36).
FROM oven/bun:1.4.4@sha256:1d22548f177f4ff38e0c15baa3c2c46c6c2060ba2d1bc573bb4720b407548f1d AS bun

# The tag must equal the consumers' @playwright/test version exactly, or Playwright
# looks for browser builds that are not here. Chromium's builds come from this stage.
FROM mcr.microsoft.com/playwright:v1.65.0-noble@sha256:6e3fb709361521eb27161606e6da6d2674e5e89fa16516cb37d6fdd91372273d AS playwright

# Same Ubuntu release as the Playwright image above (noble), so the browser builds
# copied across find the libraries they were built against.
FROM ubuntu:24.04@sha256:2198e4c65076e9cb0b3d695219df667c0e3b0072da64ca3c2648aca17dcecaf5

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG GH_VERSION=2.103.2
ARG GH_SHA256=62ccf747115ddc61237efffdde66a3c8f70ba249433dc64f70801089b59c59c8

# What a CI job otherwise installs on every run. gcc and libc6-dev are there for
# cgo: the base image ships no libc dev headers, and a bump of it must not decide
# that.
#
# Deliberately unpinned apt packages: they belong to the Ubuntu release the base
# is built on, and only the digest above moves when it does (.hadolint.yaml).
#
# gh is the release tarball rather than the Ubuntu package, which lags by years, and
# is checked against the published checksum.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gcc \
        git \
        imagemagick \
        lcov \
        libc6-dev \
        openssh-client \
        openssl \
        pipx \
        sudo \
        unzip \
        zstd && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" -o /tmp/gh.tgz && \
    echo "${GH_SHA256}  /tmp/gh.tgz" | sha256sum -c - && \
    tar -xzf /tmp/gh.tgz -C /tmp && \
    install -m 0755 "/tmp/gh_${GH_VERSION}_linux_amd64/bin/gh" /usr/local/bin/gh && \
    rm -rf /tmp/gh.tgz "/tmp/gh_${GH_VERSION}_linux_amd64"

COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
# The official image ships bunx as a symlink to bun, and consumers call it.
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx

# Node, npm and npx from the Playwright image, so they are the version that image
# was tested with. npm and npx are symlinks into the module, kept as symlinks.
COPY --from=playwright /usr/bin/node /usr/bin/node
COPY --from=playwright /usr/lib/node_modules/npm /usr/lib/node_modules/npm
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm && \
    ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/bin/npx

# The playwright CLI and library, at the version the browsers were built for.
# PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD because they are copied in below, not downloaded.
#
# The version is a build argument, never a default, so it cannot drift from the FROM
# tag above when Dependabot bumps only that. scripts/versions.sh reads the tag and
# every build passes it in; an empty one fails the build here.
ARG PLAYWRIGHT_VERSION
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    NODE_PATH=/usr/lib/node_modules \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
# install-deps chromium pulls the system libraries and fonts Chromium needs and
# nothing for Firefox or WebKit.
RUN test -n "${PLAYWRIGHT_VERSION}" && \
    npm install --global --no-fund --no-audit "playwright@${PLAYWRIGHT_VERSION}" && \
    npm cache clean --force && \
    playwright install-deps chromium && \
    rm -rf /var/lib/apt/lists/*

# Chromium only: the full build, the headless shell Playwright launches by default,
# and ffmpeg for video recording. The exact builds the Playwright image tested.
RUN --mount=type=bind,from=playwright,source=/ms-playwright,target=/mnt/pw \
    mkdir -p /ms-playwright && \
    cp -a /mnt/pw/chromium-* /mnt/pw/chromium_headless_shell-* /mnt/pw/ffmpeg-* /ms-playwright/

# A job's checkout is owned by whoever the runner is, not by root, and git refuses
# to read it without this.
RUN git config --system --add safe.directory '*'

ARG IMAGE_VERSION
LABEL io.playwright.version="${PLAYWRIGHT_VERSION}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.source="https://github.com/alrayyes/ci-playwright" \
      org.opencontainers.image.description="Playwright's Chromium, Bun, Node, git and gh for CI jobs" \
      org.opencontainers.image.licenses="GPL-3.0-or-later"

# Root, deliberately: this is built to be a CI job's own `container:`, and
# actions/checkout breaks under a non-root user (rules/containers.md).
# No HEALTHCHECK: it runs one job and exits.
