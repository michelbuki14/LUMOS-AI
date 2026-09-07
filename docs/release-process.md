# Release Process

Every release must include:

- Version tag `vX.Y.Z` (semver)
- Release notes + `CHANGELOG.md` entry
- Migration guide if breaking
- Signed binaries + checksums where applicable
- Updated `docs/` + `README.md`
- `docker compose build` verified

## Steps

1. Update version in `package.json`, `Cargo.toml`, `pyproject.toml`, `apps/desktop/pubspec.yaml`
2. `CHANGELOG.md` — auto + manual notes
3. `git tag vX.Y.Z && git push origin vX.Y.Z`
4. GitHub Release with notes + artifacts
5. Announce in Discussions + Discord

## Quality Gate

`flutter analyze` 0 errors, `cargo check`, `pytest`, `docker compose build` all green.
