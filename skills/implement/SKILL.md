# Implement

## When to use

The human wants to write code. This is the core centaur loop.

## The rule

**Never write more than one function without presenting it for review.**

This is the entire skill. Everything below is commentary on how to follow this rule well.

## The loop

1. **Write the complete function.** Present the full implementation — signature, body, docstring if warranted. State which file it belongs in. Nothing else — not the imports, not the neighbouring functions. Just the function.
2. **Wait.** The human reads it. They accept, reject, or discuss. Do not continue until they respond.
3. **Next function.** Return to step 1.

Don't split proposal and implementation into two turns. The human doesn't need to approve a signature before seeing the code — the code *is* the proposal. Presenting a signature and then asking "good to write it?" wastes a round-trip. Write the function. The human will tell you if the interface is wrong.

## What counts as "one function"

- A single function or method body
- A test for that function (present separately, after the implementation is accepted)
- A type definition or interface (if small enough to read in one pass)

What does NOT count:
- "Here's the function and also the three helper functions it calls" → those are four functions, present them one at a time
- "Here's the updated file with the new function added" → present only the new function, the human knows where it goes
- A class with five methods → present each method individually

## When the human says "just do the rest"

Push back. Say: "I'd rather keep reviewing together. What's the next function you want me to write?"

If they insist, they're the boss — but remind them once: "You said the review is the point. Want me to at least show you each function before moving on?"

If they override you twice, comply. They're an adult.

## When the function is too big

If you're writing a function that's longer than ~30 lines, stop and ask: "This is getting long. Can we break it into smaller pieces?"

If the human says no, write it. But flag it.

## Tests

After a function is accepted, offer to write the test. Present it the same way — one test, wait for review. The human may prefer to write tests themselves, or skip them entirely. That's their call.

Do not refuse to continue without tests. Centaur is not a TDD enforcement tool. It's a review enforcement tool.

## Boilerplate exception

For genuinely mechanical code — imports, config files, package.json fields, migration boilerplate — you can present multiple items at once. The test is: does this require engineering judgment? If no, batch it. If yes, one at a time.

## Files and context

When presenting a function, state which file it belongs in. If it's a new file, say so. But don't create the file — let the human decide when to commit the function to the codebase. They may want to discuss it further or change it.

When the human accepts a function, then write it to the file.
