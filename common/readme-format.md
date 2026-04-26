# README Format

Standard structure for project READMEs.

## Structure

1. Title
2. Badges (if GitHub Actions workflows exist)
3. Brief description (1-2 sentences)
4. Documentation links
5. Overview (what it does, key features)
6. Installation
7. Usage (with examples)
8. Development

## Title

Use the package name as the title:

```markdown
# <package-name>
```

Do not use prose titles like "Light Frame Organization Tool".

## Badges

Include badges only when the project has corresponding GitHub Actions workflows. Each badge maps to a workflow file — if the workflow doesn't exist, omit the badge.

Format on two lines for readability:

**Line 1:** Workflow badges (Test, Coverage, Lint, Format, Type Check)
**Line 2:** Language and style badges (Python version, Black formatting)

```markdown
[![Test](https://github.com/<owner>/<repo>/actions/workflows/test.yml/badge.svg)](https://github.com/<owner>/<repo>/actions/workflows/test.yml) [![Coverage](https://github.com/<owner>/<repo>/actions/workflows/coverage.yml/badge.svg)](https://github.com/<owner>/<repo>/actions/workflows/coverage.yml) [![Lint](https://github.com/<owner>/<repo>/actions/workflows/lint.yml/badge.svg)](https://github.com/<owner>/<repo>/actions/workflows/lint.yml) [![Format](https://github.com/<owner>/<repo>/actions/workflows/format.yml/badge.svg)](https://github.com/<owner>/<repo>/actions/workflows/format.yml) [![Type Check](https://github.com/<owner>/<repo>/actions/workflows/typecheck.yml/badge.svg)](https://github.com/<owner>/<repo>/actions/workflows/typecheck.yml)
[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/) [![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
```

Omit any badge whose workflow doesn't exist. Projects with no GitHub Actions workflows have no badges section.

## Description

One or two sentences immediately after badges (or title if no badges). State what the tool does, not implementation details.

Good:
> A tool for organizing light frames based on FITS metadata.

Bad:
> This Python package uses astropy to read FITS headers and organize files into directories.

## Documentation Links

Link to project-specific documentation if it exists:

```markdown
## Documentation

- **[How It Works](docs/how-it-works.md)** — pipeline, layout, side effects
- **[Setup Guide](docs/setup.md)** — prerequisites and configuration
```

Omit this section if the project has no docs beyond the README.

### Multi-project families

Projects that belong to a larger family with shared documentation should include a documentation block linking back to the parent project's overview, workflow guides, and per-tool documentation. Keep the format consistent across all projects in the family.

## Overview

Expand on the description. Cover:
- What problem it solves
- Key features (bulleted list)
- How it fits in the pipeline (if relevant)

Keep it brief. Users want to know what it does, not how.

## Installation

Two methods:

```markdown
## Installation

### Development

\`\`\`bash
git clone https://github.com/<owner>/<repo>.git
cd <repo>
make install-dev
\`\`\`

### From Git

\`\`\`bash
pip install git+https://github.com/<owner>/<repo>.git
\`\`\`
```

## Usage

Show the command-line interface with examples:

```markdown
## Usage

\`\`\`bash
python -m <module> [options]
\`\`\`

### Options

| Option | Description |
|--------|-------------|
| `--debug` | Enable debug output |
| `--dryrun` | Preview without changes |
| `--quiet` / `-q` | Suppress non-essential output |
```

Include 1-2 concrete examples with real-looking paths.

## What to Avoid

- Implementation details (test file names, internal functions)
- Verbose explanations of obvious things
- Changelog or version history
- Contributor guidelines (use CONTRIBUTING.md if needed)
- Duplicate information from other sections
- License section (LICENSE file exists)
- Badges for workflows that don't exist
