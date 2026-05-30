# GitHub Container Registry (GHCR) Publishing

Conventions for publishing container images to `ghcr.io/<owner>/<image>`,
both from a developer workstation and from GitHub Actions.

> Why fine-grained PATs are unsupported, why the OCI source label is
> load-bearing, and why first-publish defaults to private live in
> [knowledgebase/build/ghcr-publish.md](https://github.com/jewzaam/knowledgebase/blob/main/build/ghcr-publish.md).

## Rules

1. **Do not** use a fine-grained PAT to authenticate to `ghcr.io`. No
   Packages scope exists in fine-grained PATs.
2. **Manual workstation pushes:** use a classic PAT with the `write:packages`
   scope. Pair with the shortest expiry that matches your push cadence and
   rotate aggressively.
3. **Automated Actions pushes:** use the auto-issued `GITHUB_TOKEN`. Declare
   the package write permission explicitly:

   ```yaml
   permissions:
     contents: read
     packages: write
   ```

4. **Every Dockerfile** that ships to GHCR must include the
   `org.opencontainers.image.source` LABEL pointing at the repo HTTPS URL:

   ```dockerfile
   LABEL org.opencontainers.image.source="https://github.com/<owner>/<repo>"
   ```

   The label is what links the package to its repo. Add at first push or
   re-publish.
5. **First-push checklist for OSS images:** flip package visibility to public
   via Package Settings → Change visibility → Public. Skip for
   private/internal images.

## Manual push recipe

`podman` and `docker` are interchangeable in the recipe below.

```sh
echo $GHCR_PAT | podman login ghcr.io -u <username> --password-stdin
podman tag local-image:tag ghcr.io/<owner>/<image>:<tag>
podman push ghcr.io/<owner>/<image>:<tag>
```

`--password-stdin` keeps the PAT out of process listings and shell history.
Never embed the PAT in scripts or commit it to an env file. Source it from a
secrets manager or paste it into an interactive shell session.

## Automated push recipe (Actions skeleton)

This is the workflow shape, not a copy-paste-ready file — fill in triggers,
build context, and tag computation per project.

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
`secrets.GITHUB_TOKEN` is the auto-issued, run-scoped token — no need to
create or store anything.

## When to apply

Every project that publishes images to GHCR.
