# Shell Prompt (PS1) Standards

Conventions for building and maintaining interactive shell prompts.

## Segment Architecture

The prompt is a sequence of **segments**, each responsible for one piece of context (hostname, environment indicator, git branch, etc.).

### Spacing Convention

Each dynamic segment owns its **leading space**. No trailing spaces. This prevents double-space gaps when middle segments produce no output.

```bash
# Good — leading space
printf ' [local]'

# Bad — trailing space (doubles up when next segment also has spacing)
printf '[local] '
```

Static segments in the PS1 string (like the cwd/prompt suffix) use a literal leading space.

### Segment Order

```text
<identity> <environment> <cluster-context> <git-branch> <cwd><prompt-char>
```

1. **Identity** — `user@host` (static in PS1 string)
2. **Environment** — sandbox/profile indicator (function)
3. **Cluster context** — OpenShift/k8s user, cluster, namespace (command substitutions)
4. **Git branch** — current branch with warn coloring for default branches (function)
5. **CWD + prompt char** — basename of working directory and `$` (static in PS1 string)

## ANSI Color Escapes in PS1

### Why Two Variable Sets

Bash's PS1 processor converts `\[\033[...\]` → actual bytes (`\x01`, ESC, `\x02`) for content **inline in the PS1 string**. But output from `$()` command substitutions runs AFTER that processor — functions need the actual bytes already.

| Context | Format | Example |
|---------|--------|---------|
| PS1 inline | `\[\033[1;32m\]` | `export PS1="${C_HOSTNAME}\u@bob..."` |
| Function output | `$'\x01\e[1;32m\x02'` | `printf '%s' "$PS1F_HOSTNAME"` |

This is not duplication — it's the same ANSI codes in two transport encodings required by bash's processing pipeline.

### Deriving Function-Safe Colors

Define `C_*` as the source of truth. Derive `PS1F_*` with a converter — never duplicate ANSI codes:

```bash
_ps1_to_func() {
    local s="$1" x01=$'\x01' x02=$'\x02' esc=$'\e'
    s="${s//\\[/${x01}}"
    s="${s//\\]/${x02}}"
    s="${s//\\033/${esc}}"
    printf '%s' "$s"
}

C_HOSTNAME=$LIGHT_GREEN
PS1F_HOSTNAME=$(_ps1_to_func "$C_HOSTNAME")
```

Change `C_HOSTNAME=$LIGHT_RED` → `PS1F_HOSTNAME` updates automatically.

## Color Variables

### Never Use Raw Escape Codes in Functions

Functions must reference named variables, never raw `\x01\033[...m\x02` strings. Raw codes are unreadable and unmaintainable.

```bash
# Good — readable, changeable
printf ' %s(%s%s%s)%s' "$PS1F_HOSTNAME" "$c_branch" "$branch" "$PS1F_HOSTNAME" "$PS1F_RESET"

# Bad — what color is this? nobody knows without a lookup table
printf ' \x01\033[1;32m\x02(\x01\033[1;36m\x02%s\x01\033[1;32m\x02)\x01\033[0m\x02' "$branch"
```

### Keep Colors Self-Contained

All color definitions (palette, `C_*`, `_ps1_to_func`, `PS1F_*`) belong in the same file as the PS1 export. Don't split into a separate file — it creates a deployment dependency that silently breaks colors when the new file isn't sourced.

Functions in earlier-numbered files (e.g., `85-sandbox`) can reference `PS1F_*` variables defined in a later file (e.g., `90-prompt`) because bash resolves variables at call time (prompt display), not at function definition time.

| Prefix | Used By | Example |
|--------|---------|---------|
| `C_*` | PS1 inline string | `"${C_HOSTNAME}\u@bob"` |
| `PS1F_*` | Helper functions via `$()` | `printf '%s' "$PS1F_HOSTNAME"` |
| `NO_COLOR` / `PS1F_RESET` | Color reset in each context | |

### Semantic Color Assignments

| Variable | Role | ANSI Code |
|----------|------|-----------|
| `C_HOSTNAME` | Identity, branch parens | 1;32 (light green) |
| `C_BRANCH_OTHER` | Non-default branch name | 1;36 (light cyan) |
| `C_BRANCH_WARN` | Default branch name | 1;31 (light red) |
| `C_PWD` | Working directory basename | 1;36 (light cyan) |
| `C_PROMPT` | Prompt character (`$`) | 0;31 (red) |
| `NO_COLOR` | Color reset | 0m |

Segment-specific colors (sandbox profiles, OC context) follow the same pattern.

### Paren Consistency

Both parentheses wrapping a value (e.g., git branch) use the **same color**. The content between them may differ. Never leave a paren inheriting from the previous segment's color reset.

```bash
# Good — both parens explicitly colored via variable
printf ' %s(%s%s%s)%s' "$PS1F_HOSTNAME" "$c_branch" "$branch" "$PS1F_HOSTNAME" "$PS1F_RESET"

# Bad — ( inherits whatever came before
printf '(%s%s%s) ' "$c_branch" "$branch" "$PS1F_HOSTNAME"
```

## Helper Functions

Extract dynamic segments into shell functions when they involve:

1. Conditional logic (branch name matching, environment detection)
2. Color codes (functions use the correct `\x01...\x02` escapes)
3. Multiple output paths (sandbox profiles, branch warn vs normal)

Keep functions small — one printf per code path. The function name convention is `__<segment>_ps1()` (double underscore prefix, `_ps1` suffix).

## Warn Branch List

Default/protected branch names that trigger warn coloring: `master`, `main`, `prod`. Match with bash regex:

```bash
if [[ "$branch" =~ ^(master|main|prod)$ ]]; then
```

Extend this list per-environment if needed (e.g., `release`, `stable`).
