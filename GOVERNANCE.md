# Governance

LUMOS AI is community-driven with a maintainer council.

## Roles

- **Contributors**: anyone who contributes code, docs, design, testing, or community help.
- **Maintainers**: review, merge, and steward a subsystem (engine, desktop, api, ai, docs). Listed in `MAINTAINERS.md`.
- **Lead Maintainers**: cross-cutting decisions, releases, and governance changes.

## Decision Making

- Lazy consensus on PRs: 2 maintainer approvals, 48h window.
- Breaking API changes: RFC in Discussions → maintainer vote (majority).
- Governance changes: PR to this file + 2/3 maintainer approval.

## Releases

Semantic versioning. Every release: version tag, release notes, migration guide (if needed), checksums, updated docs, changelog. See `docs/release-process.md`.

## Code of Conduct

Enforced per [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Reports to maintainers, confidential.

## Becoming a Maintainer

Sustained high-quality contributions + nomination by existing maintainer + council approval.

## Licensing

All contributions under [Apache 2.0](LICENSE). Third-party deps must be license-compatible (documented in `THIRD_PARTY.md`).
