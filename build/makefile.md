# Makefile Standards

Standard Makefile targets for Python projects.

## Default Target

Running `make` without specifying a target runs the `check` target, which executes all validation steps (format, lint, typecheck, test, coverage). The `format` step applies formatting fixes automatically; use `make format-check` separately when you need a non-modifying check that exits non-zero on unformatted code (e.g., in CI workflows).

Using `check` as the named default target allows safer permissions for AI tools — instead of permitting the broad `make` command, tools can be granted permission for the specific `make check` target.

```bash
make           # Runs check target (all validations)
make check     # Same as above (explicit)
```

## Required Targets

| Target | Description |
|--------|-------------|
| `check` | Run format, lint, typecheck, test, coverage (default target) |
| `help` | Show available targets with descriptions |
| `install` | Install package |
| `install-dev` | Install in editable mode with dev deps |
| `install-no-deps` | Install in editable mode without dependencies |
| `uninstall` | Uninstall package |
| `clean` | Remove build artifacts |
| `format` | Format code with black |
| `format-check` | Check formatting without modifying files (exits non-zero if changes needed) |
| `lint` | Lint with flake8 |
| `typecheck` | Type check with mypy |
| `test` | Run pytest |
| `coverage` | Run pytest with coverage |
| `mutation` | Run mutation testing with mutmut |
| `mutation-report` | Show results of last mutation run |

## Virtual Environment

By default, projects use a local `.venv` in the project root. The `install-no-deps` target is available for cases where you need to install a package without pulling its dependencies from the network.

For `ap-*` projects that share a single venv, see [Shared Virtual Environment](../python/shared-venv.md).

## Template

Copy [templates/Makefile](../python/templates/Makefile) and [templates/pyproject.toml](../python/templates/pyproject.toml) to your project and set `PACKAGE_NAME` (Makefile) / `<package_name>` (pyproject.toml) to your Python package name (e.g., `my_tool`).

## Conventions

### VENV_DIR and PYTHON variables

`VENV_DIR` and `PYTHON` use a local `.venv` by default, with platform-appropriate paths:

```makefile
ifeq ($(OS),Windows_NT)
    VENV_DIR ?= .venv
    PYTHON := $(VENV_DIR)/Scripts/python.exe
else
    VENV_DIR ?= .venv
    PYTHON := $(VENV_DIR)/bin/python
endif
```

- **Default**: `VENV_DIR` resolves to `.venv` (local)
- **Override**: `make VENV_DIR=/path/to/venv test` always works

Do not hardcode `python` or `python3` in targets — always use `$(PYTHON)`.

### PACKAGE_NAME variable

`PACKAGE_NAME` is the Python package directory name (the importable name, e.g., `my_tool`). All targets that operate on source code use this variable:

```makefile
PACKAGE_NAME ?= my_tool
```

This single variable drives format, lint, typecheck, coverage, and mutation targets. Declare it at the top of the Makefile before any other variables.

All variables (`PYTHON`, `PACKAGE_NAME`, `LOG_FILE`, etc.) must be declared at the top of the Makefile, before the first target. This keeps configuration visible and easy to override.

### Venv creation target

The venv is created automatically as a Make prerequisite. Make only runs this if `$(PYTHON)` does not exist:

```makefile
$(PYTHON):
	python3 -m venv $(VENV_DIR)
```

### Dependencies

Targets that need the package installed should depend on `install-dev`, which itself depends on the venv existing. Targets that use `$(PYTHON)` but don't need packages installed (e.g., `links`, `install`, `uninstall`, `mutation-report`, `run`) should depend on `$(PYTHON)` directly:

```makefile
install-dev: $(PYTHON)
	$(PYTHON) -m pip install -e ".[dev]"

format: install-dev
	$(PYTHON) -m black $(PACKAGE_NAME) tests

links: $(PYTHON)
	$(PYTHON) scripts/check-links.py
```

### format vs format-check

`format` applies black formatting in-place — safe for local development and used by `make check`. `format-check` runs `black --check` which exits non-zero if any file would be reformatted, without modifying files. Use `format-check` in CI workflows where you want to fail the build on unformatted code.

```makefile
format: install-dev
	$(PYTHON) -m black $(PACKAGE_NAME) tests

format-check: install-dev
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

### Mutation testing

[mutmut](https://github.com/boxed/mutmut) verifies test suite quality by injecting
small faults into source code and checking whether tests detect them. A test suite
can achieve 100% code coverage but catch almost none of the actual bugs — mutation
testing reveals this gap.

`mutation` is **not** part of `check` — mutation testing is computationally expensive
(each mutant requires a test run) and is best run in CI or on-demand locally.

```makefile
mutation: install-dev  ## Run mutation testing
	$(PYTHON) -m mutmut run --CI --paths-to-mutate "$(PACKAGE_NAME)"

mutation-report:  ## Show results of last mutation run
	$(PYTHON) -m mutmut results
```

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

Optional targets are implemented as standalone `.mk` files in a `make/` directory
at the project root. Each `.mk` file is self-contained and included into the main
Makefile with `-include`. This keeps the root directory clean and optional
functionality modular.

Targets defined in included `.mk` files automatically appear in `make help` output
because the help target uses `$(MAKEFILE_LIST)`, which includes all loaded files.

### `make/` directory structure

```
project-root/
├── Makefile
└── make/
    ├── pipx.mk
    ├── run.mk
    └── version-check.mk
```

Include optional targets in your Makefile:

```makefile
-include make/pipx.mk
-include make/run.mk
-include make/version-check.mk
```

### `run`

For applications (as opposed to libraries), provide a `run` target that starts the
app with `--log-file` pointing to a stable location. Use a `LOG_FILE` variable at
the top of the `.mk` file and echo the path so the user knows where logs land.
Support `DEBUG=1` to enable debug logging.

Create `make/run.mk` with project-specific values:

```makefile
LOG_FILE := ~/.claude/my-app/app.log

run: $(PYTHON) ## Start the app (use DEBUG=1 for debug logging)
	@echo "Logging to $(LOG_FILE)"
	$(PYTHON) -m my_app $(if $(DEBUG),--debug) --log-file $(LOG_FILE)
```

There is no template for `run.mk` — the module name, log path, and flags are
entirely project-specific. The pattern above is the reference.

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

To remove: delete the `-include` line (or comment it out) and remove the `.mk` file
and workflow.

See [Versioning Standards](../common/versioning.md) for the full version location
convention.

### `pipx`

For projects that provide CLI entry points (defined in `[project.scripts]` in
`pyproject.toml`), `pipx` installs the package into an isolated global environment
and puts commands on PATH. This is the standard way to install CLI tools for
day-to-day use without polluting the system site-packages or the project venv.

Create `make/pipx.mk`:

```makefile
.PHONY: pipx pipx-uninstall

# Distribution name from [project] name in pyproject.toml.
# May differ from PACKAGE_NAME (Python module) — e.g., my-tool vs my_tool.
PROJECT_NAME ?= $(PACKAGE_NAME)

pipx:  ## Install globally via pipx
	python3 -m pipx install .

pipx-uninstall:  ## Uninstall global pipx install
	python3 -m pipx uninstall $(PROJECT_NAME)
```

`PROJECT_NAME` defaults to `PACKAGE_NAME` but can be overridden when the
distribution name differs from the module name (hyphens vs underscores). pipx
tracks packages by distribution name, not module name.

Use `python3 -m pipx` rather than bare `pipx` — the command may not be on PATH
even when the module is installed.

Include in your Makefile:

```makefile
-include make/pipx.mk
```

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
| `check` | Run markdown-lint and links (default target) |
| `install-dev` | Install dev deps from pyproject.toml |
| `markdown-lint` | Lint markdown with pymarkdown |
| `links` | Validate local markdown links and anchors |
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

.PHONY: all check install-dev markdown-lint links help

all: check

check: markdown-lint links

install-dev:
	$(PYTHON) -m pip install --quiet -e '.[dev]'

markdown-lint: install-dev
	$(PYTHON) -m pymarkdown --disable-rules MD013,MD024,MD031,MD036 scan .

links: $(PYTHON)
	$(PYTHON) scripts/check-links.py

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
requires-python = ">=3.11"

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
