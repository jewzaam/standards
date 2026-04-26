# Work Standards

[![test-markdown-lint](https://github.com/jewzaam/standards/actions/workflows/test-markdown-lint.yml/badge.svg)](https://github.com/jewzaam/standards/actions/workflows/test-markdown-lint.yml)
[![test-links](https://github.com/jewzaam/standards/actions/workflows/test-links.yml/badge.svg)](https://github.com/jewzaam/standards/actions/workflows/test-links.yml)
[![test-reachability](https://github.com/jewzaam/standards/actions/workflows/test-reachability.yml/badge.svg)](https://github.com/jewzaam/standards/actions/workflows/test-reachability.yml)

Reusable software development standards. Reference these instead of recreating project-specific guidelines.

AI agents: see [CLAUDE.md](CLAUDE.md) for a flat file index optimized for tool-based lookup.

## Usage

Reference in your project:

```markdown
This project follows the [Work Standards](https://github.com/jewzaam/standards).
```

## [Common](common/README.md)

| Standard | Description |
|----------|-------------|
| [Versioning](common/versioning.md) | Semantic versioning and release conventions |
| [README Format](common/readme-format.md) | README structure and content |
| [Naming](common/naming.md) | Project and package naming conventions |
| [Git Submodules](common/submodules.md) | Git submodule conventions and workflows |
| [Git Worktrees](common/git-worktrees.md) | Worktree conventions, cleanup, AI-assisted parallel development |
| [Reachability](common/reachability.md) | Document reachability enforcement from entry points |
| [Temp Directories](common/tmp-dirs.md) | `.tmp-<slug>/` convention for named, git-ignored working directories |

## [Python](python/README.md)

| Standard | Description |
|----------|-------------|
| [Style](python/style.md) | Python coding style and best practices |
| [Project Structure](python/project-structure.md) | Directory layout and required files |
| [Testing](python/testing.md) | Unit testing conventions, TDD, and documenting untested areas |
| [Complexity](python/complexity.md) | Cyclomatic complexity limit (10), ruff C901 enforcement |
| [Subprocess Security](python/subprocess-security.md) | Subprocess and localhost server security rules |
| [Cross-Platform](python/cross-platform.md) | Making python/python3 work across Linux, macOS, Windows |
| [Shared Venv](python/shared-venv.md) | Shared `~/.venv/<family>/` for related projects, local `.venv` fallback |
| [Logging & Progress](python/logging-progress.md) | Logging, progress indicators, and output |
| [Settings Persistence](python/settings-persistence.md) | Dataclass settings with atomic JSON I/O |
| [Agent SDK Integration](python/agent-sdk.md) | Claude Agent SDK integration patterns |

### [Tkinter UI](python/tkinter/README.md)

| Standard | Description |
|----------|-------------|
| [Architecture](python/tkinter/architecture.md) | Application structure, controller pattern, window hierarchy |
| [Windows](python/tkinter/windows.md) | Window lifecycle, borderless mode, dragging, position persistence |
| [Widgets](python/tkinter/widgets.md) | Layout, StringVar, styling, fonts, context menus |
| [Threading](python/tkinter/threading.md) | Thread-safe UI updates, daemon threads, periodic polling |
| [Dialogs](python/tkinter/dialogs.md) | Modal dialogs, settings windows, color pickers |
| [Testing](python/tkinter/testing.md) | Two-layer testing strategy, root fixture, headless CI |
| [DPI Scaling](python/tkinter/dpi-scaling.md) | HiDPI detection, `tk scaling`, pixel dimension scaling |

### Python Templates

| Template | Description |
|----------|-------------|
| [Makefile](python/templates/Makefile) | Standard Makefile with all required targets |
| [pyproject.toml](python/templates/pyproject.toml) | Package config with standard dev dependencies |
| [test.mk](python/templates/test.mk) | Standard `test-*` target collection (includable `.mk`) |
| [version-check.mk](python/templates/version-check.mk) | Semver validation (includable `.mk`, optional `make version-check`) |
| [version-check.sh](python/templates/version-check.sh) | Shell script for semver validation |

## [CLI](cli/README.md)

| Standard | Description |
|----------|-------------|
| [Conventions](cli/conventions.md) | CLI argument and flag conventions |
| [Testing](cli/testing.md) | CLI entry point testing patterns |

## [Build and CI/CD](build/README.md)

| Standard | Description |
|----------|-------------|
| [Makefile](build/makefile.md) | Build targets and conventions |
| [GitHub Workflows](build/github-workflows.md) | CI/CD pipeline configuration |
| [Local Workflow Testing](build/local-workflow-testing.md) | Testing workflows locally with act |
| [Fabcheck](build/fabcheck.md) | Detect hallucinated imports and missing file references |

### Workflow Templates

| Template | Description |
|----------|-------------|
| [test.yml](build/templates/workflows/test.yml) | Run pytest with coverage (Python 3.14) |
| [quality.yml](build/templates/workflows/quality.yml) | Format check + lint + type check (Python 3.14) |
| [test-reachability.yml](build/templates/workflows/test-reachability.yml) | Verify document reachability from entry points |
| [version-check.yml](build/templates/workflows/version-check.yml) | Validate semver (optional, copy when opting in) |
| [fabcheck.yml](build/templates/workflows/fabcheck.yml) | Run fabcheck on push/PR, annotate missing findings, upload verdict |

### Build Templates

| Template | Description |
|----------|-------------|
| [fabcheck.mk](build/templates/fabcheck.mk) | Import fabrication detection (includable `.mk`, optional `make fabcheck`) |
| [fabcheck.sh](build/templates/fabcheck.sh) | Shell script for fabcheck (vendor into `scripts/`) |

## Claude Code

| Standard | Description |
|----------|-------------|
| [Skills](claude-code/skills.md) | Authoring Claude Code skills (SKILL.md files) |
| [Plugins](claude-code/plugins.md) | Plugin structure, manifest schema, marketplace distribution |
| [Hook State Transitions](claude-code/hook-state-transitions.md) | Hook event types, state machines, and configuration |
| [Agent SDK Usage Data](claude-code/agent-sdk-usage-data.md) | Extracting cost, token, context, and rate-limit data from the Agent SDK |

## Planned Sections

| Section | Description |
|---------|-------------|
| [Android](android/README.md) | Android application development standards |
| [Mobile](mobile/README.md) | Cross-platform mobile development patterns |
| [Guides](guides/README.md) | Process and tooling how-tos |

## Guiding Principles

1. **Consistency** - All projects follow the same patterns
2. **Simplicity** - Minimal configuration, sensible defaults
3. **Automation** - CI catches issues before merge
4. **Discoverability** - Standard locations for everything

## Critical Constraints

**Git LFS is prohibited**

- GitHub LFS has a $0 budget limit and is not funded
- Do not track binary files with Git LFS
- Generate test fixtures programmatically or use minimal files (< 100KB)
- Large binary files will cause CI failures and block development
