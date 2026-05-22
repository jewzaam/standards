# Git Remote Discovery

Scripts that operate on git remotes must discover remote names by URL match,
never by hardcoded convention.

## The problem

`origin` and `upstream` are conventions, not contracts. Developers differ on
which name points where:

- Some set `origin` to their fork and `upstream` to the canonical repo.
- Others set `origin` to the canonical repo and `upstream` to their fork.
- Some have neither name — just a custom remote like `fork` or `canonical`.

A script that hardcodes `git push origin` or `git fetch upstream` works for
the author and breaks silently for everyone else. "Breaks silently" because
the wrong remote may still exist; the command succeeds against the wrong
target and the script keeps going.

## Pattern

Enumerate remotes, fetch each URL, regex-match against the expected repo
path. Then use the discovered names.

```bash
discover_remote() {
    local expected_repo="$1"   # e.g. "isbeorn/nina.plugin.manifests"
    local name url
    while read -r name; do
        url=$(git remote get-url "$name")
        if [[ "$url" =~ [:/]"$expected_repo"(\.git)?$ ]]; then
            echo "$name"
            return 0
        fi
    done < <(git remote)
    return 1
}

upstream_remote=$(discover_remote "owner/repo")
fork_remote=$(discover_remote "$gh_user/repo")
```

PowerShell equivalent:

```powershell
function Get-RemoteByRepo {
    param([string]$ExpectedRepo)
    foreach ($name in (git remote)) {
        $url = git remote get-url $name
        if ($url -match "[:/]$([regex]::Escape($ExpectedRepo))(\.git)?$") {
            return $name
        }
    }
    return $null
}
```

The regex anchors on `[:/]` so it matches both HTTPS
(`https://github.com/owner/repo`) and SSH (`git@github.com:owner/repo`)
forms, and on `(\.git)?$` so it tolerates the trailing `.git`.

## When a parameterized override is needed

Expose it as a script parameter that **defaults to discovery**, not to a
literal name. If discovery fails, fail with a message that names the
expected repo path — never fall back to `origin` and proceed.

```bash
# Good
upstream_remote="${UPSTREAM_REMOTE:-$(discover_remote owner/repo)}"
[[ -z "$upstream_remote" ]] && { echo "no remote points to owner/repo"; exit 1; }

# Bad — silently uses the wrong remote
upstream_remote="${UPSTREAM_REMOTE:-origin}"
```

## When to apply

Any script that pushes, fetches, or compares against a specific upstream:
release tooling, cross-repo PR helpers, fork-sync scripts, mirror
verifiers. If the script names `origin` or `upstream` as a literal, it has
this bug.
