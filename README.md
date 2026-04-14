# Work Standards

[![Markdown Lint](https://github.com/jewzaam/standards/actions/workflows/markdown-lint.yml/badge.svg)](https://github.com/jewzaam/standards/actions/workflows/markdown-lint.yml)
[![Validate Links](https://github.com/jewzaam/standards/actions/workflows/links.yml/badge.svg)](https://github.com/jewzaam/standards/actions/workflows/links.yml)
[![Reachability](https://github.com/jewzaam/standards/actions/workflows/reachability.yml/badge.svg)](https://github.com/jewzaam/standards/actions/workflows/reachability.yml)

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

## [Python](python/README.md)

| Standard | Description |
|----------|-------------|
| [Style](python/style.md) | Python coding style and best practices |
| [Project Structure](python/project-structure.md) | Directory layout and required files |
| [Testing](python/testing.md) | Unit testing conventions, TDD, and TEST_PLAN.md requirements |
| [Complexity](python/complexity.md) | Cyclomatic complexity limit (10), ruff C901 enforcement |
| [Subprocess Security](python/subprocess-security.md) | Subprocess and localhost server security rules |
| [Cross-Platform](python/cross-platform.md) | Making python/python3 work across Linux, macOS, Windows |
| [Shared Venv](python/shared-venv.md) | Venv setup for standalone and monorepo development |
| [ap-common Usage](python/ap-common-usage.md) | Use shared constants from ap-common |
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

### Python Templates

| Template | Description |
|----------|-------------|
| [Makefile](python/templates/Makefile) | Standard Makefile with all required targets |
| [pyproject.toml](python/templates/pyproject.toml) | Package config with standard dev dependencies |
| [TEST_PLAN.md](python/templates/TEST_PLAN.md) | Testing strategy documentation template |
| [pipx.mk](python/templates/pipx.mk) | CLI tool installation via pipx (includable `.mk`) |
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

### Workflow Templates

| Template | Description |
|----------|-------------|
| [test.yml](build/templates/workflows/test.yml) | Run pytest on Python 3.12-3.14 |
| [lint.yml](build/templates/workflows/lint.yml) | Run flake8 linter |
| [typecheck.yml](build/templates/workflows/typecheck.yml) | Run mypy type checker |
| [format.yml](build/templates/workflows/format.yml) | Verify black formatting |
| [coverage.yml](build/templates/workflows/coverage.yml) | Enforce 80% coverage threshold |
| [mutation.yml](build/templates/workflows/mutation.yml) | Run mutmut mutation testing |
| [reachability.yml](build/templates/workflows/reachability.yml) | Verify document reachability from entry points |
| [version-check.yml](build/templates/workflows/version-check.yml) | Validate semver (optional, copy when opting in) |

## Claude Code

| Standard | Description |
|----------|-------------|
| [Skills](claude-code/skills.md) | Authoring Claude Code skills (SKILL.md files) |
| [Plugins](claude-code/plugins.md) | Plugin structure, manifest schema, marketplace distribution |
| [Hook State Transitions](claude-code/hook-state-transitions.md) | Hook event types, state machines, and configuration |

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
