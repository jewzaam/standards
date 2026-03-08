# Git Submodules

Standard Git submodule conventions and workflows.

## Rationale

- **Independence** - Each project is a standalone repository that can be cloned and developed independently
- **Integration** - A parent repo aggregates projects as submodules for combined workflows
- **Single source of truth** - Each project has one canonical repository; the parent references a specific commit
- **Shared development** - Combined with the [shared venv](shared-venv.md), submodules enable cross-repo editable installs

## Adding a Submodule

Add submodules at the repository root:

```bash
git submodule add <repo-url> <path>
git commit -m "Add <path> submodule"
```

This creates an entry in `.gitmodules` and records the pinned commit.

## Initializing Submodules

```bash
make init
```

The `init` target wraps `git submodule update --init --recursive`. Use this after cloning a repo that contains submodules.

## Updating Submodules

```bash
make deinit init
```

The `deinit` target removes existing submodule checkouts and `init` re-clones them at the currently pinned commits. This is the cleanest way to sync submodules after pulling changes to `.gitmodules` or submodule refs.

Periodically update the parent repo's pinned submodule references to keep them current.

## Day-to-Day Development

### Working inside a submodule

Each submodule is a full Git repository. Develop normally:

```bash
cd <submodule-path>
git checkout -b feature-branch
# Make changes
git add .
git commit -m "Add feature"
git push origin feature-branch
```

### Cross-repo testing

With the [shared venv](shared-venv.md), editable installs make cross-repo changes immediately visible:

```bash
cd <parent-repo>/<shared-lib>
# Edit source files
cd ../<dependent-project>
make test               # Picks up shared library changes immediately
```

No reinstall needed - the shared venv with editable installs handles this.

## CI Considerations

CI workflows in individual repositories do not need submodule support. Each repo is self-contained with its own tests and workflows.

For parent repos that aggregate submodules, use `actions/checkout` with submodules:

```yaml
- uses: actions/checkout@v4
  with:
    submodules: recursive
```

## Submodule Branch Tracking

By default, `git submodule update --remote` pulls from the branch configured in `.gitmodules`. Set the tracked branch explicitly:

```bash
git config -f .gitmodules submodule.<path>.branch main
```

All submodules should track `main`.

## What to Avoid

- **Do not commit from a detached HEAD inside a submodule** - Always checkout a branch before making changes. Submodules default to detached HEAD after `git submodule update`.
- **Do not nest submodules** - Keep the hierarchy flat. Individual projects should not contain their own submodules.
- **Do not modify submodule content in parent repo PRs** - Make changes in the individual project repository first, then update the submodule reference in the parent.
