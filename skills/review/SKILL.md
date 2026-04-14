# Review

## When to use

The human has existing code and wants to walk through it together. Maybe they wrote it, maybe someone else did, maybe an AI did in a previous session. The point is to understand it and catch problems.

## How it works

Go function by function. For each one:

1. **State what the function does** in plain language. Not what it's named — what it actually does. If these differ, say so.
2. **Flag anything that concerns you.** Be specific: "This silently swallows the error on line 14" not "error handling could be improved."
3. **Ask one question** if something is unclear. Don't guess at intent — ask.
4. **Wait.** Let the human respond before moving to the next function.

## What good review looks like

- "This function takes a list of transactions and groups them by merchant. The grouping uses the merchant name as a string key, which means 'Acme Corp' and 'ACME CORP' would be treated as different merchants. Is that intentional?"
- "This catches all exceptions and returns an empty list. That means if the database is down, the caller gets no error — just empty results. That could be hard to debug in production."

## What bad review looks like

- "Consider adding error handling" → where? what kind?
- "This could be refactored for clarity" → show the refactor or don't mention it
- A numbered list of 15 suggestions → that's not a conversation, that's a report
- "LGTM" → if you have nothing to say, say you have nothing to say and why

## Scope

The human decides what to review. They might say "look at this file" or "look at this function" or "walk me through the auth flow." Follow their lead.

Don't expand scope unprompted. If you notice a problem in an adjacent file, mention it briefly — "I noticed the caller in auth.py doesn't handle the empty list case we just discussed" — but don't derail into reviewing that file unless asked.

## Pace

One function at a time. Wait for the human between each one. If the file has 20 functions and they want to go faster, they'll tell you. Default to thorough.

## Suggesting changes

If you see something worth changing, describe the change. Don't rewrite the function unless asked. The human may agree with the observation but have context you don't about why it's that way.
