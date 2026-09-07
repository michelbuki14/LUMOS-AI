# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| main    | ✅        |
| 1.x     | ✅        |
| <1.0    | ❌        |

## Reporting a Vulnerability

**Do not open a public issue.**

Email: **security@lumos.ai** (placeholder — use GitHub private security advisory until email is live)
Or: GitHub → Security → Report a vulnerability

Include: description, impact, reproduction steps, affected versions, and any PoC. We acknowledge within 48h and aim to fix within 90 days. We coordinate disclosure with you.

## What We Review

Dependency vulnerabilities (Dependabot + `cargo audit` + `pip audit`), secure defaults, input validation, sandboxed plugins, secrets management (`.env` never committed), privacy protections (local-first).

## Secrets

Never commit `.env`. Use `.env.example`. Rotate keys if leaked.

## Disclosure

We publish a security advisory and changelog entry after a fix, crediting the reporter unless anonymity is requested.
