---
description: Elicit intent for new work, reach mutual understanding, and create a GitHub issue
argument-hint: [topic or seed idea]
---

Guide the user from a rough idea to a well-understood, documented GitHub issue using structured goal elicitation.

## Steps

**1. Check prerequisites**

```bash
gh auth status
```

Abort if not authenticated.

**2. Seed the conversation**

If `$ARGUMENTS` is non-empty, use it as the starting point. Otherwise start with an open question.

**3. Elicit the goal**

Use `AskUserQuestion` to reach mutual understanding. Aim for 2–4 focused rounds — stop as soon as you have enough to write a crisp issue. Cover these dimensions (combine into fewer questions when possible):

- **Problem / motivation** — What situation or pain prompted this? What goes wrong today without this?
- **Success criteria** — What does done look like? How will we know it's working?
- **Scope** — What's explicitly in scope? What's out of scope or saved for later?
- **Constraints** — Any technical, time, or stakeholder constraints worth capturing?

Adapt based on what the seed already answers. If $ARGUMENTS covers motivation clearly, skip that question.

**4. Confirm your understanding**

Before drafting, state your synthesis in 2–3 sentences and ask the user to confirm or correct it:

> "So the goal is: [one sentence]. Done means: [one sentence]. Out of scope: [one sentence]. Is that right?"

Use `AskUserQuestion` for this confirmation. Revise until the user confirms.

**5. Draft the issue**

Write a GitHub issue with this structure:

```markdown
## Goal

[One sentence: what we want to achieve and why.]

## Background

[2–4 sentences of context and motivation. What prompted this? What breaks or is painful today?]

## Acceptance criteria

- [ ] [Concrete, testable condition]
- [ ] [Concrete, testable condition]
- [ ] ...

## Out of scope

- [Item saved for later, if any]

## Notes

[Any constraints, open questions, or references worth capturing — omit section if empty.]
```

Derive the title from the goal sentence (concise, imperative, ≤ 72 characters).

**6. Show the draft and get approval**

Display the proposed title and body, then use `AskUserQuestion` to ask:

> "Does this capture it? Approve to create, or tell me what to change."

Offer options: Approve / Edit title / Edit body / Start over.

Revise and re-show until approved.

**7. Create the issue**

```bash
gh issue create --title "<title>" --body "<body>"
```

**8. Ask about test-first**

Use `AskUserQuestion`:

- Question: "Should this issue require a test-first hill? A hill means failing tests are merged as a draft PR — with CI confirming the failures — before any implementation begins."
- Options: "Yes, require a test-first hill" / "No, standard workflow"

If the user chooses yes:

```bash
gh label create "test-first" \
  --description "Requires a test-first failing-test hill before implementation" \
  --color "FF6B35" \
  --force

gh issue edit <number> --add-label "test-first"
```

Print: `Applied test-first label to issue #<number>.`

**9. Print a confirmation**

```
Created issue #<number>: <title>
<url>

To start work on it now: /start-pr <number>
```
