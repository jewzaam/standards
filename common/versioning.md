# Versioning Standards

Semantic versioning conventions.

## Version Format

All projects use [Semantic Versioning](https://semver.org/):

```text
X.Y.Z
```

| Component | Name | Incremented When |
|-----------|------|------------------|
| `X` | Major | Breaking changes |
| `Y` | Minor | New features (backward compatible) |
| `Z` | Patch | Bug fixes, tweaks, documentation |

## What Counts as a Breaking Change

A breaking change is anything that causes existing usage to fail or produce different results.

| Change | Breaking? | Rationale |
|--------|-----------|-----------|
| Rename a CLI argument | Yes | Existing scripts and automation break |
| Remove a CLI argument | Yes | Existing scripts and automation break |
| Change a CLI argument's default value | Yes | Existing behavior changes silently |
| Change CLI exit code meanings | Yes | Scripting logic breaks |
| Change output format (stdout/stderr) | No | Output is not a stable contract |
| Add a new required CLI argument | Yes | Existing invocations fail |
| Add a new optional CLI argument | No | Existing invocations still work |
| Add a new feature behind a flag | No | No change to existing behavior |

## Integration Surface

When a project's primary integration pattern is a **command-line interface**, the CLI is the public API and the only surface covered by semver.

| Integration Method | Status | Versioning Applies? |
|--------------------|--------|---------------------|
| CLI (command-line) | Supported | Yes - CLI is the public API |
| Python module import | Not supported | No - internal, may change without notice |
| REST/HTTP API | Not yet available | TODO |

**Do not import internal modules directly when only the CLI is the supported surface.** Internal function signatures, module layout, and return types may change in any release without a major version bump. The CLI is the contract.

<!-- TODO: Define an API layer for programmatic integration. Until then, CLI is the only stable interface. -->

## Version Increment Rules

### Major (`X`) - Breaking Changes

Increment major version when the CLI contract changes in an incompatible way.

**Examples:**

- `--blink-dir` renamed to `--blink-path`
- `--no-overwrite` removed
- Default behavior of `--scale-dark` changed from off to on

### Minor (`Y`) - New Features

Increment minor version when new functionality is added without breaking existing usage.

**Examples:**

- New `--format` option added
- New subcommand added
- New output field appended (when consumers are tolerant of extra fields)
- Support for a new file type

### Patch (`Z`) - Bug Fixes and Tweaks

Increment patch version for fixes that correct behavior to match documented intent.

**Examples:**

- Fix crash on empty directory input
- Fix incorrect FITS header value extraction
- Fix `--quiet` flag not suppressing progress bars
- Documentation corrections
- Performance improvements with no behavior change

## Version Location (Python)

Version must be defined in exactly two places that must always match:

1. **`pyproject.toml`** — the packaging metadata source:

   ```toml
   [project]
   version = "0.2.0"
   ```

2. **`__version__` constant in code** — for runtime access. Place it in either
   `__init__.py` (for library packages) or the main script (for single-file tools):

   ```python
   __version__ = "0.2.0"
   ```

### Why Both

- `pyproject.toml` is read by packaging tools (`pip`, `build`, `setuptools`) but is
  not reliably accessible at runtime from installed packages without `importlib.metadata`
- `__version__` is directly importable and available for logging, `--version` flags,
  and output headers without import overhead

### Keeping Them in Sync

The `version-check` Makefile target (see [Makefile Standards](../build/makefile.md))
validates that both values match and follow semver. Run it in CI or before release.

## Automated Version Validation

The optional `version-check` Makefile target validates:

1. **Semver format** — version string matches `X.Y.Z` (no `v` prefix, no pre-release
   suffixes unless intentional)
2. **Sources match** — `pyproject.toml` version equals the `__version__` constant in code
3. **Version bumped** — version differs from the mainline branch (prevents merging
   without a version bump)

The target is a standalone `.mk` file — copy it to your project root and add a single
`-include` line. Pure shell, no Python dependency. Remove the include line to disable.
See [Makefile Standards — version-check](../build/makefile.md#version-check) for setup
and [version-check.mk](../python/templates/version-check.mk) for the implementation.

## Guidelines

1. **CLI is the public API** - Version the CLI contract, not internal code
2. **When in doubt, bump major** - A cautious major bump is better than a surprise break
3. **Reset lower components** - Bumping minor resets patch to 0; bumping major resets minor and patch to 0
4. **Tag releases** - Use git tags matching `vX.Y.Z` (e.g., `v1.2.0`). The version-check workflow auto-creates tags on push to main — no manual tagging needed
5. **Start at 0.1.0** - New projects start at `0.1.0`; the `0.x` range signals pre-stable development where breaking changes may occur in minor releases
