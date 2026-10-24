## ADDED Requirements

### Requirement: Tag equals the Playwright version
The image tag SHALL equal the Playwright version the image carries, which the
consumers' `@playwright/test` version must also equal, and the
`io.playwright.version` label SHALL report it.

#### Scenario: Label matches tag
- **WHEN** `docker inspect` reads `io.playwright.version`
- **THEN** it equals the tag

#### Scenario: Versions come from the Dockerfile
- **WHEN** the build and publish workflows need the Playwright and Bun versions
- **THEN** they read them from the Dockerfile's `FROM` lines through
  `scripts/versions.sh`

### Requirement: Both tags share a digest
Publishing SHALL push `<playwright>` and `<playwright>-bun<bun>` in one build,
so they resolve to the same digest, and only after the smoke test has passed.

#### Scenario: Shared digest
- **WHEN** both tags are inspected after a publish
- **THEN** their digests are equal

### Requirement: Bun moves by hand for minor and major releases
Dependabot SHALL NOT raise minor or major updates for the Bun stage, because
every consumer pins Bun in `.bun-version` and the floating tag carries
whatever Bun is current.

#### Scenario: Dependabot ignores minor and major Bun updates
- **WHEN** `.github/dependabot.yml` is read
- **THEN** `oven/bun` ignores `version-update:semver-minor` and
  `version-update:semver-major`
