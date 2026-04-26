# Local Workflow Testing

Testing GitHub Actions workflows locally before pushing, using
[act](https://github.com/nektos/act).

## How act Works

Act parses `.github/workflows/` YAML files, builds an execution plan of
stages (serial) and jobs (parallel), and runs each step inside Docker
containers. Remote actions (e.g., `uses: actions/checkout@v4`) are
cloned from GitHub and executed inside the container. The execution
model intentionally mirrors GitHub's hosted runners.

## Safety Assessment

| Use Case | Safe? | Notes |
|----------|-------|-------|
| Local dev with trusted workflows | Yes | You control the workflow content; container isolation is sufficient |
| Testing workflows before pushing to GitHub | Yes | Risks are comparable to GitHub-hosted runners |
| Running untrusted or third-party workflows | No | Docker socket access enables container escape |
| Shared CI/CD infrastructure | No | Multiple users could exploit Docker socket; secret masking is best-effort |

## Reviewed Version

v0.2.87+worktree from fork `jewzaam/act` branch
`fix/git-worktree-support` (commit `c2a7412a`). Adds git worktree
reconstitution and `.git` skip in FileCollector. Upstream PR:
[nektos/act#6074](https://github.com/nektos/act/issues/6074).
Pin to this fork until the [PR 6075](https://github.com/nektos/act/pull/6075) is merged and a new upstream release
is tagged.

Install from fork (module path mismatch prevents `go install`):

```bash
git clone --depth 1 --branch fix/git-worktree-support \
  https://github.com/jewzaam/act /tmp/act-fork \
  && go build -C /tmp/act-fork -o "$(go env GOPATH)/bin/act" main.go \
  && rm -rf /tmp/act-fork
```

### Verifying the installed binary

The fork does not change the version string or module path (`go.mod`
still declares `github.com/nektos/act`), so `act --version` and the
module path in build metadata are identical to upstream.

**Quick check — built from source vs tagged release:**

```bash
go version -m "$(which act)" | grep 'github.com/nektos/act'
```

- `github.com/nektos/act  (devel)` → built from source (expected for
  the fork clone+build install above)
- `github.com/nektos/act  v0.2.87` → installed from a tagged upstream
  release via `go install`

`(devel)` confirms the binary was built from a local checkout rather
than a published module version. It does not prove which fork — only
that the install method was clone+build.

**Definitive check — worktree behavior:**

Run act from inside a git worktree. Upstream act fails because it
cannot resolve `.git` file references; the fork reconstitutes the
real `.git` directory and succeeds.

## Runner Image

GitHub Actions steps (`uses: actions/checkout@v4`, `actions/setup-python@v5`,
etc.) are Node.js applications. Official Ubuntu images do not include Node.js
and cannot run these steps. Act requires a runner image that provides Node.js
and the environment GitHub Actions expects.

### Approved image

[catthehacker/ubuntu](https://github.com/catthehacker/docker_images) provides
purpose-built runner images for act. The Dockerfiles are public and auditable.

**Reviewed image:** `act-22.04` — reviewed on 2026-04-10.

**Pinned digest (required):**

```text
docker.io/catthehacker/ubuntu:act-22.04@sha256:d83455c10c9a31c9c944a4c5628360c6c374983fa6616bd2439ab88b05ae2046
```

Never use mutable tags (`:latest`, `:act-latest`, `:act-22.04` without
digest). A pinned digest is immutable — what you audit is what runs.

### What the image contains

Built from `ubuntu:22.04` with a single install script (`linux/ubuntu/scripts/act.sh`):

- **System packages:** ssh, curl, jq, wget, sudo, gnupg, ca-certificates,
  zstd, zip, unzip, python3-pip, python3-venv, pipx
- **Git:** latest from ppa:git-core/ppa, plus git-lfs
- **Docker CLI:** moby-engine, moby-cli, moby-buildx, moby-compose (from
  Microsoft's Ubuntu repo). Inert when `--container-daemon-socket=-` is used
- **Node.js:** versions 20 and 24, downloaded from nodejs.org
- **yq:** from GitHub releases with checksum verification

No services, daemons, cron jobs, or telemetry. Build-time only — the script
installs packages and exits.

### Custom runner image

Projects that need additional system packages (e.g., `python3-tk` for
tkinter) should build a local image layered on the pinned base. This
avoids slow installs on every act run.

```dockerfile
FROM docker.io/catthehacker/ubuntu:act-22.04@sha256:d83455c10c9a31c9c944a4c5628360c6c374983fa6616bd2439ab88b05ae2046
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3-tk \
 && rm -rf /var/lib/apt/lists/*
```

Build and tag locally (no registry needed):

```bash
podman build -t act-runner:local -f Dockerfile.act-runner .
```

The image inherits the security properties of the pinned base. Only
add packages needed for local testing — keep the layer minimal. When
the base digest is updated, rebuild the custom image.

## Configuration

Act reads flags from config files (one flag per line), then appends
CLI args. For array flags like `-P`, later values for the same key
overwrite earlier ones. For scalar flags like
`--container-daemon-socket`, last value wins. CLI always overrides
config files.

Config file load order:

1. `~/.config/act/actrc` (XDG spec)
2. `~/.actrc`
3. `.actrc` in the current directory (project-level)

### Global config (`~/.config/act/actrc`)

Use for the runner image mapping. Required flags and other overrides
are set explicitly where act is invoked.

```text
-P ubuntu-latest=localhost/act-runner:local
-P ubuntu-22.04=localhost/act-runner:local
```

### Project-level config (`.actrc`)

Overrides global config for a specific project. Project-level `.actrc`
files should be gitignored — they reflect local environment choices,
not project requirements.

### Updating the pinned digest

When updating to a new image version:

1. Review the Dockerfile and `act.sh` changes since the last pinned version
2. Pull the new image: `podman pull docker.io/catthehacker/ubuntu:<new-tag>`
3. Get the digest: `podman inspect docker.io/catthehacker/ubuntu:<new-tag> --format='{{.Digest}}'`
4. Test with the full command line from the Usage section below
5. Update the digest in this document

## Container Runtime

Act supports both Docker and Podman. **Podman rootless is preferred** —
it runs containers in a user namespace with no root daemon, providing
stronger isolation than Docker.

### Podman setup

Ensure the Podman user socket is active:

```bash
systemctl --user is-active podman.socket  # should print "active"
```

Point act at the Podman socket via `DOCKER_HOST`:

```bash
export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock
```

### Risk comparison

| Vector | Docker | Podman rootless |
|--------|--------|-----------------|
| Container escape | Root on host | Unprivileged user (your own UID) |
| Daemon | Runs as root | No daemon — direct fork/exec |
| Socket access | Root-equivalent | User-scoped, no privilege escalation |

With Podman rootless + `--container-daemon-socket=-`, the risk profile
is comparable to running `pip install` in your own terminal. The container
isolation actually makes it *more* constrained than running commands natively.

## Required Flags

Act mounts the Docker socket into every container by default, granting
workflow steps root-equivalent access to the host. Always pass
`--container-daemon-socket=-` unless a workflow explicitly requires
Docker access.

| Flag | Default | Required Value | Why |
|------|---------|----------------|-----|
| `--container-daemon-socket` | `/var/run/docker.sock` | `-` | Docker socket mount gives containers root-equivalent host access |
| `--privileged` | `false` | `false` (never enable) | Bypasses all container security — device access, kernel modules, iptables |
| `--insecure-secrets` | `false` | `false` (never enable) | Disables secret masking entirely |

## Usage

With the global `~/.config/act/actrc` configured, invocations are
minimal:

```bash
act pull_request
act pull_request -j <job-name>
act pull_request -W .github/workflows/ci.yml -j <job-name>
```

Full command without config files (all flags explicit):

```bash
DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock \
act pull_request \
  -P ubuntu-latest=docker.io/catthehacker/ubuntu:act-22.04@sha256:d83455c10c9a31c9c944a4c5628360c6c374983fa6616bd2439ab88b05ae2046 \
  --container-daemon-socket=- \
  --privileged=false \
  --insecure-secrets=false \
  -W .github/workflows/ci.yml \
  -j <job-name>
```

### Targeting specific jobs

Use `-j <job-name>` to run a single job, or omit it to run all jobs
triggered by the specified event. Use `act --list` to see available
jobs and their stages.

### Container reuse

Add `--reuse` to keep containers between runs. First run is slow
(image pull, dependency install). Subsequent runs reuse the container
with packages already installed.

### Jobs requiring Docker access

Jobs that use testcontainers, docker-compose, or podman-compose need
the Docker socket mounted inside the container. These will fail with
`--container-daemon-socket=-`. This is expected — leave those checks
for CI. The `--container-daemon-socket=-` flag is non-negotiable for
local runs.

## Discovering Required PR Checks

To find which workflow jobs are required for PRs (configured in
GitHub branch protection or repository rulesets):

```bash
gh api repos/$(gh repo view --json nameWithOwner --jq '.nameWithOwner')/rules/branches/$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main) \
  --jq '.[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context'
```

This returns the job names that must pass. Cross-reference with
`act --list` to identify which are locally runnable.

## Security Risks

Act's defaults are permissive because its goal is fidelity to GitHub's
execution model. GitHub's hosted runners also mount Docker, allow
privileged containers, accept mutable action refs, and use
string-replacement secret masking. Locking these down by default would
break workflows that work on GitHub.

### Docker socket exposure

The Docker socket mount is the primary risk. A workflow step with
socket access can create privileged containers, access host filesystems,
or escape the container entirely. This is equivalent to root on the
host.

### Environment variable injection

Workflows can write to `GITHUB_ENV` to set environment variables for
subsequent steps, including `PATH` and `LD_PRELOAD`. The env file
parser accepts multi-line values and buffers up to 1GB. This mirrors
real GitHub Actions behavior. Mitigated by container isolation, but one
step can influence the environment of all subsequent steps.

### Remote action integrity

Actions referenced by tag or branch use mutable Git refs — if the
upstream repo is compromised, malicious code executes. Full commit SHAs
are accepted but not required. No signature verification is performed.
This matches GitHub's own model.

### Secret masking

Secret masking uses string replacement on log output. Secrets can leak
through encoding (base64, hex, URL encoding), case differences, or
structured output that splits values across fields.

## Limitations

- **Container runtime required** — needs Docker or Podman
- **Not identical to GitHub** — hosted runner tools, OIDC tokens, and
  GitHub-managed secrets are unavailable locally
- **Jobs needing Docker inside containers** will fail with the required
  `--container-daemon-socket=-` flag (testcontainers, compose, etc.)

## Project Health

As of April 2026: MIT licensed (fork/modify permitted with copyright
notice), actively maintained, ~35 human contributors. Primary
maintainers are ChristopherHX and Casey Lee (project creator). 40% of
commits are automated dependency bumps (dependabot).
