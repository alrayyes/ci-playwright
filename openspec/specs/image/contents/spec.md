# image/contents Specification

## Purpose
What the image must carry and how it runs, so a Playwright CI job needs no install step.

## Requirements

### Requirement: Image carries what a Playwright CI job needs
The image SHALL contain Playwright's browsers in `/ms-playwright`, the
`playwright` command and library at the version the browsers were built for,
Bun with `bunx`, node and npx, git, gh, unzip, ImageMagick (`convert`), lcov,
pipx, sudo, openssl and curl.

#### Scenario: Tools resolve
- **WHEN** the image runs `command -v` for each tool
- **THEN** every one resolves

#### Scenario: bunx matches bun
- **WHEN** the image runs `bunx --version`
- **THEN** it prints the same version as `bun --version`

#### Scenario: Headless Chromium launches
- **WHEN** a script launches Chromium and loads a `data:` URL
- **THEN** the page title is readable

### Requirement: Git trusts any directory
The image SHALL set `safe.directory` to `*` at system level, so a job whose
checkout belongs to another user can run git.

#### Scenario: System safe.directory
- **WHEN** `git config --system --get-all safe.directory` runs
- **THEN** it prints `*`

### Requirement: Image runs as root
The image SHALL run as root, because `actions/checkout` fails under a non-root
user in a job's own `container:`.

#### Scenario: Default identity
- **WHEN** the image runs with no `--user` flag
- **THEN** `id -u` reports `0`
