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

## Virtual Environment

By default, projects use a local `.venv` in the project root. The `install-no-deps` target is available for cases where you need to install a package without pulling its dependencies from the network.

For `ap-*` projects that share a single venv, see [Shared Virtual Environment](../python/shared-venv.md).

## Template

Copy [templates/Makefile](../python/templates/Makefile) to your project and replace `<name>` with your project name.

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

All variables (`PYTHON`, `LOG_FILE`, etc.) must be declared at the top of the Makefile, before the first target. This keeps configuration visible and easy to override.

### Venv creation target

The venv is created automatically as a Make prerequisite. Make only runs this if `$(PYTHON)` does not exist:

```makefile
$(PYTHON):
	python3 -m venv $(VENV_DIR)
```

### Dependencies

Targets that need the package installed should depend on `install-dev`, which itself depends on the venv existing:

```makefile
install-dev: $(PYTHON)
	$(PYTHON) -m pip install -e ".[dev]"

format: install-dev
	$(PYTHON) -m black ap_<name> tests
```

### format vs format-check

`format` applies black formatting in-place — safe for local development and used by `make check`. `format-check` runs `black --check` which exits non-zero if any file would be reformatted, without modifying files. Use `format-check` in CI workflows where you want to fail the build on unformatted code.

```makefile
format: install-dev
	$(PYTHON) -m black ap_<name> tests

format-check: install-dev
	$(PYTHON) -m black --check ap_<name> tests
```

### Self-documenting help target

The `help` target greps for `## ` comments on target lines and prints a formatted list. Every target that should appear in `make help` output must have a `## description` comment on its rule line:

```makefile
format: install-dev  ## Format code with black
	$(PYTHON) -m black ap_<name> tests

help:  ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
```

Targets without `## ` comments (like the `$(PYTHON)` venv-creation target) are intentionally hidden from help output.

### Quiet failures in clean

Use `|| true` for commands that might fail during cleanup:

```makefile
find . -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true
```

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
    ├── run.mk
    └── version-check.mk
```

Include optional targets in your Makefile:

```makefile
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

run: ## Start the app (use DEBUG=1 for debug logging)
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

## What to Avoid

- Complex shell logic
- Platform-specific commands without fallbacks
- Hardcoded paths
- Targets that modify git state
