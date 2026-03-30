# Standards Repository

This repo contains reusable software development standards. It is referenced by
other projects via `~/source/standards/` in the user's global CLAUDE.md.

## How to use this index

When a project references these standards, find the right file by **topic**, not
by directory. The sections below map common questions to the authoritative file.

## Starting a new project

- [common/naming.md](common/naming.md) — repo names, package names, module names
- [python/project-structure.md](python/project-structure.md) — directory layout, required files
- [python/templates/Makefile](python/templates/Makefile) — copy this, set `PACKAGE_NAME`
- [python/templates/pyproject.toml](python/templates/pyproject.toml) — copy this, set `<package_name>`
- [common/versioning.md](common/versioning.md) — start at 0.1.0, semver rules

## Build and Makefile

- [build/makefile.md](build/makefile.md) — all Makefile conventions: required targets, `PACKAGE_NAME`, `VENV_DIR`, `PYTHON`, mutation testing, format vs format-check, help target, optional targets (`run`, `version-check`)
- [python/templates/Makefile](python/templates/Makefile) — the template to copy
- [python/templates/version-check.mk](python/templates/version-check.mk) — opt-in semver validation

## CI/CD and GitHub workflows

- [build/github-workflows.md](build/github-workflows.md) — workflow conventions, Python versions, triggers
- [build/templates/workflows/](build/templates/workflows/) — workflow templates to copy:
  - `test.yml` — pytest on Python 3.11-3.14
  - `lint.yml` — flake8
  - `typecheck.yml` — mypy
  - `format.yml` — black --check
  - `coverage.yml` — 80% threshold
  - `mutation.yml` — mutmut
  - `version-check.yml` — semver validation (optional)

## Python style and patterns

- [python/style.md](python/style.md) — coding style, imports, type hints
- [python/logging-progress.md](python/logging-progress.md) — logger setup, `--log-file`, progress bars
- [python/settings-persistence.md](python/settings-persistence.md) — dataclass settings with JSON I/O
- [python/testing.md](python/testing.md) — pytest conventions, TDD, TEST_PLAN.md

## CLI conventions

- [cli/conventions.md](cli/conventions.md) — argument naming, flags, `--log-file`, `--debug`
- [cli/testing.md](cli/testing.md) — testing main() with sys.argv patching

## Naming and versioning

- [common/naming.md](common/naming.md) — naming taxonomy for repos, packages, modules, variables
- [common/versioning.md](common/versioning.md) — semver, version location in pyproject.toml and code
- [common/readme-format.md](common/readme-format.md) — README structure, badges, descriptions

## Virtual environments

- [python/shared-venv.md](python/shared-venv.md) — shared `~/.venv/ap/` for ap-* projects only
- [build/makefile.md](build/makefile.md) — `VENV_DIR` auto-detection (general projects use local `.venv`)

## Tkinter UI

- [python/tkinter/architecture.md](python/tkinter/architecture.md) — app structure, controller pattern
- [python/tkinter/windows.md](python/tkinter/windows.md) — window lifecycle, borderless, position persistence
- [python/tkinter/widgets.md](python/tkinter/widgets.md) — layout, StringVar, styling, context menus
- [python/tkinter/threading.md](python/tkinter/threading.md) — thread-safe UI updates
- [python/tkinter/dialogs.md](python/tkinter/dialogs.md) — modal dialogs, settings windows

## Mutation testing

- [build/makefile.md](build/makefile.md) — `mutation` and `mutation-report` targets, mutmut 2.x rationale
- [python/templates/pyproject.toml](python/templates/pyproject.toml) — mutmut pinned to `>=2.0,<3.0`
- [build/templates/workflows/mutation.yml](build/templates/workflows/mutation.yml) — CI workflow

## Git

- [common/submodules.md](common/submodules.md) — submodule conventions and workflows

## Templates (copy to new projects)

- [python/templates/Makefile](python/templates/Makefile) — Makefile with all standard targets
- [python/templates/pyproject.toml](python/templates/pyproject.toml) — package config with dev deps
- [python/templates/TEST_PLAN.md](python/templates/TEST_PLAN.md) — testing strategy doc
- [python/templates/version-check.mk](python/templates/version-check.mk) — semver validation make target
- [build/templates/workflows/](build/templates/workflows/) — GitHub Actions workflow files
