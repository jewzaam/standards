# Local Workflow Testing

Testing GitHub Actions workflows locally with [act](https://github.com/nektos/act).

> How act works, runner image internals, security risks, and runner-image
> differences from GitHub-hosted runners live in
> [knowledgebase/build/local-workflow-testing.md](https://github.com/jewzaam/knowledgebase/blob/main/build/local-workflow-testing.md).

## Install: worktree-support fork

Upstream act does not work inside git worktrees. Use the fork
`jewzaam/act` branch `fix/git-worktree-support` (commit `c2a7412a`) until
[nektos/act#6075](https://github.com/nektos/act/pull/6075) is merged and a
new upstream release is tagged.

Module path mismatch prevents `go install`. Clone + build:

```bash
git clone --depth 1 --branch fix/git-worktree-support \
  https://github.com/jewzaam/act /tmp/act-fork \
  && go build -C /tmp/act-fork -o "$(go env GOPATH)/bin/act" main.go \
  && rm -rf /tmp/act-fork
```

## Runner image: pin by digest

Use the approved `catthehacker/ubuntu` runner image pinned by digest:

```text
docker.io/catthehacker/ubuntu:act-22.04@sha256:d83455c10c9a31c9c944a4c5628360c6c374983fa6616bd2439ab88b05ae2046
```

Never use mutable tags (`:latest`, `:act-latest`, `:act-22.04` without
digest).

### Updating the pinned digest

1. Review the Dockerfile and `act.sh` changes since the last pinned version
2. Pull the new image: `podman pull docker.io/catthehacker/ubuntu:<new-tag>`
3. Get the digest: `podman inspect docker.io/catthehacker/ubuntu:<new-tag> --format='{{.Digest}}'`
4. Test with the full command line from Usage below
5. Update the digest in this document

### Custom runner image

Projects that need additional system packages (e.g., `python3-tk` for
tkinter) should build a local image layered on the pinned base.

```dockerfile
FROM docker.io/catthehacker/ubuntu:act-22.04@sha256:d83455c10c9a31c9c944a4c5628360c6c374983fa6616bd2439ab88b05ae2046
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3-tk \
 && rm -rf /var/lib/apt/lists/*
```

```bash
podman build -t act-runner:local -f Dockerfile.act-runner .
```

## Required flags

Act mounts the Docker socket into every container by default, granting
workflow steps root-equivalent access to the host. Always pass
`--container-daemon-socket=-` unless a workflow explicitly requires Docker
access.

| Flag | Default | Required Value | Why |
|------|---------|----------------|-----|
| `--container-daemon-socket` | `/var/run/docker.sock` | `-` | Docker socket mount gives containers root-equivalent host access |
| `--privileged` | `false` | `false` (never enable) | Bypasses all container security |
| `--insecure-secrets` | `false` | `false` (never enable) | Disables secret masking entirely |

## Configuration

Act reads flags from config files (one flag per line), then appends CLI
args. CLI always overrides config files.

Config file load order:

1. `~/.config/act/actrc` (XDG spec)
2. `~/.actrc`
3. `.actrc` in the current directory (project-level)

### Global config (`~/.config/act/actrc`)

```text
-P ubuntu-latest=localhost/act-runner:local
-P ubuntu-22.04=localhost/act-runner:local
```

### Project-level config (`.actrc`)

Project-level `.actrc` files should be gitignored — they reflect local
environment choices, not project requirements.

## Container runtime

Use Podman rootless when available. Ensure the user socket is active:

```bash
systemctl --user is-active podman.socket  # should print "active"
```

Point act at the Podman socket:

```bash
export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock
```

## Usage

With the global `~/.config/act/actrc` configured:

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

### Container reuse

Add `--reuse` to keep containers between runs. First run is slow (image
pull, dependency install). Subsequent runs reuse the container with packages
already installed.

## Required workflow patterns

### Always `apt-get update` before `apt-get install`

```yaml
- name: Install system deps
  run: |
    apt-get update
    apt-get install -y --no-install-recommends <pkg>
```

### Validate compose files with `docker compose`, not `podman-compose`

```yaml
- name: Validate compose file
  run: docker compose -f docker-compose.yml config > /dev/null
```

For local development on machines that only have podman, drive validation
through a Makefile target that autodetects the available compose tool. See
[makefile.md — Compose tool autodetect](makefile.md#compose-tool-autodetect).

## Discovering required PR checks

```bash
gh api repos/$(gh repo view --json nameWithOwner --jq '.nameWithOwner')/rules/branches/$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main) \
  --jq '.[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context'
```

Cross-reference with `act --list` to identify which are locally runnable.

## When to apply

Any project with GitHub Actions workflows worth iterating on locally.
