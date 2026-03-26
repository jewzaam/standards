# Work Standards

[![Markdown Lint](https://github.com/jewzaam/standards/actions/workflows/markdown-lint.yml/badge.svg)](https://github.com/jewzaam/standards/actions/workflows/markdown-lint.yml)
[![Validate Links](https://github.com/jewzaam/standards/actions/workflows/links.yml/badge.svg)](https://github.com/jewzaam/standards/actions/workflows/links.yml)

Reusable software development standards. Reference these instead of recreating project-specific guidelines.

## Usage

Reference in your project:

```markdown
This project follows the [Work Standards](https://github.com/jewzaam/standards).
```

## Common

| Standard | Description |
|----------|-------------|
| [Versioning](common/versioning.md) | Semantic versioning and release conventions |
| [README Format](common/readme-format.md) | README structure and content |
| [Naming](common/naming.md) | Project and package naming conventions |
| [Git Submodules](common/submodules.md) | Git submodule conventions and workflows |

## Python

| Standard | Description |
|----------|-------------|
| [Style](python/style.md) | Python coding style and best practices |
| [Project Structure](python/project-structure.md) | Directory layout and required files |
| [Testing](python/testing.md) | Unit testing conventions, TDD, and TEST_PLAN.md requirements |
| [Shared Venv](python/shared-venv.md) | Venv setup for standalone and monorepo development |
| [ap-common Usage](python/ap-common-usage.md) | Use shared constants from ap-common |
| [Logging & Progress](python/logging-progress.md) | Logging, progress indicators, and output |

### Python Templates

| Template | Description |
|----------|-------------|
| [Makefile](python/templates/Makefile) | Standard Makefile for ap-* projects |
| [TEST_PLAN.md](python/templates/TEST_PLAN.md) | Testing strategy documentation template |
| [version-check.mk](python/templates/version-check.mk) | Semver validation (includable `.mk`, optional `make version-check`) |

## CLI

| Standard | Description |
|----------|-------------|
| [Conventions](cli/conventions.md) | CLI argument and flag conventions |
| [Testing](cli/testing.md) | CLI entry point testing patterns |

## Build and CI/CD

| Standard | Description |
|----------|-------------|
| [Makefile](build/makefile.md) | Build targets and conventions |
| [GitHub Workflows](build/github-workflows.md) | CI/CD pipeline configuration |

### Workflow Templates

| Template | Description |
|----------|-------------|
| [test.yml](build/templates/workflows/test.yml) | Run pytest on Python 3.10-3.14 |
| [lint.yml](build/templates/workflows/lint.yml) | Run flake8 linter |
| [typecheck.yml](build/templates/workflows/typecheck.yml) | Run mypy type checker |
| [format.yml](build/templates/workflows/format.yml) | Verify black formatting |
| [coverage.yml](build/templates/workflows/coverage.yml) | Enforce 80% coverage threshold |
| [version-check.yml](build/templates/workflows/version-check.yml) | Validate semver (optional, copy when opting in) |

## Planned Sections

| Section | Description |
|---------|-------------|
| [Tkinter](python/tkinter/) | UI patterns for Python tkinter applications |
| [Android](android/) | Android application development standards |
| [Mobile](mobile/) | Cross-platform mobile development patterns |
| [Spec-Kit](spec-kit/) | Working with spec-kit |
| [Guides](guides/) | Process and tooling how-tos |

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
