# Agent Work Tracking

How to track work that LLM agents perform, so a human can see state at a
glance and agents can resume without chat history. Assumes a GitHub issue
tracker plus a Projects (v2) board.

## Work item = one issue, body is the current state

One issue per work item. The issue **body** is the single current-state
document; **comments** are the log.

Body sections: outcome, current understanding, decisions, deliverables
checklist, user actions checklist, acceptance criteria.

Rules:

- Every pull request, commit, or repo touched is a checkbox under
  deliverables, including knowledge and standards updates.
- Things only the human can do are checklist items assigned to that human.
  Ordinary clarifying chat is not tracked.
- A work item may not be closed (moved to Done) while any deliverable or
  user-action checkbox is unchecked. Enforce this in the tool that moves
  items, not by convention.

Why: chat context is lost at limits; a body that is rewritten to the current
truth lets any agent resume from one read, and the checklist gate stops
"done" claims with loose ends.

## State lives in exactly one place

The project board Status column is the only state. Flags are not states:
assignee means whose turn it is; labels such as `waiting` or `in-progress`
mark a live worker or a pending human.

Why: two copies of state need two-way sync, drift, and overwrite edits the
human makes in the UI.

## Agents identify by intent, not number

- Every agent comment ends with a footer naming the agent and its intent
  (refinement, implementation, review, responder, ...).
- Human messages relayed from chat are copied verbatim, in order, attributed
  to the chat user's name and id.
- Never assume the commenter is the single repo owner; agents and humans
  often share one account.

## Human feedback is read by an agent

Free-text human feedback is interpreted by an agent. Do not match keywords
("approved", "lgtm") to decide a verdict.

Why: keyword rules misfire on negation and mixed feedback; the cost of an
agent reading a comment is lower than a wrongly closed item.

## Pick-up order for workers

Priority first (High, Medium, Low; unset = Medium), then the item idle
longest (oldest last activity, not creation date). Run one LLM worker at a
time on small machines.

## Polling GitHub

- Poll incrementally with the REST `since` parameter. Advance the watermark
  to the newest update seen. Whether `since` is inclusive is undocumented,
  so de-duplicate by comment id.
- Prefer REST for polling. Use a lean GraphQL query for project fields only;
  never list all fields of all items.
- Serialize callers with a lock (one poller at a time).
- Check the remaining rate budget first (`gh api rate_limit` is free) and
  skip the pass when it is low.

Why: the budget is shared by every session using the same token; one greedy
query can exhaust it for an hour.

## One live owner per agent session

Take a lock keyed by session id before starting or resuming an agent
session; release it when the turn ends. Never resume a session another
process may be running.

Why: measured with Claude Code in print mode, a second `--session-id` with
the same id is refused ("already in use"), but `--resume` on a busy session
is not refused and runs a full parallel turn on the same session.

## Changing a running agent's instructions

To redirect an agent mid-turn, send an interrupt control request, then send
the new instructions in the same session.

- The interrupt ends the step in about 120 ms, kills the running tool, and
  keeps the context; the process stays alive for the next message.
- A plain message sent mid-turn lands only between model steps: after a
  long tool call finishes, or after a running sub-agent hands back. A 40 s
  tool delayed the reaction by the rest of the tool; the sub-agent was not
  cancelled.
- Interrupt only after the first tool use. Before the turn is persisted the
  interrupt discards it and the follow-up has no context.

Why: a plain message cannot be relied on to change course promptly, and an
early interrupt silently loses work.

## One worktree per agent session per repo

Give each agent session its own git worktree in each repo it edits (see
[git-worktrees.md](../common/git-worktrees.md)).

- A branch can be checked out in only one worktree; a second checkout is
  refused, which prevents two sessions on one branch.
- Edits in one worktree do not appear in another.
- A worktree with modified or untracked files is not removed without
  `--force`; do not force it while the work item is open.
- Sessions are looked up by id, not by working directory: resuming from a
  different directory or from a worktree of the same repo works and appends
  to the same transcript. Record the session id on the work item.

Why: isolation is enforced by git instead of by convention, and a resumer
does not need to reproduce the original cwd.

## Restricting an agent to certain write paths

To let a role (for example a specification curator) write only some paths:

- Register a `PreToolUse` path-guard hook for the Edit, Write, MultiEdit,
  NotebookEdit, and Bash tools, supplied through a session-scoped settings
  file, and select the role with an environment variable the hook reads.
  Fail closed on unparseable input. Deny with the JSON
  `permissionDecision: "deny"` form so the agent sees a clean reason.
- Cover Bash with a strict allowlist (read-only commands, no shell
  metacharacters), or give the role no Bash.
- Do not rely on an Edit/Write matcher alone, or on a Bash denylist.
- Treat the result as a guard against mistakes, not a security boundary.

Why: measured in bypass-permissions mode, an Edit/Write matcher left
`echo x > ../other` working; a regex denylist for Bash still allowed a
`node -e` file write; `--disallowedTools Edit Write` also left Bash open.
Only an allowlist blocked the one-liner. Not tested: whether sub-agents
inherit the hooks, and symlink or junction escapes (the check resolves the
path but not links).

## Single writer per artifact

An agent that curates a specification does not write code; builders do not
write the specification. Only meaning-changing specification edits are
committed, batched rather than one commit per touch-up.

Why: two writers on one artifact conflict, and per-edit commits bury the
changes that matter.

## When to apply

Any automation where agents create, work, review, and hand back items to a
human through GitHub.
