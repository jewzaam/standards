# Python Style Standards

## Function Calls: Named Parameters

**Prefer explicit named parameters over positional parameters when calling functions.**

### Rule

When calling functions with multiple parameters, especially optional parameters, use named parameter assignment instead of relying on positional order.

### Rationale

Positional parameters are error-prone:

- Parameter order changes can silently break code
- Wrong values can be passed to wrong parameters with no type checking
- Code is harder to understand without reading function signature

### Example Bug

This bug actually occurred in production:

```python
# Function signature
def move_file(from_file: str, to_file: str, debug: bool = False, dryrun: bool = False):
    ...

# WRONG: dryrun passed as 3rd positional argument maps to debug parameter
move_file(src, dest, dry_run)  # dry_run → debug, dryrun stays False (default)
# Result: Files actually moved with debug output!

# CORRECT: Named parameter ensures correct mapping
move_file(src, dest, dryrun=dry_run)
```

### Guidelines

**Required positional parameters:** Can use positional or named
```python
# Both acceptable
check_calibration_status(image_dir, source_dir)
check_calibration_status(directory=image_dir, source_dir=source_dir)
```

**Optional parameters:** Must use named assignment
```python
# WRONG: Positional optional parameters
status = check_calibration_status(image_dir, source_dir, debug, scale_darks)

# CORRECT: Named optional parameters
status = check_calibration_status(
    image_dir,
    source_dir,
    debug=debug,
    scale_darks=scale_darks
)
```

**Boolean flags:** Always use named assignment
```python
# WRONG: Hard to understand what True/False mean
process_data(data, True, False, True)

# CORRECT: Clear intent
process_data(data, validate=True, strict=False, verbose=True)
```

### Exceptions

Positional parameters are acceptable when:

- Only 1-2 required parameters with clear, unambiguous meaning
- Very common functions where positional usage is idiomatic (e.g., `print()`, `len()`)
- All parameters are required (no defaults)

### Enforcement

- Code reviewers should flag positional optional parameters
- Consider adding linter rules (flake8-named-arguments plugin)
- Update existing code opportunistically when making changes

## Function Definitions: Keyword-Only Arguments (`*`)

**Use `*` in function signatures to enforce keyword-only arguments for optional parameters.**

### Rule

When defining functions with optional parameters (parameters with defaults), place a bare `*` before them to make them keyword-only. Required parameters go before the `*`, optional parameters go after.

### Rationale

The `*` syntax enforces at the language level what the "Named Parameters" guideline above recommends by convention. Callers **cannot** pass keyword-only arguments positionally — Python raises `TypeError` if they try. This eliminates the entire class of positional-argument bugs rather than relying on code review to catch them.

### Example

```python
def process_blink_directory(
    library_dir: Path,
    blink_dir: Path,
    date_dir_pattern: str,
    *,
    dry_run: bool = False,
    quiet: bool = False,
    scale_darks: bool = False,
    flat_state_path: Optional[Path] = None,
    picker_limit: int = 5,
) -> Statistics:
```

- **Before the `*`** — positional or keyword (required):
  `library_dir`, `blink_dir`, `date_dir_pattern`
- **After the `*`** — keyword-only (optional):
  `dry_run`, `quiet`, `scale_darks`, `flat_state_path`, `picker_limit`

Callers must name every optional argument:

```python
# CORRECT
stats = process_blink_directory(
    lib_path,
    blink_path,
    "YYYY-MM-DD",
    dry_run=True,
    scale_darks=True,
)

# WRONG — TypeError at runtime
stats = process_blink_directory(lib_path, blink_path, "YYYY-MM-DD", True, False, True)
```

### Guidelines

- Place `*` after the last required positional parameter
- All parameters with default values should appear after `*`
- Required parameters without defaults stay before `*`
- This applies to all project functions, not just public APIs

### Enforcement

- Python itself raises `TypeError` for violations — no linter needed
- Code reviewers should flag function definitions that have optional parameters without `*`
- Add `*` to existing functions opportunistically when making changes

## Dict Access: Bracket vs `.get()`

**Pick one access style per dict based on whether the shape is guaranteed,
and apply it to every key in that dict consistently.**

### Rule

- **`d["key"]`** when the dict's shape is guaranteed by the producer
  (internal code you control — a query helper, a derivation function, a
  factory, a fixture).
- **`d.get("key")`** only when the key might genuinely be absent
  (external JSON, parsed config, untrusted input, third-party dicts).

Within a single function reading a single dict, **do not mix**. Both
styles are functionally identical when the key is always present, and the
inconsistency creates a false signal — readers assume `.get()` means
"this might be missing" and waste time tracing the producer to confirm.

### Rationale

`.get()` is a defensive idiom. Using it on a dict whose shape your own
code guarantees:

- Lies about the contract — implies optionality that doesn't exist.
- Hides shape bugs — a missing key on a guaranteed-shape dict is a bug;
  silently returning `None` swallows it.
- Adds noise — `d.get("k", 0)` with a default is dead code when the
  producer always sets `k`.

Bracket access asserts the shape contract loudly. If the producer
changes and stops setting a key, `KeyError` flags it immediately at
the consumer instead of leaking `None` into downstream code.

### Example

```python
# Producer — guarantees every key
def _derive_session(...) -> dict:
    return {
        "session_id": ...,
        "ended_at": ...,        # may be None, but key is always present
        "agent_count": ...,
        "epochs": ...,          # may be None, but key is always present
    }


# WRONG — inconsistent; misleads readers about which fields are optional
def _to_response(d: dict) -> SessionResponse:
    return SessionResponse(
        session_id=d["session_id"],
        ended_at=d.get("ended_at"),
        agent_count=d.get("agent_count", 0),
        epochs=d.get("epochs"),
    )


# CORRECT — bracket access throughout; producer guarantees the shape
def _to_response(d: dict) -> SessionResponse:
    return SessionResponse(
        session_id=d["session_id"],
        ended_at=d["ended_at"],
        agent_count=d["agent_count"],
        epochs=d["epochs"],
    )
```

### Guidelines

- **Producer-controlled dicts** (helpers, factories, query results from
  your own code): bracket access for every key.
- **External dicts** (JSON parsed from a request, env-derived config,
  third-party API responses): `.get()` is fine, with explicit defaults
  where defaulting is meaningful.
- **None-vs-missing distinction is a code smell.** A producer that
  sometimes omits a key and sometimes sets it to `None` should be
  fixed to always set the key.
- **Defaults on `.get()`** (`d.get("k", default)`) are only meaningful
  when the key might genuinely be absent. On a guaranteed-shape dict
  the default is dead code.

### Enforcement

- Code reviewers should flag mixed access styles within a single
  function reading a single dict.
- When a producer adds a new field, update consumers to use bracket
  access — don't paper over with `.get()`.

## Black: Pin `target-version` to the Runtime Python

**Pin `[tool.black] target-version` in `pyproject.toml` to the same Python
version the project's runtime parses. Do not rely on black's default
target.**

### Rule

Every project that uses black sets an explicit `target-version` in
`pyproject.toml`:

```toml
[tool.black]
target-version = ["py314"]
```

The version in the list matches the lowest Python version the project
runs on (or the only one, for single-version projects). Update the pin
in the same commit that changes the project's supported Python range.

### Rationale

Black's default target tracks a future Python version. Black 26.x with
no explicit `target-version` currently targets py315. On an
`except (X, Y):` clause, black 26.x rewrites the tuple form to the
relaxed comma form because PEP-style relaxation makes the parens
optional at the future target.

Python 3.14 still parses the result without error, but the semantics
flip:

```python
# Before black
try:
    fetch()
except (urllib.error.URLError, TimeoutError) as exc:
    handle(exc)

# After black 26.x with no target-version pin (silently rewritten)
try:
    fetch()
except urllib.error.URLError, TimeoutError as exc:
    handle(exc)
# Parsed as: catch ONLY URLError, bind to local name `TimeoutError`.
# The TimeoutError arm is silently dropped from the catch.
```

The first exception class is caught; the second is silently demoted to a
local variable name. The `except` no longer catches `TimeoutError`.
Tests that don't exercise the `TimeoutError` arm of every except clause
won't notice. Mutation testing would catch it.

This is not a black bug — it's the documented behavior at the chosen
target. The bug is letting black pick a target ahead of the runtime
parser.

### When to apply

Every Python project that uses black and ships on a Python version older
than black's current default target. Effectively all Python projects
today.

### Defense in depth

For any `except (A, B):` clause that would survive a regression of the
target pin (i.e., a clause whose second arm is rarely exercised),
suffix `# fmt: skip` on the `except` line:

```python
except (urllib.error.URLError, TimeoutError) as exc:  # fmt: skip
    handle(exc)
```

This stops black from rewriting the line even if `target-version`
silently advances in a future config edit.

### Enforcement

- Code reviewers should flag any `pyproject.toml` that uses black
  without `[tool.black] target-version`.
- Grep the diff for changes to `except (` lines after a black version
  bump — silent paren removal is the regression signature.

### Provenance

Surfaced while standardising
<https://github.com/jewzaam/claude-quota-exporter>: `fetcher.py` had
two paren-stripped except clauses landed by black 26.5.1 running with
the default target.

## Imports: Every Import Must Resolve

**Adding an import is an implicit dependency-contract change.** An import must
resolve to one of:

- A Python stdlib module
- A local module in the tree
- A package declared in `requirements.txt` or `pyproject.toml[project.dependencies]`

Unresolvable imports — typos, hallucinated packages, packages pinned only in a
lockfile — are treated as fabrications. Projects enforcing this standard run
[fabcheck](../build/fabcheck.md) as a check (locally or in CI), which fails when
it finds an import that doesn't resolve.

Implications for contributors:

- Adding an import to a third-party package means also adding it to the project's
  declared deps in the same commit.
- Dist-name / import-name divergence (e.g., `pillow` installs as `PIL`) is
  handled precisely when fabcheck runs from an environment where the project's
  deps are installed. Run `make install-dev` before `make fabcheck` locally; CI
  does this automatically.
- Dynamic imports (`importlib.import_module`) and conditional imports bypass
  fabcheck — they are not a loophole for undeclared deps.
