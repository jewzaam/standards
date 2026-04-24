# GitHub Workflows

Standard CI workflows for Python projects.

## Naming convention

**Workflow filename and `name:` field describe the workflow's purpose.**
For single-target workflows, the name matches the make target (e.g.,
`test-coverage` → `make test-coverage`). Consolidated workflows use a
short descriptive name and invoke multiple targets as sequential steps
(e.g., `quality` runs `make test-format`, `make test-lint`,
`make test-typecheck`).

## Required Workflows

| Workflow | Template | Description |
|----------|----------|-------------|
| `test` | [test.yml](templates/workflows/test.yml) | Run pytest with coverage |
| `quality` | [quality.yml](templates/workflows/quality.yml) | Format check + lint + type check |

## Optional Workflows

| Workflow | Template | Description |
|----------|----------|-------------|
| `version-check` | [version-check.yml](templates/workflows/version-check.yml) | Validate semver format, source consistency, and version bump |
| `test-reachability` | [test-reachability.yml](templates/workflows/test-reachability.yml) | Verify all content files are reachable from entry points |
| `fabcheck` | [fabcheck.yml](templates/workflows/fabcheck.yml) | Foreign-API binding completeness check (migrate into `quality` when adopted) |

### Mutation Testing

Do not run mutation testing in GitHub Actions. mutmut runs are slow (1-2 hours for
a mid-size project), expensive in CI minutes, and the results are rarely reviewed.
Use `make test-mutation` locally when investigating test suite quality. See
[Makefile Standards — Mutation testing](makefile.md#mutation-testing) for the local
target and mutmut version requirements.

### Version Check

Copy when the project opts in to semver enforcement. Can be configured as a required
status check on GitHub PRs. Requires `fetch-depth: 0` for full git history (needed
by `git merge-base`). See [Makefile Standards — version-check](makefile.md#version-check)
for setup.

## Setup

Copy the required workflow files from [templates/workflows/](templates/workflows/) to your project's `.github/workflows/` directory:

```bash
cp build/templates/workflows/test.yml build/templates/workflows/quality.yml .github/workflows/
```

No modifications needed — workflows use Makefile targets which handle project-specific paths.

Projects with system-level dependencies (e.g., `python3-tk` for Tkinter) should add
an install step before `make install-dev` in their local copy of `test.yml`.

## Conventions

### Python version

Use Python 3.14 for all workflows. No version matrix — single-version testing reduces
CI minutes without sacrificing signal for projects that only target one runtime.

### pip caching

All `actions/setup-python` steps include `cache: 'pip'`:

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: "3.14"
    cache: 'pip'
```

This caches pip's download cache (`~/.cache/pip`), keyed by OS + Python version +
hash of `pyproject.toml`. On cache hit, pip uses locally cached wheels instead of
downloading from PyPI. The `pip install` step still runs (it resolves and installs)
but skips network downloads.

**Limitation:** git-based dependencies (e.g., `pkg @ git+https://...`) are re-cloned
on every run regardless of cache state.

### Concurrency groups

All workflows use concurrency groups to cancel in-progress runs when a new commit
lands on the same branch:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

This prevents queueing stale runs during rapid-fire pushes to a PR branch.

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
- name: Run tests with coverage
  run: make test-coverage
```

This keeps CI configuration simple and ensures local `make check` matches CI behavior.

### Pin the venv to the matrix Python

The install step passes `PY_SYS=python` so the venv is bootstrapped with the Python that `actions/setup-python` put on `PATH`, not the container's default `python3`:

```yaml
- name: Install dependencies
  run: make install-dev PY_SYS=python
```

Without this, [act](local-workflow-testing.md) falls back to the `catthehacker/ubuntu:act-22.04` image's default `python3` and fails with `requires-python >=3.14`. See [Makefile Standards — Pinning the venv interpreter](makefile.md#pinning-the-venv-interpreter-py_sys) for the full rationale.

## Migration from individual workflows

Projects using the old per-check workflow pattern (5 separate workflows: `test-unit`,
`test-coverage`, `test-lint`, `test-format`, `test-typecheck`) should consolidate:

1. Replace `test-unit.yml` + `test-coverage.yml` with `test.yml`
2. Replace `test-lint.yml` + `test-format.yml` + `test-typecheck.yml` with `quality.yml`
3. Update branch protection rules to require `test` and `quality` instead of the old names
4. Delete the old workflow files
