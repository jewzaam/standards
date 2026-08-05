# Standards Repository

Reusable software development standards referenced by other projects via
`~/source/standards/` in the user's global CLAUDE.md. This is a reference
library — nothing to build or deploy. Other projects read these files when
making decisions about style, structure, testing, and CI.

The full organized index with section descriptions is in
[README.md](README.md). Every file is also linked directly below for
tool-based lookup.

Run `make help` for available validation targets.

## What lives here vs in knowledgebase

- **Here (standards):** prescriptive — "do it this way". Style, naming, project
  structure, required Makefile targets, testing patterns, conventions.
- **[jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase):** descriptive
  — "this is how X works". Vendor quirks, tool internals, API taxonomies,
  discovered failure modes.
- **[jewzaam/gws-cli-notes](https://github.com/jewzaam/gws-cli-notes):** topical
  sub-area of knowledgebase, kept separate due to size and shared external audience.

If the doc tells you *what to do in your code* it belongs here. If it tells
you *how the outside world behaves* it belongs in knowledgebase.

Many sections below have a "Knowledgebase counterparts" sub-list pointing at
the descriptive companion docs.

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
- [common/commit-messages.md](common/commit-messages.md) — Conventional Commits 1.0.0 spec, valid types (8), what NOT to use (chore, style)
- [common/submodules.md](common/submodules.md) — git submodule conventions and workflows
- [common/git-worktrees.md](common/git-worktrees.md) — worktree conventions, cleanup, AI-assisted parallel development
- [common/reachability.md](common/reachability.md) — document reachability enforcement from entry points
- [common/tmp-dirs.md](common/tmp-dirs.md) — `.tmp-<slug>/` convention for named, git-ignored working directories
- [common/local-config-split.md](common/local-config-split.md) — `.example` template + `.gitignore` for per-environment config (secrets, endpoints)
- [common/git-remote-discovery.md](common/git-remote-discovery.md) — discover remote names by URL match, not by hardcoded `origin`/`upstream`
- [common/doc-authority.md](common/doc-authority.md) — skills own their domain (project docs link, don't copy); a repo with hands-on domain experience outranks the generalized cross-project standard for that domain

## Python

- [python/README.md](python/README.md)
- [python/style.md](python/style.md) — coding style, imports, type hints
- [python/project-structure.md](python/project-structure.md) — directory layout, required files
- [python/testing.md](python/testing.md) — pytest conventions, TDD, documenting untested areas
- [python/complexity.md](python/complexity.md) — cyclomatic complexity limit (10), ruff C901 enforcement
- [python/subprocess-security.md](python/subprocess-security.md) — subprocess and localhost server security rules
- [python/shared-venv.md](python/shared-venv.md) — shared `~/.venv/<family>/` for related projects, local `.venv` fallback
- [python/logging-progress.md](python/logging-progress.md) — logger setup, `--log-file`, progress bars
- [python/settings-persistence.md](python/settings-persistence.md) — dataclass settings with atomic JSON I/O
- [python/agent-sdk.md](python/agent-sdk.md) — Claude Agent SDK integration, threading with tkinter, permission control
- [python/cross-platform.md](python/cross-platform.md) — PATH shims for `python`/`python3`, `python -m <module>` rule

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

Knowledgebase counterpart in [jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase):

- `dotnet/nina-plugin.md` — NINA 3.x C# plugin: build, MEF, mediators, options, HTTP, logging, publishing

## CLI

- [cli/README.md](cli/README.md)
- [cli/conventions.md](cli/conventions.md) — argument naming, flags, `--log-file`, `--debug`
- [cli/testing.md](cli/testing.md) — testing main() with sys.argv patching

## Build and CI/CD

- [build/README.md](build/README.md)
- [build/makefile.md](build/makefile.md) — Makefile conventions, required targets, `PACKAGE_NAME`, `VENV_DIR`
- [build/github-workflows.md](build/github-workflows.md) — workflow conventions, Python versions, triggers
- [build/fabcheck.md](build/fabcheck.md) — fabcheck opt-in steps, Make include, CI workflow
- [build/ghcr-publish.md](build/ghcr-publish.md) — GHCR publishing rules: classic PAT for manual, `GITHUB_TOKEN` for Actions, OCI source label, push recipes
- [build/json-schema-validation.md](build/json-schema-validation.md) — `npx ajv` invocation, required flags, Make target shape
- [build/local-workflow-testing.md](build/local-workflow-testing.md) — act install (worktree fork), pinned runner digest, required flags, usage
- [build/templates/fabcheck.mk](build/templates/fabcheck.mk) — fabcheck include (optional `make fabcheck`, `make fabcheck-report`)
- [build/templates/fabcheck.sh](build/templates/fabcheck.sh) — vendorable bash script for fabcheck (multi-language import resolution)
- [build/templates/workflows/test.yml](build/templates/workflows/test.yml) — pytest with coverage (Python 3.14)
- [build/templates/workflows/quality.yml](build/templates/workflows/quality.yml) — format check + lint + typecheck (Python 3.14)
- [build/templates/workflows/test-reachability.yml](build/templates/workflows/test-reachability.yml) — document reachability check
- [build/templates/workflows/version-check.yml](build/templates/workflows/version-check.yml) — semver validation (optional)
- [build/templates/workflows/fabcheck.yml](build/templates/workflows/fabcheck.yml) — run fabcheck on push/PR, annotate missing findings, upload verdict (optional)

Knowledgebase counterparts (mechanics, vendor quirks) live in [jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase):

- `build/fabcheck.md` — fabcheck language coverage, dist-name resolution modes, verdict.json shape, known gaps
- `build/ghcr-publish.md` — why fine-grained PATs fail, classic PAT scoping, OCI label linkage mechanics, first-publish-private behavior
- `build/local-workflow-testing.md` — how act works, runner image internals, security risks, runner-image differences from GitHub-hosted

## Kubernetes

- [kubernetes/README.md](kubernetes/README.md)
- [kubernetes/helm-values.md](kubernetes/helm-values.md) — verify Helm value overrides with `helm template` before pushing
- [kubernetes/applicationset-safety.md](kubernetes/applicationset-safety.md) — Argo CD ApplicationSet safety defaults: `preserveResourcesOnDeletion: true` for stateful generators, `goTemplateOptions: [missingkey=error]` for Go templates
- [kubernetes/configmap-reload.md](kubernetes/configmap-reload.md) — ConfigMap/Secret reload strategies (Reloader preferred, Helm checksum, manual)
- [kubernetes/podsecurity-restricted-pod.md](kubernetes/podsecurity-restricted-pod.md) — five required Pod fields for PodSecurity `restricted` profile + template
- [kubernetes/resource-limits.md](kubernetes/resource-limits.md) — set CPU request + memory request/limit; omit CPU limit
- [kubernetes/windows-msys-kubectl.md](kubernetes/windows-msys-kubectl.md) — MSYS / Git-Bash on Windows rewrites POSIX paths in `kubectl.exe` argv; use stdin pipes instead of `kubectl cp`, relative paths inside `kubectl exec -- ...`
- [kubernetes/non-root-sidecar-scripts.md](kubernetes/non-root-sidecar-scripts.md) — `node:*-alpine` (and similar) non-root sidecars: set `NPM_CONFIG_PREFIX` + `NPM_CONFIG_CACHE` for `npm install -g`; `apk add` unavailable, use busybox tools only

Knowledgebase counterparts (mechanics, vendor behavior, failure modes) live in [jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase):

- `kubernetes/applicationset-safety.md` — why these defaults are dangerous (cascade delete, silent empty-string substitution)
- `kubernetes/helm-values.md` — Helm silent-ignore behavior, subchart key drift, grafana failure mode
- `kubernetes/configmap-reload.md` — why the kubelet doesn't restart Pods on CM/Secret content change; Reloader direct-mount gotcha
- `kubernetes/podsecurity-restricted-pod.md` — admission-rejection wall-of-text format and why it surfaces only at admission
- `kubernetes/resource-limits.md` — CFS bandwidth controller throttling mechanics; why CPU limits hurt
- `kubernetes/job-sync-hooks.md` — Jobs are immutable; Argo CD sync hooks for delete-and-recreate
- `kubernetes/kubectl-run-entrypoints.md` — match `kubectl run -- <args>` to image's ENTRYPOINT shape
- `kubernetes/gitops-polling-vs-webhooks.md` — Argo CD default 3-min poll latency; webhook setup
- `kubernetes/image-tag-immutability.md` — tags are build identifiers; kubelet `IfNotPresent` cache behavior

## Observability

- [observability/README.md](observability/README.md)
- [observability/metric-naming.md](observability/metric-naming.md) — Prometheus metric naming: `<prefix>_[<subsystem>_]<name>_<unit_or_role>`; unit suffixes (`_total`, `_seconds`, `_timestamp_seconds`, `_celsius`, `_percent`, ...); when to omit; rules for cardinality via labels.
- [observability/readiness-probes.md](observability/readiness-probes.md) — `/readyz` startup-prerequisite checklist; antipatterns
- [observability/exposition-format-consumption.md](observability/exposition-format-consumption.md) — shell scrapers must truncate `prometheus_client` float values (`${var%.*}`) before POSIX `[ -gt ]` integer comparison; rationale framed by how the exposition format emits floats

Knowledgebase counterpart (mechanics, vendor behavior) live in [jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase):

- `observability/readiness-probes.md` — why mission-capability vs dependency split matters (ServiceMonitor scrape gaps)

## Claude Code

- [claude-code/skills.md](claude-code/skills.md) — authoring Claude Code skills (SKILL.md files)
- [claude-code/plugins.md](claude-code/plugins.md) — plugin structure, manifest schema, marketplace distribution

Knowledgebase counterparts (descriptive mechanics, vendor quirks) live in [jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase):

- `claude-code/skills.md` — `allowed-tools` enforcement detail, shell injection mechanics, frontmatter typo behavior
- `claude-code/plugins.md` — plugin caching, env vars, marketplace source types, CLI commands, common failure modes
- `claude-code/hook-state-transitions.md` — hook event types, state machines, configuration
- `claude-code/agent-sdk-usage-data.md` — extracting cost, token, context, rate-limit data from the Agent SDK
- `claude-code/oauth-tokens.md` — Anthropic OAuth token taxonomy, endpoint compatibility, error-envelope quirks, K8s Secret tmpfs reset

## Planned (empty)

- [android/README.md](android/README.md) — Android development standards (placeholder)
- [mobile/README.md](mobile/README.md) — cross-platform mobile patterns (placeholder)
- [guides/README.md](guides/README.md) — process and tooling how-tos (placeholder)
