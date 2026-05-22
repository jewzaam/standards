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

`actions/setup-python` steps include `cache: 'pip'` **when the workflow actually
invokes pip** (typically via `make install-dev`):

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

**Omit `cache: 'pip'` when the workflow never calls pip** (e.g., a workflow that
runs only stdlib Python scripts like `test-reachability`). The post-job cache-save
step fails when `~/.cache/pip` was never created, breaking the workflow even if
the actual checks passed.

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

### Tag-triggered workflows and `GITHUB_TOKEN`

Tag pushes made by a job using the default `GITHUB_TOKEN` do **not** fire any
`on: push: tags:` workflow. GitHub Actions suppresses re-triggering to prevent
recursive runs. Splitting "auto-tag on push-to-main" and "build-release on
tag-push" across two workflows under `GITHUB_TOKEN` silently never fires the
second one.

Pattern: either

1. **Single workflow** on push to main creates the tag *and* builds/releases in
   one run. Use when tagging and release are deterministic from main.
2. **Personal Access Token (PAT) or GitHub App token** pushes the tag. The
   non-`GITHUB_TOKEN` push event fires downstream tag workflows normally. Use
   when tag and release must remain in separate workflows.

When to apply: any release flow that wants tag pushes to drive a downstream
job. Verify by checking the Actions tab — a silently-skipped run leaves no
log trail.

### Windows runner: `Get-FileHash` under `powershell.exe -File`

`Get-FileHash` (from `Microsoft.PowerShell.Utility`, normally auto-loaded in
Windows PowerShell 5.1) fails with `CommandNotFoundException` on the
`windows-latest` GitHub Actions runner image when invoked via
`powershell.exe -File <script>` in a non-interactive context. The cmdlet is
documented as built-in but is not resolvable in that invocation mode.

Pattern: compute SHA-256 via .NET directly:

```powershell
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $stream = [System.IO.File]::OpenRead($Path)
    try { $hashBytes = $sha256.ComputeHash($stream) }
    finally { $stream.Dispose() }
}
finally { $sha256.Dispose() }
$hash = ([BitConverter]::ToString($hashBytes)).Replace('-', '')
```

When to apply: any `windows-latest` workflow step that needs a file hash from
a `.ps1` script. The `.NET` path has no dependency on cmdlet auto-loading and
works identically on local Windows and CI.

### Cross-repo PR automation — credential scoping

Fine-grained PATs cannot grant write permissions on repos the user does not
own or administer. GitHub's UI restricts the per-repo permission selector to
repos the token owner has admin access to, so a fine-grained PAT is not a
viable credential for CI that needs to write to (or open PRs against) an
upstream repo.

The two remaining credentials for cross-repo CI automation are:

1. **Classic PAT** — account-wide blast radius; the token has the granted
   scopes (`repo`, `workflow`, etc.) against every repo the owner has
   access to. Acceptable only when the blast radius is acceptable.
2. **GitHub App with explicit installation on the upstream** — narrow scope,
   but requires the upstream maintainer to install the app on their repo.
   Usually impractical for casual cross-repo automation.

Neither is acceptable for casual cross-repo automation against a repo the
user does not control.

**Resolution: orchestrate cross-repo PR submission from the developer's
workstation using `gh` CLI, not from CI.** The workstation already holds a
broadly-scoped `gh` auth that the user has accepted for interactive use; CI
keeps its tightly-scoped default `GITHUB_TOKEN`. See the local-orchestrator
pattern below.

When to apply: any CI flow that proposes "PR into someone else's repo."
Stop and re-architect as a local Make target before issuing or storing a
classic PAT in CI secrets.

### Local-orchestrator pattern for cross-repo PR submission

When CI cannot get clean cross-repo write credentials (see above), implement
the submission as a Make target driven from the workstation. The shape:

1. **Make target** invokes a helper script (PowerShell on Windows, shell
   elsewhere).
2. **Read the version/identifier from the source-of-truth file** in this
   project (e.g., `Properties/AssemblyInfo.cs` for .NET,
   `pyproject.toml` for Python). Do not re-derive from git tags or release
   metadata — the source file is authoritative.
3. **Download the canonical release artifact from the just-cut GitHub
   Release** (`gh release download`). Submitting a locally-rebuilt artifact
   risks checksum drift against what was actually released; downloading the
   release artifact guarantees the submitted metadata matches the bytes
   users will install.
4. **Re-validate the artifact against the target repo's schema before
   submitting.** Catches drift between this project's manifest generator
   and the upstream schema before opening a PR.
5. **`cd` into a local clone of the target repo, verify a clean tree, hard-
   reset local `main` to the upstream remote's `main`.** Stale local state
   is the most common cause of force-pushing the wrong content; resetting
   defensively avoids it.
6. **Create a per-version branch with `git checkout -B <branch>`** so
   re-runs of the same version reuse the same branch rather than piling up
   stale branches on the fork.
7. **Drop the artifact at the target path, commit, force-push to the user's
   fork** (force-push is acceptable here because the branch is per-version
   and owned by the script).
8. **Call `gh pr create --repo <upstream> --head <fork-owner>:<branch>
   --base main`**, or report an existing open PR for the same head if one
   is already open.
9. **Use the user's existing `gh` auth** — no long-lived credentials
   anywhere, no secrets to rotate, no CI blast radius.

When to apply: any release flow that must hand a generated artifact (plugin
manifest, package index entry, registry submission) to a repo the user does
not control. Project-specific applications of the pattern live in each
project's own docs; this is the shape they share.

## Migration from individual workflows

Projects using the old per-check workflow pattern (5 separate workflows: `test-unit`,
`test-coverage`, `test-lint`, `test-format`, `test-typecheck`) should consolidate:

1. Replace `test-unit.yml` + `test-coverage.yml` with `test.yml`
2. Replace `test-lint.yml` + `test-format.yml` + `test-typecheck.yml` with `quality.yml`
3. Update branch protection rules to require `test` and `quality` instead of the old names
4. Delete the old workflow files
