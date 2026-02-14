# Testing Standards

Unit testing conventions for ap-* projects.

## Framework

Use pytest with pytest-cov for coverage.

## Directory Structure

```
tests/
├── __init__.py
├── test_<module>.py
├── conftest.py        # Shared fixtures
└── fixtures/          # Test data files
    └── README.md
```

## Test Isolation

Tests must be completely isolated:

| Rule | Rationale |
|------|-----------|
| No real filesystem access | Tests must not read/write outside `tmp_path` |
| No mutation of source files | Never modify files in the repo |
| No persistent state | Each test starts clean |
| All created files are cleaned up | Use `tmp_path` fixture for automatic cleanup |

Use pytest's `tmp_path` fixture for any file operations:

```python
def test_copy_file(tmp_path):
    source = tmp_path / "source.fits"
    source.write_bytes(b"test")
    dest = tmp_path / "dest.fits"

    copy_file(str(source), str(dest))

    assert dest.exists()
```

## Test Data (Fixtures)

**⚠️ DO NOT USE GIT LFS**

Git LFS has a $0 budget limit and is not funded for these projects. Large binary files will cause CI failures and block development.

Store test data files in `tests/fixtures/`. Prefer small, minimal test files:

- **Generate programmatically** when possible (mock FITS headers, minimal valid files)
- **Keep fixtures small** - only what's needed to test functionality
- **Avoid large binary files** - they bloat the repository
- **Document fixtures** - add `tests/fixtures/README.md` explaining each file's purpose

Example of generating minimal test data:

```python
from astropy.io import fits

def create_minimal_fits(path, header_data=None):
    """Create minimal valid FITS file for testing."""
    data = np.zeros((10, 10), dtype=np.uint16)
    hdu = fits.PrimaryHDU(data)
    if header_data:
        for key, value in header_data.items():
            hdu.header[key] = value
    hdu.writeto(path, overwrite=True)
```

## Naming

| Item | Pattern | Example |
|------|---------|---------|
| Test files | `test_<module>.py` | `test_move.py` |
| Test functions | `test_<function>_<scenario>` | `test_build_path_missing_camera_raises` |
| Test classes | `Test<Class>` | `TestMetadataExtraction` |

## Test Organization

One test file per module:

```
ap_<name>/
├── move.py
└── config.py

tests/
├── test_move.py
└── test_config.py
```

## Coverage

Target 80%+ line coverage.

```bash
make coverage
```

## What to Test

- Public functions and methods
- Edge cases (empty input, missing keys)
- Error conditions (raises appropriate exceptions)

## What Not to Test

- Private functions (test through public interface)
- Third-party library behavior
- Configuration constants
