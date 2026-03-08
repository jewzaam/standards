# Git Submodules

Standard for managing Git submodules in the ap-base monorepo.

## Rationale

- **Independence** - Each ap-* tool is a standalone repository that can be cloned and developed independently
- **Integration** - ap-base aggregates all tools as submodules for full-pipeline workflows
- **Single source of truth** - Each tool has one canonical repository; ap-base references a specific commit
- **Shared development** - Combined with the [shared venv](shared-venv.md), submodules enable cross-repo editable installs

## Repository Layout

The ap-base monorepo contains each ap-* tool as a submodule:

```
ap-base/
├── ap-common/              # Shared utilities (submodule)
├── ap-cull-light/          # Light frame culling (submodule)
├── ap-preserve-header/     # Header preservation (submodule)
├── ap-create-master/       # Master frame creation (submodule)
├── ap-move-raw-light-to-blink/  # (submodule)
├── ap-move-master-to-library/   # (submodule)
├── ap-copy-master-to-blink/     # (submodule)
├── ap-move-light-to-data/       # (submodule)
├── .gitmodules
├── Makefile
└── README.md
```

## Adding a New Submodule

Add each ap-* tool at the repository root of ap-base:

```bash
cd ap-base
git submodule add https://github.com/jewzaam/ap-<name>.git ap-<name>
git commit -m "Add ap-<name> submodule"
```

This creates an entry in `.gitmodules` and records the pinned commit.

## Cloning with Submodules

Clone ap-base and initialize all submodules in one step:

```bash
git clone --recurse-submodules https://github.com/jewzaam/ap-base.git
```

If already cloned without submodules:

```bash
cd ap-base
git submodule update --init --recursive
```

## Updating Submodules

### Pull latest from all submodules

```bash
cd ap-base
git submodule update --remote
```

This advances each submodule to the latest commit on its tracked branch. Review the changes, then commit the updated references:

```bash
git add ap-<name>
git commit -m "Update ap-<name> to latest"
```

### Pull latest for a single submodule

```bash
cd ap-base/ap-<name>
git pull origin main
cd ..
git add ap-<name>
git commit -m "Update ap-<name> to latest"
```

## Day-to-Day Development

### Working inside a submodule

Each submodule is a full Git repository. Develop normally:

```bash
cd ap-base/ap-cull-light
git checkout -b feature-branch
# Make changes
git add .
git commit -m "Add feature"
git push origin feature-branch
```

After the submodule branch is merged to main, update the reference in ap-base:

```bash
cd ap-base
git submodule update --remote ap-cull-light
git add ap-cull-light
git commit -m "Update ap-cull-light to latest"
```

### Cross-repo testing

With the [shared venv](shared-venv.md), editable installs make cross-repo changes immediately visible:

```bash
cd ap-base/ap-common
# Edit ap_common/constants.py
cd ../ap-cull-light
make test               # Picks up ap-common changes immediately
```

No reinstall needed - the shared venv with editable installs handles this.

## CI Considerations

CI workflows in individual ap-* repositories do not need submodule support. Each repo is self-contained with its own tests and workflows.

For ap-base CI (if applicable), use `actions/checkout` with submodules:

```yaml
- uses: actions/checkout@v4
  with:
    submodules: recursive
```

## Submodule Branch Tracking

By default, `git submodule update --remote` pulls from the branch configured in `.gitmodules`. Set the tracked branch explicitly:

```bash
git config -f .gitmodules submodule.ap-<name>.branch main
```

All ap-* submodules should track `main`.

## What to Avoid

- **Do not commit from a detached HEAD inside a submodule** - Always checkout a branch before making changes. Submodules default to detached HEAD after `git submodule update`.
- **Do not use `git submodule foreach` for development tasks** - Work in each submodule individually to avoid accidental changes.
- **Do not nest submodules** - ap-* tools should not contain their own submodules. Keep the hierarchy flat.
- **Do not modify submodule content in ap-base PRs** - Make changes in the individual tool repository first, then update the submodule reference in ap-base.
