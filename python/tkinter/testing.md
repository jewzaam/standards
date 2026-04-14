# Tkinter Testing

Testing conventions for tkinter desktop applications. Extends the general
[Testing Standards](../testing.md) with tkinter-specific patterns.

## Two-Layer Strategy

Tkinter applications use two layers of tests with different characteristics:

| Layer | Speed | Volume | Scope | GUI required? |
|-------|-------|--------|-------|---------------|
| Business logic | Fast | Many | Model, controller logic | No |
| GUI integration | ~150-200ms each | Few | Widget wiring, event flow | Yes |

**Business logic tests** are standard pytest tests targeting the model layer.
These should make up the majority of the test suite. The model must not import
tkinter — see [Architecture](architecture.md#mvc-separation).

**GUI integration tests** verify that widgets correctly wire to business logic.
They use real tkinter widgets with `withdraw()`, `invoke()`, and
`event_generate()`. Budget for ~150-200ms per test.

## Root Fixture

Manage a single `tk.Tk` root per test module. Multiple `Tk()` instances create
separate Tcl interpreters with shared event queue interference.

`root.withdraw()` makes the entire widget tree invisible — widgets exist as
in-memory Tcl objects but nothing renders on screen. You can create buttons,
invoke them, read entry values, and check state without any window appearing.
Tests must never show visible windows.

```python
import tkinter as tk
import pytest

@pytest.fixture(scope="module")
def root():
    root = tk.Tk()
    root.withdraw()  # Invisible — widgets work, nothing renders
    yield root
    root.update_idletasks()
    root.destroy()
```

### Teardown Order

When tests create widgets, clean up in this order:

```python
widget.after_cancel(timer_id)   # 1. Cancel scheduled callbacks
del self.widget_ref             # 2. Delete attribute references
root.update_idletasks()         # 3. Process pending operations
root.destroy()                  # 4. Destroy root last
```

Orphaned `after()` callbacks cause `TclError` on destroyed widgets. Always
cancel before destroy.

## Widget Interaction

### invoke() — direct callback execution

```python
button = ttk.Button(root, command=on_submit)
button.invoke()  # Calls on_submit() directly, no mainloop needed
```

Works with `Button`, `ttk.Button`, and `Menu` items. Preferred for simple
command execution tests.

### event_generate() — simulated user events

```python
widget.event_generate('<Button-1>', x=10, y=10)
widget.event_generate('<KeyPress>', keysym='Return')
```

For realistic click simulation, use the full event sequence:
`<Enter>` → `<Motion>` → `<ButtonPress-1>` → `<ButtonRelease-1>`

### Widget state verification

```python
entry.get()                     # Read text content
widget.cget('option')           # Read configuration value
widget.instate(['disabled'])    # ttk state check (returns bool)
```

## Mocking Dialogs

Dialogs block test execution. Mock them at the import point in your module:

```python
from unittest import mock

@mock.patch('mypackage.views.messagebox.showinfo')
def test_save_shows_confirmation(mock_show):
    save_data()
    mock_show.assert_called_once_with('Success', 'Data saved')
```

For modal windows that use `grab_set()` and `wait_window()`, use the
`_utest=True` parameter pattern — production code skips blocking calls in
test mode:

```python
class SettingsDialog:
    def __init__(self, parent, *, _utest=False):
        self._window = tk.Toplevel(parent)
        if not _utest:
            self._window.grab_set()
            self._window.wait_window()
```

## The Mainloop Problem

`root.mainloop()` blocks test execution. Three approaches, from simplest to
most robust:

**A. Never call mainloop** — use `invoke()` and direct widget access. Sufficient
for most tests.

**B. update_idletasks()** — process display updates without entering the event
loop:

```python
root.update_idletasks()  # Safe — display updates only
```

Avoid `root.update()` — it creates nested event loops that can cause
"serious difficulties" (per TkDocs).

**C. Generator-based mainloop** — CPython's approach for IDLE tests, described
as "faster and more robust than .update()":

```python
@run_in_tk_mainloop(delay=1)
def test_input_handling(self):
    self.do_input('hello')
    yield                    # Let mainloop process events
    self.assert_output('hello')
```

Uses a real mainloop with `after()` scheduling to interleave test steps. Use
this for tests that genuinely need event loop processing.

## Headless CI

Tkinter requires the Tk shared libraries (`libtk`) at import time. The
`actions/setup-python` action installs CPython from pre-built binaries that
expect Tk to already be on the system — it is not included by default on
`ubuntu-latest`. Any workflow that imports a module using tkinter (directly
or transitively) will fail with `ImportError: libtk8.6.so: cannot open
shared object file` unless the system package is installed first.

Tkinter tests also require a display. On Linux CI runners, use pytest-xvfb:

```yaml
# GitHub Actions
- name: Install Tk libraries
  run: sudo apt-get update && sudo apt-get install -y python3-tk
- run: sudo apt-get install -y xvfb
- run: pip install pytest-xvfb
- run: python -m pytest
```

Configure in `pytest.ini` or `pyproject.toml`:

```ini
[pytest]
xvfb_width = 1280
xvfb_height = 720
xvfb_colordepth = 24
```

Use `--no-xvfb` locally for visual inspection during debugging.

macOS and Windows CI runners generally have display subsystems available.

## Common Failure Modes

| Problem | Symptom | Fix |
|---------|---------|-----|
| Multiple `Tk()` instances | Shared event queue interference | Single root per module |
| Orphaned `after()` callbacks | `TclError` on destroyed widgets | Cancel before destroy |
| `winfo` before render | Returns 1 instead of actual size | Call `update_idletasks()` first |
| `wait_visibility` in CI | Hangs on headless runners | Use pytest-xvfb |
| `destroy()` called twice | `TclError` | Guard with try/except or flag |
| Cross-thread widget access | `RuntimeError` | Keep widget ops on main thread |

## What to Test

- **Model layer** — all business logic, data transformations, state management
  (standard pytest, no GUI)
- **Controller logic** — action coordination, state transitions (mock views)
- **Widget wiring** — buttons call the right callbacks, state renders correctly
  (integration tests with real widgets)
- **Event sequences** — complex interactions like drag-and-drop, keyboard
  shortcuts (use `event_generate()`)

## What Not to Test

- Widget rendering/appearance — visual correctness is manual verification
- Tkinter library behavior — trust the framework
- Layout pixel positions — fragile, platform-dependent
- Mainloop scheduling order — non-deterministic
