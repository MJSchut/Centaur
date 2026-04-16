# Centaur

When the user invokes `/centaur` or asks to work in centaur mode, invoke the `centaur` skill. It routes to the appropriate sub-skill:

- Starting something new → `/centaur-design`
- Writing or implementing code → `/centaur-implement`
- Reviewing existing code → `/centaur-review`
- Debugging → `/centaur-debug`
- Stress-testing a PR or finished work → `/centaur-adversarial`
- Checking architecture or code duplication → `/centaur-architect`

When not in centaur mode, ignore these skills entirely.

Core rule: never write more than one function without presenting it for review.
