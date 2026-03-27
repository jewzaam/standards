# Dependency Management

Standards for vetting, pinning, and maintaining third-party dependencies.

## Vetting New Dependencies

Before adding a dependency, verify:

1. **Existence** — Does the package exist on the registry? LLMs hallucinate package names at measurable rates (5.2% for commercial models, 21.7% for open-source models). Attackers register these hallucinated names with malicious code (slopsquatting). When an AI assistant suggests a package, verify it exists before installing.

2. **Maintenance status** — Is it actively maintained? Check for recent commits, open issues, and release frequency. Abandoned packages accumulate unpatched vulnerabilities.

3. **Known vulnerabilities** — Check for CVEs before adding. Use `pip-audit` (Python) or `npm audit` (npm) to scan dependencies.

4. **Established track record** — Prefer well-established packages over new/obscure ones. Brand-new packages with zero downloads are a slopsquatting risk.

## Pinning and Lockfiles

**Pin direct dependencies** in your manifest file:

- **Python (pyproject.toml):** Pin major versions with flexible minor/patch (e.g., `"requests>=2.31,<3.0"`). Pin exact versions (`"mypy==1.11.2"`) only when version drift causes breakage.

- **JavaScript (package.json):** Use caret ranges for libraries (`"^3.1.0"`), exact versions for tools (`"3.1.0"`).

**Use lockfiles and commit them:**

| Ecosystem | Lockfile | Tool |
|-----------|----------|------|
| Python + uv | `uv.lock` | `uv lock` |
| Python + Poetry | `poetry.lock` | `poetry lock` |
| npm | `package-lock.json` | `npm install` |
| Yarn | `yarn.lock` | `yarn install` |

Lockfiles capture the full transitive dependency tree at a known-good state. They are the only artifact that enables reproducible builds. Without lockfiles, `npm install` or `pip install` pulls the latest versions matching the range, which may introduce breaking changes or vulnerabilities.

## Scanning for Vulnerabilities

Run vulnerability scanning in CI and before releasing.

### Python: pip-audit

```bash
python -m pip_audit
```

**What it does:** Scans Python dependencies against PyPA Advisory Database and OSV.dev. Apache 2.0 licensed, official PyPA tool, no telemetry.

**What it catches:** Known CVEs in direct and transitive dependencies.

**What it misses:** Zero-day vulnerabilities, malware, typosquatting.

### npm: npm audit

```bash
npm audit
```

**What it does:** Checks dependencies against GitHub Advisory Database.

**What it catches:** Known CVEs.

**What it misses:** Zero-day vulnerabilities, malware, typosquatting, dependency confusion.

**Limitations:** High false positive rate for build-time-only dependencies. Does not distinguish dev dependencies from production dependencies.

### Tool Comparison

| Tool | npm | Python | Known CVEs | Malware Detection | Free |
|------|-----|--------|------------|-------------------|------|
| npm audit | ✅ | ❌ | ✅ | ❌ | ✅ |
| pip-audit | ❌ | ✅ | ✅ | ❌ | ✅ |
| OSV.dev API | ✅ | ✅ | ✅ | ❌ | ✅ |
| Socket.dev | ✅ | ✅ | ✅ | ✅ | ✅ (free tier) |
| Snyk | ✅ | ✅ | ✅ | Partial | ✅ (limited) |
| Dependabot | ✅ | ✅ | ✅ | ❌ | ✅ (GitHub) |

**No single tool catches all threats.** Known-vulnerability scanners (npm audit, pip-audit) cannot detect malicious packages, typosquatting, or dependency confusion. Behavioral analysis tools (Socket.dev) fill this gap.

## Updating Dependencies

1. **Review changelogs before bumping** — Understand what changed. Major version bumps may introduce breaking changes.

2. **Do not auto-merge dependency PRs without review** — Dependabot and Renovate PRs still require human judgment.

3. **Test after updating** — Run your full test suite after dependency updates.

4. **Consider delaying adoption of new releases** — Wait 7-14 days before adopting newly-released versions. This allows the community to discover issues and provides time for scanning tools to detect malicious releases.

## What to Avoid

1. **Avoid installing packages you have not verified** — Especially when an AI assistant suggests a package name you have not heard of.

2. **Avoid `pip install` with URLs to arbitrary tarballs** — Use PyPI or trusted registries.

3. **Avoid adding dependencies for trivial functionality** — The left-pad incident showed the risk of micro-dependencies. Prefer standard library or copy a few lines of code.

4. **Do not ignore audit findings** — If `pip-audit` or `npm audit` reports critical/high vulnerabilities, address them before shipping.

5. **Do not use Safety for commercial projects** — Safety DB is licensed CC BY-NC-SA 4.0 (non-commercial). Use pip-audit instead.

## Package Provenance (Emerging)

Package signing and provenance verification are early-stage but worth enabling when available:

- **npm provenance (Sigstore):** GA since October 2023. Verify with `npm audit signatures`.
- **PyPI attestations (PEP 740):** Launched November 2024. ~5% adoption among top packages at launch. No install-time verification in pip/uv yet.

Provenance proves a package was built from a specific source repository in a specific CI/CD environment. It does not prove the source code is safe.
