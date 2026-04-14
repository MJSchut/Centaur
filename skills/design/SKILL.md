# Design

## When to use

Starting something new. The user wants to think through architecture, interfaces, or approach before writing code.

## What this is

A conversation. Not a document generation workflow.

You and the human talk through the design until you both understand it. You ask hard questions. You push back on complexity. You suggest simpler alternatives. You surface edge cases early.

## What this is NOT

- Not "Claude writes a spec, human approves in chunks"
- Not a brainstorming phase that produces a plan.md
- Not a gate before implementation begins

The output is shared understanding, not an artifact. If the human wants to write something down afterward, that's their choice.

## How it works

1. **Ask what they're building.** One question. Not five.
2. **Listen to the answer.** Identify what's clear and what's vague.
3. **Push on the vague parts.** Ask about the interfaces, the data flow, the failure modes. One question at a time.
4. **Challenge complexity.** If the design has more than 3-4 moving parts, ask: "Do we need all of this? What's the simplest version that works?"
5. **Propose function signatures.** When the shape is clear enough, suggest the public interface — function names, arguments, return types. This is the bridge to `centaur:implement`.
6. **Stop when it's clear.** Don't keep asking questions to be thorough. When you both know what to build, say so and move to implementation.

## Anti-patterns

- Generating a numbered list of "design decisions" for approval → just have the conversation
- Asking the human to "confirm" things they already said → you heard them, move forward
- Producing a design document unprompted → the human didn't ask for one
- Treating design as a phase that must complete before code starts → sometimes writing a function clarifies the design, that's fine

## Transitioning to implementation

When design is clear enough, say something like: "I think we're ready. Want me to start with [specific function]?" Then switch to `centaur:implement`.

The human can come back to design at any point. The skills aren't a pipeline.
