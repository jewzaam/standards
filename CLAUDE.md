# Standards Repository

Reusable software development standards referenced by other projects via
`~/source/standards/` in the user's global CLAUDE.md. This is a reference
library — nothing to build or deploy. Other projects read these files when
making decisions about style, structure, testing, and CI.

The full organized index with section descriptions is in
[README.md](README.md). Every file is also linked directly below for
tool-based lookup.

Run `make help` for available validation targets.

## Maintaining this file

Every non-infrastructure file in this repo must be linked directly from this
file. No file should require traversing intermediate documents to discover.

Run `make test-reachability` (or `python scripts/reachability.py --check`) to
verify. It fails if any content file is missing a direct link from CLAUDE.md
or README.md.

When adding a new standard or template:

1. Add the file
2. Add a direct link here under the appropriate section with a short description
3. Add a link in [README.md](README.md) under the matching section
4. Run `make test-reachability` to confirm

## Common

- [common/README.md](common/README.md)
- [common/naming.md](common/naming.md) — repo, package, module, variable naming conventions
- [common/versioning.md](common/versioning.md) — semver rules, version location in pyproject.toml and code
- [common/readme-format.md](common/readme-format.md) — README structure, badges, descriptions
- [common/submodules.md](common/submodules.md) — git submodule conventions and workflows
- [common/git-worktrees.md](common/git-worktrees.md) — worktree conventions, cleanup, AI-assisted parallel development
- [common/reachability.md](common/reachability.md) — document reachability enforcement from entry points
- [common/tmp-dirs.md](common/tmp-dirs.md) — `.tmp-<slug>/` convention for named, git-ignored working directories
- [common/local-config-split.md](common/local-config-split.md) — `.example` template + `.gitignore` for per-environment config (secrets, endpoints)
- [common/git-remote-discovery.md](common/git-remote-discovery.md) — discover remote names by URL match, not by hardcoded `origin`/`upstream`

## Python

- [python/README.md](python/README.md)
- [python/style.md](python/style.md) — coding style, imports, type hints
- [python/project-structure.md](python/project-structure.md) — directory layout, required files
- [python/testing.md](python/testing.md) — pytest conventions, TDD, documenting untested areas
- [python/complexity.md](python/complexity.md) — cyclomatic complexity limit (10), ruff C901 enforcement
- [python/subprocess-security.md](python/subprocess-security.md) — subprocess and localhost server security rules
- [python/cross-platform.md](python/cross-platform.md) — making python/python3 work across Linux, macOS, Windows
- [python/shared-venv.md](python/shared-venv.md) — shared `~/.venv/<family>/` for related projects, local `.venv` fallback
- [python/logging-progress.md](python/logging-progress.md) — logger setup, `--log-file`, progress bars
- [python/settings-persistence.md](python/settings-persistence.md) — dataclass settings with atomic JSON I/O
- [python/agent-sdk.md](python/agent-sdk.md) — Claude Agent SDK integration, threading with tkinter, permission control

## Tkinter UI

- [python/tkinter/README.md](python/tkinter/README.md)
- [python/tkinter/architecture.md](python/tkinter/architecture.md) — app structure, controller pattern, window hierarchy
- [python/tkinter/windows.md](python/tkinter/windows.md) — window lifecycle, borderless mode, dragging, position persistence
- [python/tkinter/widgets.md](python/tkinter/widgets.md) — layout, StringVar, styling, fonts, context menus
- [python/tkinter/threading.md](python/tkinter/threading.md) — thread-safe UI updates, daemon threads, periodic polling
- [python/tkinter/dialogs.md](python/tkinter/dialogs.md) — modal dialogs, settings windows, color pickers
- [python/tkinter/testing.md](python/tkinter/testing.md) — two-layer testing strategy, root fixture, headless CI
- [python/tkinter/dpi-scaling.md](python/tkinter/dpi-scaling.md) — HiDPI detection, `tk scaling`, pixel dimension scaling

## Python Templates

- [python/templates/Makefile](python/templates/Makefile) — standard Makefile with all required targets
- [python/templates/pyproject.toml](python/templates/pyproject.toml) — package config with standard dev dependencies
- [python/templates/test.mk](python/templates/test.mk) — standard `test-*` target collection (includable `.mk`)
- [python/templates/version-check.mk](python/templates/version-check.mk) — semver validation (includable `.mk`, optional `make version-check`)
- [python/templates/version-check.sh](python/templates/version-check.sh) — shell script for semver validation

## .NET

- [dotnet/README.md](dotnet/README.md)
- [dotnet/style.md](dotnet/style.md) — async, nullable, .NET 8/10 features, MVVM
- [dotnet/project-structure.md](dotnet/project-structure.md) — csproj layout, TFM choice, deps
- [dotnet/testing.md](dotnet/testing.md) — xUnit/NUnit, Moq, FluentAssertions, STA/WPF tests
- [dotnet/nina-plugin.md](dotnet/nina-plugin.md) — NINA 3.x C# plugin: build, MEF, mediators, options, HTTP, logging, publishing

## CLI

- [cli/README.md](cli/README.md)
- [cli/conventions.md](cli/conventions.md) — argument naming, flags, `--log-file`, `--debug`
- [cli/testing.md](cli/testing.md) — testing main() with sys.argv patching

## Build and CI/CD

- [build/README.md](build/README.md)
- [build/makefile.md](build/makefile.md) — Makefile conventions, required targets, `PACKAGE_NAME`, `VENV_DIR`
- [build/github-workflows.md](build/github-workflows.md) — workflow conventions, Python versions, triggers
- [build/json-schema-validation.md](build/json-schema-validation.md) — `npx ajv` invocation, required flags, Make target shape
- [build/local-workflow-testing.md](build/local-workflow-testing.md) — testing GitHub Actions workflows locally with act, safe defaults
- [build/fabcheck.md](build/fabcheck.md) — fabrication detection: every import must resolve to stdlib, local code, or declared dep
- [build/templates/fabcheck.mk](build/templates/fabcheck.mk) — fabcheck include (optional `make fabcheck`, `make fabcheck-report`)
- [build/templates/fabcheck.sh](build/templates/fabcheck.sh) — vendorable bash script for fabcheck (multi-language import resolution)
- [build/templates/workflows/test.yml](build/templates/workflows/test.yml) — pytest with coverage (Python 3.14)
- [build/templates/workflows/quality.yml](build/templates/workflows/quality.yml) — format check + lint + typecheck (Python 3.14)
- [build/templates/workflows/test-reachability.yml](build/templates/workflows/test-reachability.yml) — document reachability check
- [build/templates/workflows/version-check.yml](build/templates/workflows/version-check.yml) — semver validation (optional)
- [build/templates/workflows/fabcheck.yml](build/templates/workflows/fabcheck.yml) — run fabcheck on push/PR, annotate missing findings, upload verdict (optional)

## Kubernetes

- [kubernetes/README.md](kubernetes/README.md)
- [kubernetes/helm-values.md](kubernetes/helm-values.md) — verify Helm value overrides with `helm template` before pushing
- [kubernetes/configmap-reload.md](kubernetes/configmap-reload.md) — restart Pods on ConfigMap/Secret content change (stakater/reloader, checksum annotation)
- [kubernetes/job-sync-hooks.md](kubernetes/job-sync-hooks.md) — Jobs are immutable; use Argo CD sync hooks for delete-and-recreate
- [kubernetes/kubectl-run-entrypoints.md](kubernetes/kubectl-run-entrypoints.md) — match `kubectl run -- <args>` to the image's ENTRYPOINT shape
- [kubernetes/gitops-polling-vs-webhooks.md](kubernetes/gitops-polling-vs-webhooks.md) — pair GitOps polling with webhooks day 1 (Argo CD, Flux); don't tighten poll interval
- [kubernetes/applicationset-safety.md](kubernetes/applicationset-safety.md) — Argo CD ApplicationSet safety defaults: `preserveResourcesOnDeletion: true` for stateful generators, `goTemplateOptions: [missingkey=error]` for Go templates
- [kubernetes/podsecurity-restricted-pod.md](kubernetes/podsecurity-restricted-pod.md) — five required Pod fields for the PodSecurity `restricted` profile (runAsNonRoot, runAsUser, seccompProfile, allowPrivilegeEscalation, capabilities.drop)
- [kubernetes/resource-limits.md](kubernetes/resource-limits.md) — set CPU request + memory request/limit; omit CPU limit (CFS throttling causes latency spikes with no node-protection benefit)

## Observability

- [observability/README.md](observability/README.md)
- [observability/metric-naming.md](observability/metric-naming.md) — Prometheus metric naming: `<prefix>_[<subsystem>_]<name>_<unit_or_role>`; unit suffixes (`_total`, `_seconds`, `_timestamp_seconds`, `_celsius`, `_percent`, ...); when to omit; rules for cardinality via labels.
- [observability/readiness-probes.md](observability/readiness-probes.md) — `/readyz` gates on mission-capability misconfig only; runtime dependency state lives in metrics, not the probe (avoids `ServiceMonitor` scrape gaps during dependency flaps).

## Claude Code

- [claude-code/skills.md](claude-code/skills.md) — authoring Claude Code skills (SKILL.md files)
- [claude-code/plugins.md](claude-code/plugins.md) — plugin structure, manifest schema, marketplace distribution
- [claude-code/hook-state-transitions.md](claude-code/hook-state-transitions.md) — hook event types, state machines, configuration
- [claude-code/agent-sdk-usage-data.md](claude-code/agent-sdk-usage-data.md) — extracting cost, token, context, and rate-limit data from the Agent SDK

## Planned (empty)

- [android/README.md](android/README.md) — Android development standards (placeholder)
- [mobile/README.md](mobile/README.md) — cross-platform mobile patterns (placeholder)
- [guides/README.md](guides/README.md) — process and tooling how-tos (placeholder)
