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

## When to apply

Any automation where agents create, work, review, and hand back items to a
human through GitHub.
