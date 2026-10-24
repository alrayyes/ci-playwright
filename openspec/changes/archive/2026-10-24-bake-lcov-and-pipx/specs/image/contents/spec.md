## MODIFIED Requirements

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
