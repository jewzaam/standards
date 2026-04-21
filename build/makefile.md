# Makefile Standards

Standard Makefile targets for Python projects.

## Naming Grammar

Every target name follows **verb‑[qualifier‑]noun**:

- **verb:** `install` | `uninstall` | `run` | `test`
- **qualifier (optional):** a mode or scope word (e.g. `dev`, `autostart`)
- **noun:** the subsystem being acted on (e.g. `hooks`, `service`, `tray`,
  `pipx`). For `test-*` the noun is the kind of test (`unit`, `lint`, etc.).

The whitelist of unprefixed / standalone targets is small and exhaustive:

| Target | Why exempt |
|---|---|
| `help` | Listing targets has no noun. |
| `check` | Runs the full quality gate; "noun" is the whole repo. |
| `clean` | Removes build artefacts; negates the build, not a subsystem. |
| `format` | Rewrites source in place. The only source-mutating target. Idiomatic. |
| `install` | Installs everything for end-user use (project-mutated; see below). |
| `uninstall` | Inverse of `install`. |
| `run` | Runs every process in normal usage (apps only). |

Because every other target carries a verb prefix, alphabetic sort already groups
related targets in `make help` — no section headers are required.

### `.mk` files are noun-based

Optional / non-common targets live in `make/<noun>.mk` fragments included by the
root Makefile. **Each fragment is named after a subsystem (a noun)**, never
after a verb. So `make/tray.mk`, `make/service.mk`, `make/hooks.mk` are correct;
`make/autostart.mk` and `make/install.mk` are not — `autostart` and `install`
are qualifiers/verbs that span multiple subsystems.

Targets inside a noun fragment carry the full prefix grammar:

```makefile
# make/tray.mk
run-tray:                  ## Start tray icon in the foreground
install-autostart-tray:    ## Enable tray auto-start on login
uninstall-autostart-tray:  ## Disable tray auto-start
```

The exception is `make/test.mk` — the `test-*` collection is verb-based and
common enough to warrant its own fragment for readability. The user is
expected to know this is the one allowed verb-named fragment; it keeps the root
Makefile uncluttered.

### `install`, `uninstall`, `run` are project-specific composites

The standard template ships `install` as the venv install. App projects with
multiple subsystems (hooks, autostart, tray, etc.) **mutate** `install` in their
root Makefile to mean "install everything the end-user needs", composing
`install-pipx` + `install-<noun>` targets. The same applies to `uninstall` and
`run`.

```makefile
# Root Makefile in a project with hooks + service autostart:
install: install-pipx install-hooks install-autostart-service
uninstall: uninstall-autostart-service uninstall-hooks uninstall-pipx
run: $(PYTHON)
	@$(PYTHON) -m my_app.tray --config $(CONFIG_FILE) & \
	 trap 'kill %1 2>/dev/null || true' EXIT; \
	 $(PYTHON) -m my_app --config $(CONFIG_FILE)
```

To target a single subsystem the user calls it explicitly:
`make install-hooks`, `make run-tray`, etc. There is no `install-all` /
`uninstall-all` / `run-all` — the bare verbs serve that role.

`install-dev` (editable venv for development) is orthogonal to `install` and
remains a standard target.

## Default Target

Running `make` without arguments runs the `check` target, which executes
`test-format`, `test-lint`, `test-typecheck`, `test-unit`, `test-coverage`.
Each step is read-only — none rewrite source. Use `make format` separately to
apply formatting fixes.

Using `check` as the named default allows safer permissions for AI tools —
instead of permitting the broad `make` command, tools can be granted permission
for the specific `make check` target.

```bash
make           # Runs check (all validations)
make check     # Same as above (explicit)
```

## Required Targets

### Utility (whitelist)

| Target | Description |
|--------|-------------|
| `help` | Show available targets with descriptions |
| `check` | Run full quality gate (default target) |
| `clean` | Remove build artifacts |
| `format` | Rewrite sources with black |

### `test-*`

| Target | Description |
|--------|-------------|
| `test-unit` | Run pytest |
| `test-coverage` | Run pytest with coverage threshold |
| `test-format` | Check formatting (exits non-zero if changes needed) |
| `test-lint` | Lint with flake8 |
| `test-typecheck` | Type check with mypy |
| `test-complexity` | Check cyclomatic complexity with xenon (opt-in) |
| `test-mutation` | Run mutation testing with mutmut (opt-in) |
| `test-reachability` | Verify all content files are reachable from entry points (doc projects) |

### `install-*` / `uninstall-*`

| Target | Description |
|--------|-------------|
| `install` | Install everything for end-user use (project-mutated composite — see "Naming Grammar" above). |
| `install-dev` | Editable install + dev extras (for local development; orthogonal to `install`). |
| `install-pipx` | Install globally via pipx. |
| `uninstall` | Inverse of `install`. |
| `uninstall-pipx` | Uninstall the pipx install. |

App-style projects (with subsystems like hooks, autostart, etc.) add their own
`install-<noun>` / `uninstall-<noun>` pairs in `make/<noun>.mk` fragments and
compose them into `install` / `uninstall` in the root Makefile. Every
`install-X` should have a matching `uninstall-X` unless it's been deliberately
decided to skip.

### `run-*` (apps only)

| Target | Description |
|--------|-------------|
| `run` | Run every process in normal usage (project-mutated composite). |
| `run-<noun>` | Start the named subsystem in the foreground. |

For single-process apps `run` and `run-<service>` may be the same recipe; for
multi-process apps `run` orchestrates the subsystem `run-*` targets (typically
foreground + background under a trap so Ctrl-C cleans them up).

## Virtual Environment

By default, projects use a local `.venv` in the project root.

For `ap-*` projects that share a single venv, see [Shared Virtual Environment](../python/shared-venv.md).

## Template

Copy [templates/Makefile](../python/templates/Makefile) and [templates/pyproject.toml](../python/templates/pyproject.toml) to your project and set `PACKAGE_NAME` (Makefile) / `<package_name>` (pyproject.toml) to your Python package name (e.g., `my_tool`).

## Conventions

### Variables and venv creation

See [templates/Makefile](../python/templates/Makefile) for the canonical variable declarations, platform split, and venv creation target. Key points:

- All variables use `?=` so callers can override from the command line or environment
- Do not hardcode `python` or `python3` in targets — always use `$(PYTHON)`
- `python3` works on all platforms via [cross-platform shims](../python/cross-platform.md)
- All variables must be declared at the top of the Makefile, before the first target

### Pinning the venv interpreter (`PY_SYS`)

The venv-creation target uses `$(PY_SYS) -m venv $(VENV_DIR)`, where `PY_SYS` defaults to `python3`. CI overrides `PY_SYS=python` to pin the venv to the matrix Python installed by `actions/setup-python`.

**Why this matters:** `setup-python` prepends its install to `PATH` and creates a stable `python` symlink pointing at the matrix version, but `python3` is not always rebound. On hosted `ubuntu-latest` runners this usually works for `python3` too; under [act](local-workflow-testing.md) with `catthehacker/ubuntu:act-22.04`, the container ships Python 3.11 as the default `python3` and `setup-python` only adjusts `python`. A matrix leg running Python 3.12+ then falls back to 3.11 when `make install-dev` runs `python3 -m venv .venv`, producing a 3.11 venv. `pip install -e ".[dev]"` subsequently fails with `requires-python >=3.12`.

`python` is the safe choice in CI because `setup-python` always rebinds it; `python3` is the safe local default because distro Pythons ship it but not the unversioned `python`. Using `PY_SYS` as a variable keeps both paths clean without duplicating targets.

The variable only governs venv *creation* — all other targets invoke `$(PYTHON)` (the venv interpreter), so once the venv exists the matrix version is baked in.

### Dependencies

Targets that need the package installed should depend on `install-dev`, which itself depends on the venv existing. Targets that use `$(PYTHON)` but don't need packages installed (e.g., `install`, `uninstall`, `run-*`) should depend on `$(PYTHON)` directly.

### `format` vs `test-format`

`format` applies black formatting in-place — safe for local development. `test-format` runs `black --check` which exits non-zero if any file would be reformatted, without modifying files. `check` depends on `test-format` (read-only); CI workflows do too.

```makefile
format: install-dev  ## Rewrite sources with black
	$(PYTHON) -m black $(PACKAGE_NAME) tests

test-format: install-dev  ## Check formatting (exits non-zero if changes needed)
	$(PYTHON) -m black --check $(PACKAGE_NAME) tests
```

### Self-documenting help target

The `help` target greps for `## ` comments on target lines and prints a formatted list. Every target that should appear in `make help` output must have a `## description` comment on its rule line:

```makefile
format: install-dev  ## Format code with black
	$(PYTHON) -m black $(PACKAGE_NAME) tests

help:  ## Show available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
```

The `-h` flag on grep suppresses filename prefixes when `$(MAKEFILE_LIST)` contains
multiple files (e.g., from `-include make/*.mk`). Without it, the awk field split
breaks and prints filenames instead of target names.

Targets without `## ` comments (like the `$(PYTHON)` venv-creation target) are intentionally hidden from help output.

### Quiet failures in clean

Use `|| true` for commands that might fail during cleanup:

```makefile
find . -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true
```

### Complexity checking

[xenon](https://github.com/rubik/xenon) enforces cyclomatic complexity thresholds
at the Makefile level. It wraps [radon](https://github.com/rubik/radon) and exits
non-zero when any module, function, or average exceeds the configured grade.

`test-complexity` is **not** part of `check` — it's a separate validation step,
similar to mutation testing. Run it on-demand or in CI.

```makefile
test-complexity: install-dev  ## Cyclomatic complexity check (xenon)
	$(PYTHON) -m xenon $(PACKAGE_NAME) --max-absolute B --max-modules B --max-average A
```

Grades: A (low risk, CC 1-5), B (moderate, CC 6-10), C (high, CC 11-15). The
thresholds above (`--max-absolute B --max-modules B --max-average A`) match the
[complexity standard](../python/complexity.md) limit of CC ≤ 10.

See [Cyclomatic Complexity](../python/complexity.md) for refactoring patterns when
functions exceed the limit.

### Reachability

Every project with a `CLAUDE.md` should include the `test-reachability` target
as part of `check`. This ensures all content files remain discoverable from
entry points. See [Document Reachability](../common/reachability.md) for the
full standard.

```makefile
test-reachability:  ## Verify all files are reachable from entry points
	@echo "Checking document reachability..."
	$(PYTHON) scripts/reachability.py --check
```

The script only requires Python stdlib — no extra dependencies. Include
`test-reachability` in the `check` target prerequisites.

### Mutation testing

[mutmut](https://github.com/boxed/mutmut) verifies test suite quality by injecting
small faults into source code and checking whether tests detect them. A test suite
can achieve 100% code coverage but catch almost none of the actual bugs — mutation
testing reveals this gap.

`test-mutation` is **not** part of `check` — mutation testing is
computationally expensive (each mutant requires a test run) and is best run in
CI or on-demand locally.

```makefile
test-mutation: install-dev  ## Run mutation testing
	$(PYTHON) -m mutmut run --CI --paths-to-mutate "$(PACKAGE_NAME)"
```

A separate "show results" target is intentionally not part of the standard —
`python -m mutmut results` is short enough to run directly when needed.

**Use mutmut 2.x** (`mutmut>=2.0,<3.0`). mutmut 3.x has a [decorator bug (#387)](https://github.com/boxed/mutmut/issues/387)
that skips ALL decorated functions and classes — `@staticmethod`, `@classmethod`, `@property`,
`@dataclass`, etc. are all silently excluded. This makes 3.x unusable for most real codebases.
mutmut 3.x also has a [`set_start_method` bug (#466)](https://github.com/boxed/mutmut/issues/466)
on Python 3.12+ when invoked via `python -m`.

mutmut 2.x is slower (no parallelization, one test run per mutant) but actually mutates
decorated code. The `--CI` flag makes mutmut return 0 for all non-fatal runs (surviving
mutants return 0, not 2).

**Platform constraint:** mutmut requires `fork()` — Linux, macOS, and WSL only. It
does not run on native Windows.

#### Configuration

Add `[tool.mutmut]` to `pyproject.toml` for projects that need non-default settings:

```toml
[tool.mutmut]
paths_to_mutate = ["<package_name>/"]
also_copy = ["conftest.py"]
pytest_add_cli_args = ["-p", "no:asyncio", "-p", "no:anyio"]
```

- **`also_copy`** — files mutmut needs alongside the mutated source (fixtures,
  test config). Without this, mutation runs fail when conftest or pytest config
  is missing.
- **`pytest_add_cli_args`** — disable pytest plugins that conflict with mutmut's
  subprocess model. `asyncio` and `anyio` plugins are common offenders.

#### Python 3.13+ workaround

mutmut 2.x calls `set_start_method('fork')` without `force=True` at module
import time. Python 3.13+ locks the multiprocessing context on the first
`get_start_method()` call, causing a `RuntimeError`. Add this workaround to
`conftest.py`:

```python
import multiprocessing

_orig = multiprocessing.set_start_method

def _patched(method, force=False):
    _orig(method, force=True)

multiprocessing.set_start_method = _patched
```

#### CI performance

Mutation testing is slow — expect 1-2 hours for a mid-size project (250+ tests,
20+ source files). Since the workflow runs post-merge, use `concurrency` with
`cancel-in-progress: true` in the GitHub workflow to avoid queueing stale runs
during rapid-fire merges. See [GitHub Workflows — Mutation Testing](github-workflows.md#mutation-testing).

### Line length

Match black's default of 88 characters:

```makefile
--max-line-length=88
```

## Optional Targets

Optional / non-common targets are implemented as standalone `.mk` files in a
`make/` directory at the project root. Each `.mk` file is self-contained and
included into the main Makefile with `-include`. This keeps the root directory
clean and optional functionality modular.

Targets defined in included `.mk` files automatically appear in `make help` output
because the help target uses `$(MAKEFILE_LIST)`, which includes all loaded files.

### `make/` directory structure

Each fragment is named after a **subsystem (a noun)**, never after a verb. The
sole exception is `make/test.mk`, which holds the standard `test-*` collection
to keep the root Makefile uncluttered.

```
project-root/
├── Makefile
└── make/
    ├── hooks.mk          # noun: hooks      → install-hooks, uninstall-hooks
    ├── service.mk        # noun: service    → run-service, install-autostart-service
    ├── tray.mk           # noun: tray       → run-tray, install-autostart-tray
    ├── test.mk           # exception: test-* targets
    └── version-check.mk
```

Include fragments in the Makefile. `-include` lines can go at the top, before
variable definitions — Make expands variables in rules and prerequisites after
all files are parsed, so included `.mk` files can reference `$(PYTHON)` and
other variables defined later in the main Makefile:

```makefile
-include make/hooks.mk
-include make/service.mk
-include make/tray.mk
-include make/test.mk
-include make/version-check.mk
```

### `run-*`

For applications (as opposed to libraries), each subsystem `.mk` file owns its
own `run-<noun>` target. There is no `make/run.mk` — `run-service` lives in
`make/service.mk`, `run-tray` lives in `make/tray.mk`, etc.

```makefile
# make/service.mk
run-service: $(PYTHON) ## Start service in the foreground
	$(PYTHON) -m my_app --config $(CONFIG_FILE)

# make/tray.mk
run-tray: $(PYTHON) ## Start tray icon in the foreground
	$(PYTHON) -m my_app.tray --config $(CONFIG_FILE)
```

The bare `run` target lives in the root Makefile and is project-specific —
typically backgrounding all but one process under a trap:

```makefile
# Root Makefile (project-mutated)
CONFIG_FILE ?= ~/.claude/my-app/config.json

run: $(PYTHON)  ## Run service + tray (Ctrl-C exits both)
	@$(PYTHON) -m my_app.tray --config $(CONFIG_FILE) & \
	 trap 'kill %1 2>/dev/null || true' EXIT; \
	 $(PYTHON) -m my_app --config $(CONFIG_FILE)
```

Single-process apps simply have `run` invoke the lone `run-<service>` target.

### `version-check`

Validates semantic versioning compliance. This target is **opt-in** — add it to
projects that enforce semver. It is not part of `check` by default because not all
projects use semver enforcement.

The target is implemented as a standalone `.mk` file
([version-check.mk](../python/templates/version-check.mk)) that gets included into
your Makefile. Pure shell (grep/sed/git) — no Python dependency. It checks:

1. **Semver format** — `pyproject.toml` version matches `X.Y.Z`
2. **Sources match** — `pyproject.toml` version equals `__version__` in code
3. **Version bumped** — version differs from the mainline branch (`main` or `master`)

The bump check uses `git merge-base` to find the common ancestor with mainline and
compares the `pyproject.toml` version at that point against the current version.
This works correctly for both feature branches and direct mainline commits.

### Opting In

1. Copy [version-check.mk](../python/templates/version-check.mk) to `make/` in your project
2. Add to your Makefile:

   ```makefile
   VERSION_FILE ?= my_package/__init__.py
   VERSION_DIRS ?= my_package/ scripts/
   -include make/version-check.mk
   ```

3. Copy [version-check.yml](templates/workflows/version-check.yml) to
   `.github/workflows/` for CI enforcement
4. Optionally configure as a required status check on the GitHub repo for PRs

### Configuration

| Variable | Purpose | Default |
|----------|---------|---------|
| `VERSION_FILE` | File containing `__version__` (empty to skip consistency check) | empty |
| `VERSION_DIRS` | Space-separated dirs that require a version bump when changed | empty |

When `VERSION_DIRS` is set, the bump check only fires if files in those directories
changed vs mainline. Changes to docs, tests, workflows, or other non-source files
are ignored. When `VERSION_DIRS` is empty, any change triggers the bump check.

`version-check` is **not** part of the `check` target — it runs in CI via the
workflow, not locally on every `make`. This avoids penalizing local iteration speed
with git operations on every build.

### Auto-Tagging

The version-check workflow includes an `auto-tag` job that runs on push to
main (not on PRs). After version-check passes, it reads the version from
`pyproject.toml` and creates a `vX.Y.Z` git tag if one doesn't already exist.

This works with rebase-merge workflows — tags are created on the mainline
commit after merge, not on the feature branch commit that gets rewritten.
The job requires `contents: write` permission.

Consumers can pin to a version tag:

```
pip install git+https://github.com/user/repo.git@v0.3.5
```

To remove: delete the `-include` line (or comment it out) and remove the `.mk` file
and workflow.

See [Versioning Standards](../common/versioning.md) for the full version location
convention.

### `install-pipx` / `uninstall-pipx`

For projects that provide CLI entry points (defined in `[project.scripts]` in
`pyproject.toml`), `install-pipx` installs the package into an isolated global
environment and puts commands on PATH. This is the standard way to install CLI
tools for day-to-day use without polluting the system site-packages or the
project venv.

`install-pipx` / `uninstall-pipx` live directly in the **root Makefile**
alongside `install` / `install-dev` / `uninstall` — pipx is standard enough that
it doesn't warrant its own `.mk` fragment:

```makefile
PROJECT_NAME ?= $(PACKAGE_NAME)

install-pipx:  ## Install globally via pipx
	python3 -m pipx install . --force

uninstall-pipx:  ## Uninstall the pipx install
	python3 -m pipx uninstall $(PROJECT_NAME)
```

`PROJECT_NAME` defaults to `PACKAGE_NAME` but can be overridden when the
distribution name differs from the module name (hyphens vs underscores). pipx
tracks packages by distribution name, not module name.

Use `python3 -m pipx` rather than bare `pipx` — the command may not be on PATH
even when the module is installed.

Library projects with no CLI entry points can delete these two targets from
their root Makefile.

**When to use:** Projects that define CLI commands other tools or skills invoke by
name (e.g., `meet-summarize-query`). Not needed for libraries or projects only used
via `python -m`.

**Prerequisite:** pipx must be installed (`python3 -m pip install --user pipx`).

## Documentation-Only Projects

For repos that contain only markdown (no Python source code), use a simplified
Makefile with two targets: `markdown-lint` and `links`.

### Targets

| Target | Description |
|--------|-------------|
| `check` | Run test-markdown, test-links, and test-reachability (default target) |
| `install-dev` | Install dev deps from pyproject.toml |
| `test-markdown` | Lint markdown with pymarkdown |
| `test-links` | Validate local markdown links and anchors |
| `test-reachability` | Verify all files are reachable from entry points |
| `help` | Show available targets |

### Link Checker

Use `scripts/check-links.py` — a zero-dependency script (stdlib only) that
checks local file links and heading anchors in markdown files. It does **not**
check external URLs. This avoids pulling in third-party dependencies for a
narrow, stable task.

The script:
- Finds all `.md` files recursively (excluding `.git/`)
- Checks `[text](relative/path.md)` — does the file exist?
- Checks `[text](relative/path.md#anchor)` — does the heading exist?
- Checks `[text](#anchor)` — does the heading exist in current file?
- Converts headings to GitHub-style anchor slugs
- Skips external URLs, glob patterns, and `...` literals
- Exits 1 with file:line report on broken links

Copy `scripts/check-links.py` from the standards repo into your project.

### Template

```makefile
PYTHON := python

.PHONY: all check install-dev test-markdown test-links test-reachability help

all: check

check: test-markdown test-links test-reachability

install-dev:
	$(PYTHON) -m pip install --quiet -e '.[dev]'

test-markdown: install-dev
	$(PYTHON) -m pymarkdown --disable-rules MD013,MD024,MD031,MD036 scan .

test-links: $(PYTHON)
	$(PYTHON) scripts/check-links.py

test-reachability:
	@echo "Checking document reachability..."
	$(PYTHON) scripts/reachability.py --check

help:
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := all
```

### pyproject.toml

```toml
[project]
name = "my-docs-repo"
version = "0.1.0"
requires-python = ">=3.12"

[project.optional-dependencies]
dev = [
    "pymarkdownlnt>=0.9.36,<1.0",
]
```

### GitHub Workflows

Use the same `markdown-lint.yml` and `links.yml` workflow templates as Python
projects — they both just call `make <target>`.

## What to Avoid

- Complex shell logic
- Platform-specific commands without fallbacks
- Hardcoded paths
- Targets that modify git state
