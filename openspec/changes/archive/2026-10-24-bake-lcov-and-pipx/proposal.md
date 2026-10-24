## Why

`movie-planner-web`'s test job ran `apt-get update` and installed `lcov` and
`pipx` on every run, which is the network install the image exists to remove
([#13](https://github.com/alrayyes/ci-playwright/issues/13)). The fewer things a
pipeline installs, the less can go wrong in it.

## What Changes

- Add `lcov` and `pipx` to the image, and to the smoke test.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `image/contents`: the tool list gains `lcov` and `pipx`.

## Impact

`Dockerfile`, `test/smoke.sh`, `README.md`. A new image digest, which consumers
pin.
