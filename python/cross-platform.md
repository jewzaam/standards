# Cross-Platform Python

Make `python` and `python3` work consistently across Linux, macOS, and Windows.

> Why these quirks exist (Microsoft Store aliases, Windows Smart App Control)
> lives in [knowledgebase/python/cross-platform.md](https://github.com/jewzaam/knowledgebase/blob/main/python/cross-platform.md).

## The Fix: PATH Shims

Place cross-platform shims for `python` and `python3` in a directory on `PATH`.
Each shim detects the platform and delegates to the right command:

- **Windows (Git Bash / MSYS2):** `py -3`
- **Linux / macOS:** `/usr/bin/python3` (hardcoded to avoid infinite recursion
  since the shim shadows `python3` on PATH)

### Shim: `python3`

```bash
#!/bin/bash

PYTHON3_CMD=/usr/bin/python3

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        exec py -3 "$@"
        ;;
    *)
        exec $PYTHON3_CMD "$@"
        ;;
esac
```

### Shim: `python`

```bash
#!/bin/bash

PYTHON_CMD=/usr/bin/python

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        exec py -3 "$@"
        ;;
    *)
        exec $PYTHON_CMD "$@"
        ;;
esac
```

## Setup

1. Place both shims in a directory that is on `PATH` (e.g., `~/bin` or
   `~/source/bin`)
2. Make them executable: `chmod +x python python3`
3. Ensure the shim directory appears **before** the Windows App Execution
   Aliases directory in `PATH`. On Windows, this means before
   `~\AppData\Local\Microsoft\WindowsApps`
4. Verify: `python3 --version` should print the installed Python version, not
   a Microsoft Store error

## Effect on Makefiles

With the shims on PATH, Makefiles no longer need `PYTHON_BOOTSTRAP` or
platform-conditional bootstrap logic. `python3 -m venv` works on all
platforms. The only platform split remaining is the venv layout
(`Scripts/python.exe` vs `bin/python`).

## Effect on Scripts

Scripts using `#!/usr/bin/env python3` shebangs work on all platforms without
modification. Shell scripts calling `python3 -c` or `python3 -m` also work
without platform checks.

## Always use `python -m <module>`, not naked entry-point commands

Find the module name in the package's `pyproject.toml` under `[project.scripts]`.
For example:

```toml
[project.scripts]
ai-guardian = "ai_guardian.__main__:main"
```

Invoke as `python -m ai_guardian` instead of `ai-guardian`. Combined with the
`python` / `python3` PATH shims above, `python -m <module>` works identically
on Linux, macOS, and Windows.
