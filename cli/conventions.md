# CLI Standards

Command-line interface conventions.

## Options

| Type | Example | Rule |
|------|---------|------|
| Single concept | `--dryrun`, `--debug` | No hyphens |
| Qualified/compound | `--no-overwrite`, `--blink-dir` | Hyphen separates qualifier |

## Required Options

All CLI tools must support:

| Option | Short | Type | Description |
|--------|-------|------|-------------|
| `--debug` | | flag | Enable debug output |
| `--dryrun` | | flag | Perform dry run without side effects |
| `--quiet` | `-q` | flag | Suppress non-essential output (see below) |
| `--log-file` | | path | Write log output to file (see below) |

### `--quiet` Flag Behavior

The `--quiet` flag enables minimal output mode for scripting, automation, and clean logging.

**Suppressed when `--quiet` is set:**

| Output Type | Examples |
|-------------|----------|
| Progress indicators | Progress bars, spinners, percentage counters |
| INFO-level logging | "Starting processing", "Found N files" |
| Summary statistics | "Processed 42 files successfully" |

**Never suppressed (always shown):**

| Output Type | Rationale |
|-------------|-----------|
| WARNING messages | Indicate potential issues requiring attention |
| ERROR messages | Critical for diagnosing failures |
| Exit codes | Required for scripting and automation |
| Dry-run output | User explicitly requested this information |

**Use cases:**

- Scripting/automation requiring minimal output
- Cron jobs avoiding unnecessary email notifications
- File logging where progress bars create unwanted artifacts
- CI/CD pipelines with cleaner logs

See [Logging and Progress Standards](../python/logging-progress.md) for implementation patterns.

### `--dryrun` Flag Behavior

"Without side effects" means the filesystem is left exactly as it was. Writing a file is a side effect, even one the caller asked for and even if it touches none of the data the tool manages (a report, a cache, a generated script).

| Allowed in a dry run | Not allowed in a dry run |
|----------------------|--------------------------|
| Reading files | Moving, copying, deleting, or modifying files |
| Output on stdout/stderr, for people | Writing any file: reports, state, caches, generated scripts |
| Log output (`--log-file`, see below) | Creating directories |

**Options that write a file:** under `--dryrun` the file is not written. The tool says it would have written it (e.g. `[DRYRUN] Would write report to PATH`) and carries on. Dry-run output is for people and is never suppressed by `--quiet` (see above).

**Handing results to another program:** don't make the caller parse stdout or logs; those are operational output, not an interface. Give the tool a separate, non-dry-run mode whose only effect is writing the result file, named for that intent (e.g. `--report-only-file PATH`: write the report, change nothing else). Under `--dryrun` that mode, too, only says what it would have written.

Exception: `--log-file` still writes during a dry run. The user explicitly redirected log output there, and the log only records what the run did.

### `--log-file` Flag Behavior

The `--log-file` flag redirects all log output to a file instead of stderr.

**Behavior:**

| Aspect | Detail |
|--------|--------|
| Default | Not set — logs go to stderr |
| Path resolution | `expanduser().resolve()` — expands `~`, converts to absolute |
| File mode | Append (`"a"`) — survives process restarts |
| Scope | All logging output (DEBUG through CRITICAL) |
| Uncaught exceptions | Route through `sys.excepthook` to the same logger |
| Combines with | `--debug`, `--quiet` (controls level, not destination) |

**Use cases:**

- Long-running GUI/daemon processes that restart themselves
- Preserving log history across `os.execv`-style restarts
- Post-mortem debugging of crashes via captured stack traces

See [Logging and Progress Standards - File Output](../python/logging-progress.md#file-output) for implementation patterns.

## Option Naming

| Pattern | Example | Use |
|---------|---------|-----|
| `--<word>` | `--debug`, `--dryrun` | Single-concept flags |
| `--no-<feature>` | `--no-overwrite`, `--no-accept` | Disable default behavior |
| `--<qualifier>-dir` | `--blink-dir`, `--accept-dir` | Directory paths |

## Boolean Flags

**Preferred Pattern:** Use `argparse.BooleanOptionalAction` for boolean feature flags (Python 3.9+).

```python
parser.add_argument(
    "--scale-dark",
    action=argparse.BooleanOptionalAction,
    default=False,
    help="scale dark frames using bias compensation (allows shorter exposures). "
    "Default: exact exposure match only",
)
```

**When to use:**

- Features that can be enabled or disabled
- Behavior that should be explicitly controllable
- Replacing simple `action="store_true"` flags where negation is useful

**Example:**

- `--scale-dark` - Enable bias-compensated dark frame scaling

## Positional Arguments

Source and destination directories are positional, not options.

## Help Text

| Rule | Example |
|------|---------|
| Start with lowercase | `help="enable debug output"` |
| No period at end | `help="source directory"` |
| Under 60 characters | Keep it brief |

## Default Values

**Single Source of Truth:** Set default values in ONE place only.

### For CLI Arguments

Set defaults in `argparse` argument definition, **not** in function signatures:

**Good:**
```python
# config.py
DEFAULT_PATH_PATTERN = r".*[/\\]accept[/\\].*"

# CLI
parser.add_argument(
    "--path-pattern",
    default=config.DEFAULT_PATH_PATTERN,
    help="regex pattern to match paths"
)

# Function - no default in signature
def process(path_pattern: str = None):
    # None means "use whatever caller passed"
    pass
```

**Bad:**
```python
# CLI
parser.add_argument("--path-pattern", default=r".*accept.*")

# Function - DUPLICATE default
def process(path_pattern: str = r".*accept.*"):  # Wrong!
    pass
```

**Rationale:**

- Prevents inconsistencies when defaults change
- Clear separation: CLI layer sets policy, function layer implements logic
- Function can be called programmatically with different defaults

## Output

Status and progress go to stderr, data to stdout, so a caller can pipe the data
without status mixed into it.

| Rule | Detail |
|------|--------|
| Case | Sentence case — capital first letter. A line opening with a literal command, flag, filename, or variable keeps that literal's case (`gh pr view failed`, `open-prs.json is 12m old`) |
| Column | Status lines start at column 0. Never indent to imply nesting |
| Detail lines | Indent 4 spaces, lowercase fragment, no closing period. Explains the status line directly above it |
| Density | One line per item. A per-item result is a line, not a block |
| Prefixes | `Error:`, `Warning:`, `Note:` — capitalized, and the only prefixes |
| Wrapping | Never hard-wrap one message across several print calls. One message, one line; the terminal wraps it |

### Result marks

| Mark | Meaning | Color |
|------|---------|-------|
| `✓` | Completed | green |
| `✗` | Failed | red |
| `⊘` | Skipped — nothing was wrong, the work was not needed | yellow |

At column 0, one space, then the result. Color only when the stream is a TTY
(`[[ -t 2 ]]` for stderr), so a redirected log keeps the glyph without escapes.

A skipped item names what was skipped and why on its one line:

```text
⊘ Download skipped — OpenShell unchanged in the sandbox (--force to pull)
```

Skipped earns a mark for the reason failure does: unmarked, it is a bare line
among marked ones, and reads as another success.

### Wrapping another tool

When a tool you invoke prints its own status, match its case and column so both
read as one stream, and do not re-announce what it already announces. Print only
what it cannot know — most often, why you skipped calling it at all.

## Exit Codes

Define as module-level constants with `EXIT_` prefix:

| Constant | Value | Meaning |
|----------|-------|---------|
| `EXIT_SUCCESS` | 0 | Success |
| `EXIT_ERROR` | 1 | Error |
