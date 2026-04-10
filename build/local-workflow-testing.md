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

v0.2.87 was reviewed on 2026-04-10 and is safe to use with the
required flags below. Pin to this version. Before upgrading, check
release notes for security-relevant changes.

Install via Go:

```bash
go install github.com/nektos/act@v0.2.87
```

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

- **Docker required** — needs a running Docker daemon
- **Not identical to GitHub** — hosted runner tools, OIDC tokens, and
  GitHub-managed secrets are unavailable locally

## Project Health

As of April 2026: MIT licensed (fork/modify permitted with copyright
notice), actively maintained, ~35 human contributors. Primary
maintainers are ChristopherHX and Casey Lee (project creator). 40% of
commits are automated dependency bumps (dependabot).
