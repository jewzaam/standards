# GitHub Container Registry (GHCR) Publishing

Gotchas and conventions for publishing container images to
`ghcr.io/<owner>/<image>`, both from a developer workstation and from
GitHub Actions.

## Fine-grained PATs do not support GHCR

**Pattern.** Do not attempt to authenticate to `ghcr.io` with a
GitHub fine-grained personal access token.

**Why.** The fine-grained PAT permission set has no Packages scope.
Verified against
[GitHub's "Permissions required for fine-grained personal access tokens"](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens)
on 2026-05-24 — the document contains no Packages permission. The
community feature request has been open since 2022 at
[github/community discussion #36441](https://github.com/orgs/community/discussions/36441).
Portainer's March 2026 documentation states plainly that "GitHub does
not currently support the use of fine-grained tokens for registry
access".

**When to apply.** Always — until GitHub ships a Packages permission
in fine-grained PATs. The failure mode is silent: the fine-grained UI
simply does not surface a Packages toggle, so people hunt for it for
roughly an hour before concluding it does not exist.

## Classic PAT with `write:packages` for manual pushes

**Pattern.** For manual pushes from a developer workstation, use a
classic PAT with the `write:packages` scope (which implicitly grants
`read:packages`).

**Why.** Classic PATs are the only manual-workstation push path
GitHub currently supports for GHCR.

**Caveat.** Classic PATs cannot be scoped to a single repository or
package. The token can push to any user-owned package. Use the
shortest expiry that matches your push cadence and rotate aggressively.

**When to apply.** Local image builds the developer wants to publish
ad-hoc, before (or instead of) wiring up an Actions workflow.

## `GITHUB_TOKEN` for automated pushes from Actions

**Pattern.** For automated publishes, drive the push from a GitHub
Actions workflow using the auto-issued `GITHUB_TOKEN`.

**Why.** `GITHUB_TOKEN` is the only per-repo-scoped path to GHCR. It
is minted per workflow run, scoped to the running workflow's
repository, and disappears when the run ends. No long-lived
credential to rotate.

**When to apply.** Any project where the image is built and pushed
on tag, release, or main-branch merge. Default to this over the
classic-PAT path as soon as a workflow exists.

The workflow YAML must declare the package write permission
explicitly — `GITHUB_TOKEN` defaults to read-only for packages:

```yaml
permissions:
  contents: read
  packages: write
```

## Link the package to its source repo via OCI label

**Pattern.** Add an `org.opencontainers.image.source` LABEL to the
Dockerfile pointing at the repo's HTTPS URL.

```dockerfile
LABEL org.opencontainers.image.source="https://github.com/<owner>/<repo>"
```

**Why.** On first push, GHCR reads this label and links the package
to the repository. The package then appears in the repo's Packages
sidebar and becomes eligible for provenance attestation. Without the
label, the package is orphaned at the account level — discoverable
only by typing the full URL.

**When to apply.** Every Dockerfile that ships to GHCR. The label is
cheap (one line) and the linkage is impossible to add later without
re-publishing.

## First publish defaults to private

**Pattern.** After the first push, an operator must flip the package
to public via the package's web UI: Package Settings → Change
visibility → Public.

**Why.** GHCR's default visibility is private. For open-source
images, this means `docker pull` returns 401 until the visibility is
changed. This is a one-time, per-package, click-through action — no
API or workflow flag flips it.

**When to apply.** Every new OSS image, immediately after the first
successful push. Skip for private/internal images.

## Manual push recipe

`podman` and `docker` are interchangeable in the recipe below.

```sh
echo $GHCR_PAT | podman login ghcr.io -u <username> --password-stdin
podman tag local-image:tag ghcr.io/<owner>/<image>:<tag>
podman push ghcr.io/<owner>/<image>:<tag>
```

`--password-stdin` keeps the PAT out of process listings and shell
history. Never embed the PAT in scripts or commit it to an env file.
Source it from a secrets manager or pasted into an interactive shell
session.

## Automated push recipe (GitHub Actions skeleton)

This is the workflow shape, not a copy-paste-ready file — fill in
triggers, build context, and tag computation per project.

```yaml
permissions:
  contents: read
  packages: write

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
```

`github.actor` is the user that triggered the workflow run.
`secrets.GITHUB_TOKEN` is the auto-issued, run-scoped token — no need
to create or store anything.

## Provenance

Surfaced while building
[claude-quota-exporter](https://github.com/jewzaam/claude-quota-exporter)
— added a Makefile push-image target and walked the operator through
the fine-grained-token dead-end before landing on classic PAT for the
manual path.
