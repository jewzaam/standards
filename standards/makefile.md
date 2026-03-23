# Makefile Standards

Standard Makefile targets for ap-* Python projects.

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

## Shared Venv

All ap-* projects share a single venv at `~/.venv/ap/`. See [Shared Virtual Environment](shared-venv.md) for the full standard.

One-time setup:

```bash
python3 -m venv ~/.venv/ap
```

Then cd into any repo and run make as usual:

```bash
cd ap-common
make install-dev        # Detects ~/.venv/ap, installs there

cd ../ap-cull-light
make install-dev        # Same shared venv
make test               # Uses ~/.venv/ap automatically
```

The auto-detection uses `$(wildcard $(HOME)/.venv/ap/bin/python)` in each Makefile. If the shared venv does not exist (CI, new machine), it falls back to a local `.venv`.

The `install-no-deps` target is still available for cases where you need to install a package without pulling its dependencies from the network.

## Template

Copy [templates/Makefile](templates/Makefile) to your project and replace `<name>` with your project name.

## Conventions

### VENV_DIR and PYTHON variables

`VENV_DIR` and `PYTHON` auto-detect the shared venv at `~/.venv/ap` or fall back to a local one, with platform-appropriate paths:

```makefile
HOME_DIR := $(subst \,/,$(HOME))

ifeq ($(OS),Windows_NT)
    VENV_DIR ?= $(if $(wildcard $(HOME_DIR)/.venv/ap/Scripts/python.exe),$(HOME_DIR)/.venv/ap,.venv)
    PYTHON := $(VENV_DIR)/Scripts/python.exe
else
    VENV_DIR ?= $(if $(wildcard $(HOME_DIR)/.venv/ap/bin/python),$(HOME_DIR)/.venv/ap,.venv)
    PYTHON := $(VENV_DIR)/bin/python
endif
```

`HOME_DIR` normalizes backslashes to forward slashes so paths work in both Windows shells and Unix.

- **Shared venv exists**: `VENV_DIR` resolves to `~/.venv/ap`
- **No shared venv**: `VENV_DIR` resolves to `.venv` (local)
- **Override**: `make VENV_DIR=.venv test` always works

Do not hardcode `python` or `python3` in targets - always use `$(PYTHON)`.

See [Shared Virtual Environment](shared-venv.md) for full details.

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

## What to Avoid

- Complex shell logic
- Platform-specific commands without fallbacks
- Hardcoded paths
- Targets that modify git state
