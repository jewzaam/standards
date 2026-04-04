# Cross-Platform Python

How to make `python` and `python3` work consistently across Linux, macOS, and Windows.

## The Problem

On Windows, `python` and `python3` are intercepted by Microsoft Store app execution aliases. These aliases do not run Python — they open the Store. Scripts with `#!/usr/bin/env python3` shebangs fail on Windows because the alias wins over any real Python installation.

The Windows Python Launcher (`py -3`) is the correct way to invoke Python on Windows, but it does not exist on Linux/macOS. This creates a split: scripts and Makefiles need platform-conditional logic to pick the right command.

## The Fix: PATH Shims

Place cross-platform shims for `python` and `python3` in a directory on `PATH`. Each shim detects the platform and delegates to the right command:

- **Windows (Git Bash / MSYS2):** `py -3`
- **Linux / macOS:** `/usr/bin/python3` (hardcoded to avoid infinite recursion since the shim shadows `python3` on PATH)

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

1. Place both shims in a directory that is on `PATH` (e.g., `~/bin` or `~/source/bin`)
2. Make them executable: `chmod +x python python3`
3. Ensure the shim directory appears **before** the Windows App Execution Aliases directory in `PATH`. On Windows, this means before `~\AppData\Local\Microsoft\WindowsApps`
4. Verify: `python3 --version` should print the installed Python version, not a Microsoft Store error

## Effect on Makefiles

With the shims on PATH, Makefiles no longer need `PYTHON_BOOTSTRAP` or platform-conditional bootstrap logic. `python3 -m venv` works on all platforms. The only platform split remaining is the venv layout (`Scripts/python.exe` vs `bin/python`).

## Effect on Scripts

Scripts using `#!/usr/bin/env python3` shebangs work on all platforms without modification. Shell scripts calling `python3 -c` or `python3 -m` also work without platform checks.
