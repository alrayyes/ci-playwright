# Security

## Reporting a vulnerability

Please report it privately, through
[GitHub's private vulnerability reporting](https://github.com/alrayyes/ci-playwright/security/advisories/new)
— the Security tab of this repository, "Report a vulnerability". That opens a
draft advisory only you and the maintainers can see.

Not a public issue, please. A working exploit posted in the open is a working
exploit against everything that pulls this image.

Tell me what you did, what happened, and what you expected. A `Dockerfile` or a
workflow that reproduces it is worth more than a description of one.

I acknowledge within a week and tell you what I think, whether or not I
agree it is a vulnerability. If it is one, the fix ships as a `fix:` commit and
the advisory is published once the fixed image is.

## Supported versions

The newest Playwright version, and only that one. Every fix publishes a new
image, so "upgrade" is the patch. Pinned digests do not update themselves —
that is what pinning means — so a pin is a decision to stay on that image until
something moves it.

## What this image is exposed to

Worth knowing before you go looking, because these are deliberate:

- **It runs as root.** It is built to be a CI job's own `container:`, and
  `actions/checkout` breaks under a non-root user. It runs one short-lived job and
  no network-facing service. Run untrusted code in it only as you would on a
  runner.
- **git trusts every directory** (`safe.directory '*'`), because a job's checkout
  is owned by the runner's user and not by root. Do not point it at a directory
  you do not trust.
- **apt package versions are not pinned.** The base image digest is, and it is
  what a rebuild reproduces; the packages come from the Ubuntu release that base
  was built on. The reasoning is in `.hadolint.yaml`.
- **No secret belongs in this image.** Credentials arrive at runtime.

## Verifying what you pulled

Every published image is attested:

```sh
gh attestation verify oci://ghcr.io/alrayyes/ci-playwright:1.64.1 --repo alrayyes/ci-playwright
```

That tells you which commit and which workflow run built the digest. An image
that fails it did not come from here.
