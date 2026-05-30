# Work Standards

[![test-markdown-lint](https://github.com/jewzaam/standards/actions/workflows/test-markdown-lint.yml/badge.svg)](https://github.com/jewzaam/standards/actions/workflows/test-markdown-lint.yml)
[![test-links](https://github.com/jewzaam/standards/actions/workflows/test-links.yml/badge.svg)](https://github.com/jewzaam/standards/actions/workflows/test-links.yml)
[![test-reachability](https://github.com/jewzaam/standards/actions/workflows/test-reachability.yml/badge.svg)](https://github.com/jewzaam/standards/actions/workflows/test-reachability.yml)

Reusable software development standards. Reference these instead of recreating project-specific guidelines.

AI agents: see [CLAUDE.md](CLAUDE.md) for a flat file index optimized for tool-based lookup.

## What lives here vs in knowledgebase

- **Standards (this repo):** prescriptive — "do it this way". Style, naming, structure, required targets, testing patterns.
- **[jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase):** descriptive — "this is how X works". Vendor quirks, tool internals, discovered failure modes.
- **[jewzaam/gws-cli-notes](https://github.com/jewzaam/gws-cli-notes):** topical sub-area of knowledgebase, kept separate due to size and shared external audience.

Hybrid topics (where prescriptive rules and descriptive mechanics both exist) cross-link between the two.

## Usage

Reference in your project:

```markdown
This project follows the [Work Standards](https://github.com/jewzaam/standards).
```

## [Common](common/README.md)

| Standard | Description |
|----------|-------------|
| [Versioning](common/versioning.md) | Semantic versioning and release conventions |
| [README Format](common/readme-format.md) | README structure and content |
| [Naming](common/naming.md) | Project and package naming conventions |
| [Git Submodules](common/submodules.md) | Git submodule conventions and workflows |
| [Git Worktrees](common/git-worktrees.md) | Worktree conventions, cleanup, AI-assisted parallel development |
| [Reachability](common/reachability.md) | Document reachability enforcement from entry points |
| [Temp Directories](common/tmp-dirs.md) | `.tmp-<slug>/` convention for named, git-ignored working directories |
| [Local Config Split](common/local-config-split.md) | `.example` template + `.gitignore` for per-environment config (secrets, endpoints) |
| [Git Remote Discovery](common/git-remote-discovery.md) | Discover remote names by URL match, not by hardcoded `origin`/`upstream` |

## [Python](python/README.md)

| Standard | Description |
|----------|-------------|
| [Style](python/style.md) | Python coding style and best practices |
| [Project Structure](python/project-structure.md) | Directory layout and required files |
| [Testing](python/testing.md) | Unit testing conventions, TDD, and documenting untested areas |
| [Complexity](python/complexity.md) | Cyclomatic complexity limit (10), ruff C901 enforcement |
| [Subprocess Security](python/subprocess-security.md) | Subprocess and localhost server security rules |
| [Shared Venv](python/shared-venv.md) | Shared `~/.venv/<family>/` for related projects, local `.venv` fallback |
| [Logging & Progress](python/logging-progress.md) | Logging, progress indicators, and output |
| [Settings Persistence](python/settings-persistence.md) | Dataclass settings with atomic JSON I/O |
| [Agent SDK Integration](python/agent-sdk.md) | Claude Agent SDK integration patterns |
| [Cross-Platform](python/cross-platform.md) | PATH shims for `python`/`python3`, `python -m <module>` rule |

### [Tkinter UI](python/tkinter/README.md)

| Standard | Description |
|----------|-------------|
| [Architecture](python/tkinter/architecture.md) | Application structure, controller pattern, window hierarchy |
| [Windows](python/tkinter/windows.md) | Window lifecycle, borderless mode, dragging, position persistence |
| [Widgets](python/tkinter/widgets.md) | Layout, StringVar, styling, fonts, context menus |
| [Threading](python/tkinter/threading.md) | Thread-safe UI updates, daemon threads, periodic polling |
| [Dialogs](python/tkinter/dialogs.md) | Modal dialogs, settings windows, color pickers |
| [Testing](python/tkinter/testing.md) | Two-layer testing strategy, root fixture, headless CI |
| [DPI Scaling](python/tkinter/dpi-scaling.md) | HiDPI detection, `tk scaling`, pixel dimension scaling |

### Python Templates

| Template | Description |
|----------|-------------|
| [Makefile](python/templates/Makefile) | Standard Makefile with all required targets |
| [pyproject.toml](python/templates/pyproject.toml) | Package config with standard dev dependencies |
| [test.mk](python/templates/test.mk) | Standard `test-*` target collection (includable `.mk`) |
| [version-check.mk](python/templates/version-check.mk) | Semver validation (includable `.mk`, optional `make version-check`) |
| [version-check.sh](python/templates/version-check.sh) | Shell script for semver validation |

## [.NET](dotnet/README.md)

| Standard | Description |
|----------|-------------|
| [Style](dotnet/style.md) | Async, nullable, .NET 8/10 language features, MVVM |
| [Project Structure](dotnet/project-structure.md) | csproj layout, TFM choice, deps |
| [Testing](dotnet/testing.md) | xUnit/NUnit, Moq, FluentAssertions, STA/WPF tests |

Knowledgebase counterpart in [jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase): NINA 3.x C# plugin (build, MEF, mediators, options, HTTP, logging, publishing).

## [CLI](cli/README.md)

| Standard | Description |
|----------|-------------|
| [Conventions](cli/conventions.md) | CLI argument and flag conventions |
| [Testing](cli/testing.md) | CLI entry point testing patterns |

## [Build and CI/CD](build/README.md)

| Standard | Description |
|----------|-------------|
| [Makefile](build/makefile.md) | Build targets and conventions |
| [GitHub Workflows](build/github-workflows.md) | CI/CD pipeline configuration |
| [Fabcheck](build/fabcheck.md) | Fabcheck opt-in steps, Make include, CI workflow |
| [GHCR Publishing](build/ghcr-publish.md) | Classic PAT for manual, `GITHUB_TOKEN` for Actions, OCI source label, push recipes |
| [JSON Schema Validation](build/json-schema-validation.md) | `npx ajv` invocation, required flags, Make target shape |
| [Local Workflow Testing](build/local-workflow-testing.md) | act install (worktree fork), pinned runner digest, required flags, usage |

Knowledgebase counterparts (mechanics, vendor behavior) live in [jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase): fabcheck internals, GHCR auth mechanics + first-publish behavior, act internals + security risks.

### Workflow Templates

| Template | Description |
|----------|-------------|
| [test.yml](build/templates/workflows/test.yml) | Run pytest with coverage (Python 3.14) |
| [quality.yml](build/templates/workflows/quality.yml) | Format check + lint + type check (Python 3.14) |
| [test-reachability.yml](build/templates/workflows/test-reachability.yml) | Verify document reachability from entry points |
| [version-check.yml](build/templates/workflows/version-check.yml) | Validate semver (optional, copy when opting in) |
| [fabcheck.yml](build/templates/workflows/fabcheck.yml) | Run fabcheck on push/PR, annotate missing findings, upload verdict |

### Build Templates

| Template | Description |
|----------|-------------|
| [fabcheck.mk](build/templates/fabcheck.mk) | Import fabrication detection (includable `.mk`, optional `make fabcheck`) |
| [fabcheck.sh](build/templates/fabcheck.sh) | Shell script for fabcheck (vendor into `scripts/`) |

## [Kubernetes](kubernetes/README.md)

| Standard | Description |
|----------|-------------|
| [Helm Values](kubernetes/helm-values.md) | Verify Helm value overrides with `helm template` before pushing |
| [ApplicationSet Safety](kubernetes/applicationset-safety.md) | Argo CD ApplicationSet: `preserveResourcesOnDeletion: true` for stateful generators, `goTemplateOptions: [missingkey=error]` for Go templates |
| [ConfigMap Reload](kubernetes/configmap-reload.md) | ConfigMap/Secret reload strategies (Reloader preferred, Helm checksum, manual) |
| [PodSecurity Restricted Pod](kubernetes/podsecurity-restricted-pod.md) | Five required Pod fields for the PodSecurity `restricted` profile + template |
| [Resource Limits](kubernetes/resource-limits.md) | Set CPU request + memory request/limit; omit CPU limit |
| [Windows MSYS `kubectl`](kubernetes/windows-msys-kubectl.md) | MSYS / Git-Bash on Windows rewrites POSIX paths in `kubectl.exe` argv; stdin pipes replace `kubectl cp`, relative paths inside `kubectl exec -- ...` |
| [Non-Root Sidecar Scripts](kubernetes/non-root-sidecar-scripts.md) | `node:*-alpine` non-root sidecars: `NPM_CONFIG_PREFIX` + `NPM_CONFIG_CACHE` for `npm install -g`; busybox-only tools because `apk add` needs root |

Knowledgebase counterparts (mechanics, failure modes) live in [jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase): why ApplicationSet/Helm defaults are dangerous, why the kubelet doesn't restart on CM change, PodSecurity admission rejection format, CFS throttling mechanics, Job immutability, `kubectl run` entrypoint shapes, GitOps polling vs webhooks, image tag caching.

## [Observability](observability/README.md)

| Standard | Description |
|----------|-------------|
| [Metric Naming](observability/metric-naming.md) | Prometheus metric naming: `<prefix>_[<subsystem>_]<name>_<unit_or_role>`; unit suffixes; cardinality via labels |
| [Readiness Probes](observability/readiness-probes.md) | `/readyz` startup-prerequisite checklist; antipatterns |

Knowledgebase counterparts in [jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase): why readiness-probe split matters (ServiceMonitor scrape gaps), shell scraper truncation rule for `prometheus_client` float counters.

## Claude Code

| Standard | Description |
|----------|-------------|
| [Skills](claude-code/skills.md) | Authoring Claude Code skills (SKILL.md files) |
| [Plugins](claude-code/plugins.md) | Plugin structure, manifest schema, marketplace distribution |

Knowledgebase counterparts (descriptive mechanics, vendor quirks) live in [jewzaam/knowledgebase](https://github.com/jewzaam/knowledgebase): skills enforcement detail, plugin caching/env-vars/marketplace mechanics, hook state transitions, Agent SDK usage data, OAuth token taxonomy.

## Planned Sections

| Section | Description |
|---------|-------------|
| [Android](android/README.md) | Android application development standards |
| [Mobile](mobile/README.md) | Cross-platform mobile development patterns |
| [Guides](guides/README.md) | Process and tooling how-tos |

## Guiding Principles

1. **Consistency** - All projects follow the same patterns
2. **Simplicity** - Minimal configuration, sensible defaults
3. **Automation** - CI catches issues before merge
4. **Discoverability** - Standard locations for everything

## Critical Constraints

**Git LFS is prohibited**

- GitHub LFS has a $0 budget limit and is not funded
- Do not track binary files with Git LFS
- Generate test fixtures programmatically or use minimal files (< 100KB)
- Large binary files will cause CI failures and block development
