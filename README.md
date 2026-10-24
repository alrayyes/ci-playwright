# ci-playwright

[![CI](https://github.com/alrayyes/ci-playwright/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/alrayyes/ci-playwright/actions/workflows/ci.yml)
[![licence](https://img.shields.io/badge/licence-GPL--3.0--or--later-blue)](LICENSE)

A prebuilt CI image with Playwright's browsers, Bun, Node, git and gh, so a job
stops running `bunx playwright install --with-deps chromium` on every run. That
step costs minutes each time and sometimes hangs for ten.

```text
ghcr.io/alrayyes/ci-playwright:1.64.1
```

## What's in it

| Tool                                    | Why                                                                    |
| --------------------------------------- | ---------------------------------------------------------------------- |
| Playwright browsers in `/ms-playwright` | the point of the image                                                 |
| `playwright` command and library        | at the version the browsers were built for                             |
| Bun                                     | the version in the tag, from the Dockerfile                            |
| node, npx                               | `actions/checkout` is a node program                                   |
| git, gh                                 | git trusts any directory, because the checkout belongs to another user |
| unzip, imagemagick (`convert`)          | what the Playwright jobs already needed                                |
| lcov, pipx                              | coverage reports without a network install in the job                  |
| sudo, openssl, curl                     | the rest of what a job otherwise installs                              |

There is no Go. Keep `actions/setup-go` where a job needs it. The image runs as
root, because `actions/checkout` breaks under a non-root user, and it is
`linux/amd64` only.

## Tags

| Tag                | Meaning                                            |
| ------------------ | -------------------------------------------------- |
| `1.64.1`           | Playwright 1.64.1, whatever Bun version is current |
| `1.64.1-bun1.3.14` | the same image, with the Bun version spelled out   |

Both resolve to one digest. **Pin the digest as well as the tag**: the tag moves
when the image is rebuilt for a patched base or a newer `gh`.

## The version-matching rule

The tag must equal the repo's `@playwright/test` version exactly. Playwright
looks for the browser builds that match its own version, and a mismatch fails
with a missing executable. When you bump `@playwright/test`, bump the tag in the
same pull request, and add a check that fails CI when they drift.

## Using it

```yaml
jobs:
  e2e:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/alrayyes/ci-playwright:1.64.1@sha256:<digest>
      options: --ipc=host
    steps:
      - uses: actions/checkout@v7
      - run: bun install --frozen-lockfile
      - run: bunx playwright test
```

`--ipc=host` stops Chromium running out of shared memory. Find the digest with
`docker buildx imagetools inspect ghcr.io/alrayyes/ci-playwright:1.64.1`.

The Forgejo runners at git.higherlearning.eu pull from ghcr.io as well, so the
package has to be public. The image needs no registry credentials.

Verify where an image came from:

```sh
gh attestation verify oci://ghcr.io/alrayyes/ci-playwright:1.64.1 --repo alrayyes/ci-playwright
```

## Cutting a version

Merge to `main`. The publish workflow builds the image, runs
[`test/smoke.sh`](test/smoke.sh) against it and only then pushes both tags. The
Playwright and Bun versions come from the Dockerfile's two `FROM` lines, and
Dependabot raises the pull request that moves them. After it merges, bump
`@playwright/test` in each consumer to the same version.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Security reports go through
[SECURITY.md](SECURITY.md), not the issue tracker.

## Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).
