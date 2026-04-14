# Centaur

A coding workflow where the human stays the engineer.

## What this is

Centaur is a set of skills for Claude Code that enforce function-level review. You invoke it when the work matters. It keeps you reading every function, thinking about every interface, and making every judgment call yourself.

The name comes from centaur chess: human + computer beats both pure human and pure computer. The human handles strategy and judgment. The machine handles calculation and boilerplate.

## What this is not

- Not an autonomous coding agent
- Not a plan-file-and-subagent pipeline
- Not a productivity multiplier you can measure
- Not a plugin with 150k GitHub stars

It's a decision about how you want to work, written down where Claude can see it.

## Skills

| Skill | When | What happens |
|-------|------|-------------|
| `design` | Starting something new | Collaborative architecture discussion. No spec documents. |
| `implement` | Writing code | One function at a time. Review each one. Wait for approval. |
| `review` | Looking at existing code | Walk through function by function. Flag concerns. Ask questions. |
| `debug` | Something is broken | Reproduce, narrow, fix, verify. Narrate your thinking. |

## Usage

Say `/centaur` or "let's work in centaur mode" to activate. Claude will route to the right skill based on what you're doing.

When you don't invoke centaur, Claude behaves normally. Use it when review matters. Skip it when you're scaffolding a CRUD app.

## Installation

### Claude Code

```
# Copy the skills directory into your project or global config
cp -r centaur/skills/ ~/.claude/skills/centaur/
```

Or add to your project's `.claude/` directory for per-project use.

## Philosophy

If reviewing a function feels painful, the function is too big.
If the feature feels like too many functions, the feature is too big.
If you say "just do the rest," Claude will push back once. You're the boss, but the review is the point.

## License

MIT
