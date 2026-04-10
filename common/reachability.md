# Document Reachability

Every content file in a repository must be reachable via markdown links from
designated entry points. Files that require traversing intermediate documents
to discover get lost — AI agents miss them, humans forget they exist, and they
drift out of date.

## Concepts

**Entry point** — a root document from which reachability is measured
(e.g., `CLAUDE.md`, `README.md`). A repo can have multiple entry points.

**Depth** — shortest link chain from an entry point to a file. The entry point
itself has depth 1. A file linked directly from the entry point has depth 2.

**Direct-link entry** — one entry point (typically `CLAUDE.md`) that must link
every content file directly (depth ≤ 2). This ensures AI agents can discover
all files without traversing intermediate documents.

**Excluded files** — infrastructure files that don't need to be reachable
(scripts, CI config, lock files, etc.).

## Rules

1. **Every content file must be reachable** from all entry points via markdown
   link chains.

2. **The direct-link entry must link every content file at depth ≤ 2.** This
   means either linking the file directly or linking a document that itself
   links the file.

3. **Use `git ls-files`** to discover tracked files. This respects `.gitignore`
   and avoids checking generated or vendored content.

4. **Exclude infrastructure** from reachability requirements. Common exclusions:

   | Category | Examples |
   |----------|----------|
   | Prefixes | `.github/`, `scripts/`, `.` (dotfiles) |
   | Exact files | `LICENSE`, `Makefile`, `pyproject.toml`, `ANALYSIS.md` |

5. **Enforce in CI** with a dedicated workflow that fails on unreachable files.

6. **When adding a new file**, add a link in the direct-link entry and any
   other entry points. Run the check before committing.

## Configuration Axes

Different repos need different settings. These are the axes of variance:

| Axis | Default | When to change |
|------|---------|----------------|
| Entry points | `CLAUDE.md`, `README.md` | Add entries like `NOTES.md` when multiple index documents exist |
| Direct-link entry | `CLAUDE.md` | Change when a different file serves as the primary index |
| Max depth | 2 | Increase to 3 for larger repos where intermediate index files are necessary |
| Scope | All tracked files | Restrict to a prefix (e.g., `docs/standards/`) when only a subset of files needs reachability |
| Exclusions | Dotfiles, `scripts/`, infra files | Adjust per repo — templates, generated files, etc. |

## Implementation

The reachability checker is a Python script (`scripts/reachability.py` by
convention) that:

1. Discovers tracked files via `git ls-files --cached --others --exclude-standard`
2. Parses markdown links (`[text](path)`) from each file, resolving relative paths
3. Builds a directed link graph
4. Runs BFS from each entry point to compute depths
5. Fails if any non-excluded content file is unreachable or exceeds max depth
   from the direct-link entry

### Link resolution

- Relative paths resolve from the linking file's directory
- Absolute paths (starting with `/`) resolve from the repo root
- Anchors (`#section`) are stripped; pure anchors are skipped
- External URLs (`http://`, `https://`, `mailto:`) are skipped
- Directory links resolve to `directory/README.md` if it exists

### Makefile target

```makefile
reachability:  ## Verify all files are reachable from entry points
	@echo "Checking document reachability..."
	$(PYTHON) scripts/reachability.py --check
```

For repos that need a higher depth limit:

```makefile
reachability:  ## Verify all files are reachable from entry points
	@echo "Checking document reachability..."
	$(PYTHON) scripts/reachability.py --check --max-depth 3
```

Include `reachability` in the `check` target so it runs with other validations.

### CI workflow

```yaml
name: Reachability
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  reachability:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: make reachability
```

### CLI flags

- **`--check`** — validation mode. Prints pass/fail summary to stdout and
  exits non-zero on failures. Does not write any files. Use this in CI and
  Makefile targets.
- **`--max-depth N`** — override the maximum allowed depth from the direct-link
  entry. Default is 2. Use 3 for larger repos with intermediate index files
  (e.g., monorepos where `CLAUDE.md` → `AGENTS.md` → `docs/standards/*.md`).
  Pass via the Makefile target so the value is documented in one place.
- **No flags** — report mode. Writes `ANALYSIS.md` with a depth table showing
  each file's depth from every entry point. Useful for auditing. Exclude
  `ANALYSIS.md` from reachability checks itself (add to `EXCLUDED_EXACT`).

## Adapting for a new repo

1. Copy `scripts/reachability.py` from an existing implementation
2. Set `ENTRY_POINTS` and `DIRECT_LINK_ENTRY` for the repo
3. Set `EXCLUDED_PREFIXES` and `EXCLUDED_EXACT` for infrastructure files
4. If only a subset of files needs checking, add a scope prefix filter
5. Add the `reachability` Makefile target
6. Add the CI workflow
7. Document the reachability requirement in `CLAUDE.md`
