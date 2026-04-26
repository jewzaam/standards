# Project Structure

Standard directory layout for Python projects.

## Directory Layout

```text
<repo-name>/
├── .venv/                  # Virtual environment (created by make, git-ignored)
├── <package_name>/         # Package directory (underscores)
│   ├── __init__.py
│   ├── __main__.py         # Entry point for python -m
│   └── <module>.py
├── tests/
│   ├── __init__.py
│   └── test_<module>.py
├── .github/
│   └── workflows/
│       ├── test.yml
│       ├── lint.yml
│       ├── typecheck.yml
│       ├── format.yml
│       └── coverage.yml
├── .gitignore
├── LICENSE
├── MANIFEST.in
├── Makefile
├── README.md
└── pyproject.toml
```

The `.venv/` directory is created automatically by `make install-dev` and must be git-ignored. For project families that share a single venv across multiple repos, see [Shared Virtual Environment](shared-venv.md).

## Required Files

| File | Purpose |
|------|---------|
| `LICENSE` | Project license |
| `README.md` | Project documentation |
| `MANIFEST.in` | sdist inclusion rules |
| `Makefile` | Build/test automation |
| `pyproject.toml` | Package configuration |
| `.gitignore` | Git ignore patterns |

## Naming Conventions

See [Naming](../common/naming.md) for the full naming taxonomy and pattern.

- **Repository**: hyphenated (e.g., `my-tool`)
- **Package directory**: Same as repository with underscores (e.g., `my_tool`)
- **Module files**: lowercase, underscored
- **Test files**: `test_<module>.py`

## pyproject.toml

See [templates/pyproject.toml](templates/pyproject.toml) for the generic template. Add domain-specific `keywords` and `classifiers` for your project family.

## .gitignore

```gitignore
# Python
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/
.eggs/

# Testing
.pytest_cache/
.coverage
htmlcov/

# Mutation testing
mutants/
.mutmut-cache

# Type checking
.mypy_cache/

# IDE
.vscode/
.idea/

# Virtual environments
venv/
.venv/

# Claude Code local settings
.claude/settings.local.json
```

## MANIFEST.in

```text
include LICENSE
include README.md
recursive-include <package_name> *.py
```
