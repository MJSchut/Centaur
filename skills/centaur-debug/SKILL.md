---
name: centaur-debug
description: Reproduce, narrow, fix, verify — find and fix bugs together with the human steering.
---

# Debug

## When to use

Something is broken. The human wants to find and fix it together.

## How it works

Debugging is inherently interactive. You don't go away and come back with an answer. You think out loud, and the human steers.

### 1. Reproduce

Ask the human to describe what's happening. Not what they think the bug is — what they observe. What did they expect? What happened instead?

If you can run the code, reproduce it. Show the output. Confirm with the human: "Is this the behaviour you're seeing?"

### 2. Narrow

Form a hypothesis about where the problem is. State it clearly: "I think the issue is in the response parsing, because the request looks correct but the data comes back wrong."

Then propose one specific thing to check. Not five things — one thing. Run it or ask the human to run it. Look at the result together.

If the hypothesis was wrong, say so and form a new one. Don't quietly pivot — be explicit: "That wasn't it. The response is fine, so the problem is downstream. Let me look at the transform step."

### 3. Fix

When you find the root cause, explain it: what's happening, why, and what the fix is. Then write the fix as a single function or a minimal change. Present it for review exactly like `centaur-implement` — wait for approval before applying.

If the fix is more than a few lines, break it up. Same rule as implement: one reviewable unit at a time.

### 4. Verify

After the fix is applied, reproduce the original problem. Show that it's gone. If there are related edge cases, mention them: "This fixes the null case, but there's also a potential issue when the list is empty. Want me to look at that?"

## Anti-patterns

- Running 10 diagnostic commands in a row without explaining what you're looking for → slow down, narrate
- "I found the bug and fixed it" without showing the human the root cause → they need to understand it too
- Fixing symptoms instead of causes → if adding a null check makes the crash go away but doesn't explain why the value is null, you haven't debugged, you've papered over
- Expanding scope → "while I was in here I also refactored the error handling" — no. Fix the bug. That's it.
- Describing code by file and line number without showing it → read the file, quote the relevant lines so the human can see what you're talking about
