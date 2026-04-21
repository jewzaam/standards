# GitHub Workflows

Standard CI workflows for ap-* projects.

## Naming convention

**Workflow filename and `name:` field both match the make target they invoke.**
Lower-case, hyphenated, exact match. So `make test-unit` lives in
`.github/workflows/test-unit.yml` with `name: test-unit`.

This makes branch-protection setup trivial — searching for `test-` in the
required-status-checks list surfaces every quality gate at once. It also
removes any guesswork about which workflow runs which target.

## Required Workflows

| Workflow | Template | Description |
|----------|----------|-------------|
| `test-unit` | [test-unit.yml](templates/workflows/test-unit.yml) | Run pytest on Python 3.12-3.14 |
| `test-lint` | [test-lint.yml](templates/workflows/test-lint.yml) | Run flake8 linter |
| `test-typecheck` | [test-typecheck.yml](templates/workflows/test-typecheck.yml) | Run mypy type checker |
| `test-format` | [test-format.yml](templates/workflows/test-format.yml) | Verify black formatting |
| `test-coverage` | [test-coverage.yml](templates/workflows/test-coverage.yml) | Enforce 80% coverage threshold |

## Optional Workflows

| Workflow | Template | Description |
|----------|----------|-------------|
| `test-mutation` | [test-mutation.yml](templates/workflows/test-mutation.yml) | Run mutmut mutation testing (post-merge only) |
| `version-check` | [version-check.yml](templates/workflows/version-check.yml) | Validate semver format, source consistency, and version bump |

### Mutation Testing

Runs on push to main only — not on PRs. Mutation testing is computationally expensive
(each mutant requires a full test run) and should not block merges. Uses `concurrency`
with `cancel-in-progress: true` so that rapid-fire merges cancel stale runs instead
of queueing 1-2 hour jobs that will never be looked at. Use a README badge to surface
the current mutation score:

```markdown
[![test-mutation](https://github.com/<owner>/<repo>/actions/workflows/test-mutation.yml/badge.svg?branch=main)](https://github.com/<owner>/<repo>/actions/workflows/test-mutation.yml)
```

See [Makefile Standards — Mutation testing](makefile.md#mutation-testing) for the
Makefile target and mutmut version requirements.

### Version Check

Copy when the project opts in to semver enforcement. Can be configured as a required
status check on GitHub PRs. Requires `fetch-depth: 0` for full git history (needed
by `git merge-base`). See [Makefile Standards — version-check](makefile.md#version-check)
for setup.

## Setup

Copy all files from [templates/workflows/](templates/workflows/) to your project's `.github/workflows/` directory:

```bash
cp -r build/templates/workflows/* .github/workflows/
```

No modifications needed - workflows use Makefile targets which handle project-specific paths.

## Conventions

### Python versions

Test on Python 3.12 through 3.14. Use 3.12 for single-version jobs (lint, format, typecheck, coverage).

### Actions versions

Use current major versions:
- `actions/checkout@v4`
- `actions/setup-python@v5`

### Triggers

All workflows run on push to main and all PRs to main:

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

### Use Makefile targets

Workflows call Makefile targets, not duplicate commands:

```yaml
- name: Run tests
  run: make test
```

This keeps CI configuration simple and ensures local `make test` matches CI behavior.

### Pin the venv to the matrix Python

The install step passes `PY_SYS=python` so the venv is bootstrapped with the Python that `actions/setup-python` put on `PATH`, not the container's default `python3`:

```yaml
- name: Install dependencies
  run: make install-dev PY_SYS=python
```

Without this, [act](local-workflow-testing.md) matrix legs targeting Python ≥3.12 fall back to the `catthehacker/ubuntu:act-22.04` image's default `python3` (3.11) and fail with `requires-python >=3.12`. See [Makefile Standards — Pinning the venv interpreter](makefile.md#pinning-the-venv-interpreter-py_sys) for the full rationale.
