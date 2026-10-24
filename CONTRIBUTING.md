# Contributing

## What you need

- **bun** `1.3.14`, pinned in `.bun-version`. It installs the dev dependencies
  and runs the hooks.
- **Docker**, to build the image and to run hadolint. The image is about 2 GB, so
  leave room for it.
- **shellcheck**, for the scripts.

That is the whole toolchain. Everything else arrives through `bun install`.

## Getting set up

```sh
bun install
```

That installs the dependencies and, through the `prepare` script, installs
lefthook's git hooks. Do it before your first commit — the hooks are most of
what stops CI being the place you find things out.

## The checks

Run what the pipeline runs:

```sh
bun run lint                # biome: JSON, and anything else it supports
bun run lint:pkg            # sort-package-json: canonical key order
bun run check:biome-schema  # biome.json's $schema vs. the pinned @biomejs/biome
bun run format:check        # prettier: Markdown and YAML layout
bun run lint:md             # markdownlint: structure, links, heading levels
bun run lint:mechanics      # ltex: grammar and spelling
bun run lint:prose          # vale: house style

docker run --rm -i -v "$PWD/.hadolint.yaml:/.hadolint.yaml:ro" hadolint/hadolint:v2.15.1-alpine@sha256:a1d49ae1a4e83c1dbad26b8c1ad7588c8bd1e04f4866b34ad3cac50335198552 hadolint --config /.hadolint.yaml - < Dockerfile
scripts/build.sh ci-playwright:local
scripts/smoke-local.sh ci-playwright:local
shellcheck scripts/versions.sh scripts/build.sh scripts/smoke-local.sh test/smoke.sh
```

To run it by hand: `bun run audit` lists every known vulnerability in the
pinned dependencies, including ones the `Dependency advisories` ticket already
tracks. It isn't a hook or a CI step, because the gate in CI fails only on
what a pull request adds.

Prose is linted in tiers because they answer to different things. Layout is
Prettier's, structure is markdownlint's, mechanics have a right answer, and
style is advice. Mechanics fails the build; style reports and does not, because
style advice that blocks a merge teaches people to skip the hooks.

`bun run format`, `bun run lint:fix` and `bun run lint:pkg:fix` are the
writing versions of `format:check`, `lint` and `lint:pkg`. They take file
arguments (`bun run format README.md`), which is how the hook calls them.

The hooks run the same commands, which is the point — they cannot drift from CI
if there is one copy of each:

- **pre-commit** judges only what the commit contains: every job is handed the
  staged files, so a half-finished file elsewhere can't fail or be rewritten by
  a commit. It formats them with biome and Prettier and restages what they
  touched, then runs markdownlint, and hadolint on a staged `Dockerfile` (read
  from the index). It may write, and it builds the image when the `Dockerfile`
  is staged.
- **commit-msg** runs commitlint.
- **pre-push** runs everything in check mode over the whole tree, including the
  two prose tiers. It never writes: a hook rewriting files under a push leaves
  the pushed commit and your working tree disagreeing about what was reviewed.

The first `bun run lint:mechanics` downloads ltex-ls-plus, which is about
300 MB because it ships its own JVM. It caches outside the repository under
`$XDG_CACHE_HOME`, so that is once per machine and a few seconds thereafter.
Vale fetches its style packages into `styles/` on first run; both of those
directories are gitignored.

CI adds one check the hooks cannot: it builds the image and runs
`test/smoke.sh` against it. A missing tool, or a Playwright or Bun version that
differs from the Dockerfile, fails the pull request rather than whoever pulls
the image.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/), enforced by
commitlint on `@commitlint/config-conventional` unextended. The format keeps the
history readable and the Dependabot prefixes meaningful. There is no version
to compute, because the image tags come from the Dockerfile (see Releasing).

One logical change per commit, each building and passing its own tests. A
refactor and a feature are two commits.

## Changing the Dockerfile

- **The Playwright tag is the contract.** The `FROM` tag has to equal the
  consumers' `@playwright/test` version exactly, or Playwright looks for browser
  builds that are not there. `scripts/versions.sh` reads it, and the build, the
  smoke test and the publish workflow all take their versions from it. Never
  write the version anywhere else.
- **Bun comes from its own image** in a named stage, because Dependabot reads
  `FROM` lines and nothing else. The `gh` version and checksum are build
  arguments and move by hand, together.
- **apt package versions are deliberately unpinned**, and DL3008 is off in
  `.hadolint.yaml` with the reason beside it. DL3002 is off too: the image runs
  as root on purpose, since `actions/checkout` breaks under a non-root user.
- **Add the assertion first.** A new tool goes into `test/smoke.sh` and fails
  there before the Dockerfile installs it.

Adding a package makes the image bigger for everyone pulling it, so it wants an
argument in the commit message, not just a line in the `RUN`.

## Tracking a change

A non-trivial change carries two records, side by side: a GitHub issue for
why it matters, and an OpenSpec change under `openspec/changes/` for
_what the system must do_ — a proposal, a spec delta where behaviour
actually changes, and a task list. Neither replaces the other. Create one
with `openspec new change <name>`, or ask your assistant to propose one;
`openspec archive <name>` folds a finished change's spec deltas into
`openspec/specs/` once it ships. A pure tooling, config or docs change with
no observable behaviour change sets `skip_specs: true` in the change's
`.openspec.yaml` rather than inventing a spec for it.

`openspec/` and `.claude/` (OpenSpec's own generated skills and commands)
are excluded from this repo's Markdown linting: they follow OpenSpec's own
template contract, not this repo's house style.

## Opening a pull request

Branch, push, open a pull request — nothing lands on `main` directly. Read your
own diff first; if it carries two changes, say so at the top of the description
rather than leaving it to be found.

Label it from GitHub's standard set: `bug`, `enhancement` or
`documentation`.

Spend the description on **why**. The diff already says what.

**Pull requests are squash merged**, and it is the only method this repository
allows. One pull request becomes one commit on `main`, so **the pull request
title and body become the commit message**. Write them accordingly.

## Releasing

Merging to `main` publishes. `.github/workflows/publish.yml` builds the image,
runs `test/smoke.sh` against it, and only then pushes two tags to
`ghcr.io/alrayyes/ci-playwright` and attests the provenance. The tags come from
the Dockerfile: `<playwright>` and `<playwright>-bun<bun>`.

To cut a new Playwright version, bump the `FROM` tag and digest (Dependabot
does this weekly), merge, and bump `@playwright/test` to the same version in each
consumer. To cut a new image of the same version, such as a patched base or a
new `gh`, change the Dockerfile and merge: the floating tag moves, so consumers
pin the digest.

A new package starts private. Make it public once, in the package settings on
GitHub, so the Forgejo runners and CI can pull it without a login.
