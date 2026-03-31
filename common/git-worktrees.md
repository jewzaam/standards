# Git Worktrees

Conventions for using git worktrees, particularly with AI-assisted development
tools (Claude Code, Cursor, Copilot CLI).

## When to use worktrees

Worktrees provide file-level isolation for parallel work on the same repository.
Use them when:

- Running multiple AI agents on independent tasks in the same repo
- Working on a feature while keeping the main worktree clean for reviews
- Testing a change in isolation without stashing or committing WIP

Do **not** use worktrees when a full clone or container would be more appropriate
(e.g., when tasks need isolated databases, ports, or Docker state — worktrees
share everything except the file tree and index).

## Directory placement

Place worktrees in a `git-worktrees/` directory at the same level as the repo:

```
~/source/
├── my-project/              # main worktree
└── git-worktrees/
    └── my-project/
        ├── fix-auth/        # worktree for fix-auth branch
        └── add-caching/     # worktree for add-caching branch
```

This keeps worktrees out of the repo directory, avoids `.gitignore` noise, and
groups all worktrees in a predictable location. The `git-worktrees/` path is
allowed for `git -C` operations in the user's global CLAUDE.md.

Create worktrees with:

```bash
git worktree add ~/source/git-worktrees/my-project/fix-auth -b fix-auth
```

## Branch naming

Each worktree requires its own branch — git enforces this (no two worktrees can
have the same branch checked out).

- Name the branch to match the worktree directory for traceability
- Use descriptive, task-based names: `fix-auth-timeout`, `add-retry-logic`
- AI tools that auto-create worktrees (Claude Code's `WorktreeCreate`) use
  `worktree-<name>` prefixes — this is acceptable

## Cleanup

**Always use `git worktree remove`, never `rm -rf`.** Filesystem deletion
leaves stale references in `.git/worktrees/` that cause errors on subsequent
operations.

```bash
# Correct
git worktree remove ~/source/git-worktrees/my-project/fix-auth

# Wrong — leaves stale refs
rm -rf ~/source/git-worktrees/my-project/fix-auth
```

If a worktree was deleted with `rm -rf`, recover with:

```bash
git worktree prune
```

After removing a worktree, delete the branch if it has been merged:

```bash
git branch -d fix-auth
```

List active worktrees to audit for stale ones:

```bash
git worktree list
```

## Lock file safety

Concurrent git operations across worktrees can cause index lock conflicts.
When terminating a process working in a worktree:

- Use `SIGTERM`, not `SIGKILL` (`kill`, not `kill -9`) — allow graceful cleanup
- If a lock file is left behind (`index.lock`), investigate what process held it
  before deleting

## Scale limits

3-5 parallel worktrees is the practical ceiling before coordination overhead
dominates. Beyond that, conflicts between branches increase, merge resolution
becomes frequent, and the cognitive load of tracking parallel work outweighs the
parallelism benefit.

## What to avoid

- **Do not nest worktrees inside the main repo** — use sibling directories under
  `git-worktrees/`
- **Do not use `rm -rf` for cleanup** — always `git worktree remove`
- **Do not share a branch across worktrees** — git prevents this, but attempting
  it with force flags causes corruption
- **Do not assume resource isolation** — worktrees share the same `.git` directory,
  remotes, hooks, and any external state (databases, ports, Docker volumes)
