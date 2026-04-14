# Centaur

A set of skills for Claude Code that keep the human in the driver's seat.

## The problem

AI coding tools are getting good at generating code. They're bad at knowing when to stop. The default mode is: human gives a vague instruction, agent disappears for 45 seconds, comes back with 600 lines across 12 files, and the human rubber-stamps it because reading all of that carefully is more work than writing it would have been.

That's not pair programming. That's delegation with extra steps. The human loses understanding of their own codebase, misses bugs the AI introduced, and can't effectively review work they didn't participate in creating.

Centaur fixes this by enforcing a simple constraint: **one function at a time, reviewed by the human, before moving on.** The AI writes. The human reads, thinks, and decides. Every function. No exceptions.

The name comes from centaur chess — human + computer beats both pure human and pure computer. The human handles strategy and judgment. The machine handles calculation and boilerplate.

## What this gives you

- **You understand every line.** Because you reviewed it as it was written.
- **Bugs surface early.** Because you're reading each function before the next one builds on it.
- **Design stays honest.** When implementation reveals the design was wrong, Centaur makes Claude stop and revisit the architecture instead of plowing forward.
- **AI has opinions, not menus.** Claude states what it thinks and why, instead of presenting options for you to pick from.
- **Adversarial self-review.** A separate context reviews the finished work with fresh eyes, trying to break what was just built.

## Skills

| Skill | When | What happens |
|-------|------|-------------|
| `design` | Starting something new | Collaborative architecture discussion. No spec documents. |
| `implement` | Writing code | One function at a time. Full implementation. Wait for review. |
| `review` | Looking at existing code | Walk through function by function. Flag concerns. Ask questions. |
| `debug` | Something is broken | Reproduce, narrow, fix, verify. Narrate your thinking. |
| `adversarial` | Stress-testing finished work | Fresh-context review that tries to break the code. Surfaces refactor opportunities as future tickets. |

## Installation

```
curl -fsSL https://raw.githubusercontent.com/MJSchut/Centaur/main/install.sh | bash
```

Installs to `~/.claude/skills/centaur/` — available in every Claude Code session across all your projects.

For per-project use, copy into your project's `.claude/skills/centaur/` directory instead.

## Usage

Say `/centaur` or "let's work in centaur mode" to activate. Claude routes to the right skill based on what you're doing. When you don't invoke centaur, Claude behaves normally.

Use it when the work matters. Skip it when you're scaffolding.

## Contributing

Found a problem or have an idea? Open an issue: [github.com/MJSchut/Centaur/issues](https://github.com/MJSchut/Centaur/issues)

## License

MIT
