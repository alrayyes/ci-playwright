# Two FROM lines and nothing else version-bearing, because Dependabot's Docker
# updater reads FROM lines and no other. Bun comes from its own image in a named stage
# for that reason; it is only a source for the COPY below, never the final image.
# scripts/versions.sh reads both lines to derive the image tags and the labels.
FROM oven/bun:1.3.14@sha256:e10577f0db68676a7024391c6e5cb4b879ebd17188ab750cf10024a6d700e5c4 AS bun

# The tag must equal the consumers' @playwright/test version exactly, or Playwright
# looks for browser builds that are not here. Browsers sit in /ms-playwright.
FROM mcr.microsoft.com/playwright:v1.64.1-noble@sha256:47b510dd9230bf0b9bfc9b20102241e577ea7a99334ab4c3ca19f19770e9b8ea

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG GH_VERSION=2.103.2
ARG GH_SHA256=62ccf747115ddc61237efffdde66a3c8f70ba249433dc64f70801089b59c59c8

# What a CI job otherwise installs on every run. Deliberately unpinned apt packages:
# they belong to the Ubuntu release the base is built on, and only the digest above
# moves when it does (.hadolint.yaml).
#
# gh is the release tarball rather than the Ubuntu package, which lags by years, and
# is checked against the published checksum.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        lcov \
        pipx \
        sudo \
        unzip && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" -o /tmp/gh.tgz && \
    echo "${GH_SHA256}  /tmp/gh.tgz" | sha256sum -c - && \
    tar -xzf /tmp/gh.tgz -C /tmp && \
    install -m 0755 "/tmp/gh_${GH_VERSION}_linux_amd64/bin/gh" /usr/local/bin/gh && \
    rm -rf /tmp/gh.tgz "/tmp/gh_${GH_VERSION}_linux_amd64"

COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
# The official image ships bunx as a symlink to bun, and consumers call it.
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx

# The playwright CLI and library, at the version the browsers were built for.
# PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD because they are already in /ms-playwright.
#
# The version is a build argument, never a default, so it cannot drift from the FROM
# tag above when Dependabot bumps only that. scripts/versions.sh reads the tag and
# every build passes it in; an empty one fails the build here.
ARG PLAYWRIGHT_VERSION
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    NODE_PATH=/usr/lib/node_modules
RUN test -n "${PLAYWRIGHT_VERSION}" && \
    npm install --global --no-fund --no-audit "playwright@${PLAYWRIGHT_VERSION}" && \
    npm cache clean --force

# A job's checkout is owned by whoever the runner is, not by root, and git refuses
# to read it without this.
RUN git config --system --add safe.directory '*'

ARG IMAGE_VERSION
LABEL io.playwright.version="${PLAYWRIGHT_VERSION}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.source="https://github.com/alrayyes/ci-playwright" \
      org.opencontainers.image.description="Playwright's browsers, Bun, Node, git and gh for CI jobs" \
      org.opencontainers.image.licenses="GPL-3.0-or-later"

# Root, deliberately: this is built to be a CI job's own `container:`, and
# actions/checkout breaks under a non-root user (rules/containers.md).
# No HEALTHCHECK: it runs one job and exits.
