---
name: centaur-adversarial
description: Stress-test finished code with a fresh-context subagent reviewer — finds bugs, wrong abstractions, missing edge cases.
---

# Adversarial Review

## When to use

A PR or feature is ready. The human wants the code stress-tested by fresh eyes — not the eyes that wrote it.

## Why a separate context

Claude reviewing code it just wrote in the same conversation is biased. It remembers why it made each decision and unconsciously defends them. The adversarial review runs in a subagent so the reviewer sees only the diff, not the reasoning. This is the same principle as adversarial training: the critic and the generator must be independent.

This is not delegation. The subagent gathers findings. Every finding comes back to the human for discussion. No decisions are made without the human.

## How it works

### 1. Gather the diff

Get the PR diff against the base branch. If there's no PR yet, diff against main. Show the human what you're about to send to the reviewer so they can confirm scope.

### 2. Spawn the reviewer

Launch a subagent with the diff and the adversarial prompt. The reviewer's job:

- **Assume the code is wrong.** Look for bugs, not style issues. Look for logic errors, missed edge cases, race conditions, incorrect assumptions about data shape.
- **Assume the abstractions are wrong.** Is this function doing too much? Is this the wrong boundary? Would this be painful to change in six months?
- **Assume the tests are insufficient.** What isn't tested? What's tested but with happy-path-only inputs?
- **Show the code.** Every concern must quote the specific lines. No "consider improving error handling."
- **State what you'd do differently.** Not "this could be improved" — say the specific change.
- **Be concrete, not exhaustive.** Return the 5 most important concerns, ranked by severity. Not 20 nitpicks.

The reviewer is adversarial about the code and the decisions that produced it. It is not adversarial toward the human. The tone is a senior engineer reviewing a PR they need to trust in production.

### 3. Present findings one at a time

When the reviewer returns, present each concern to the human individually:

1. Show the code the reviewer flagged.
2. Explain the concern.
3. State what the reviewer would do differently.
4. Wait for the human to respond before moving to the next one.

The human may agree, disagree, or explain context the reviewer didn't have. That's the conversation. Some concerns will be valid. Some won't. The human decides which to act on.

### 4. Act on accepted findings

For any concern the human agrees with, switch to `centaur-implement` to make the fix. One function at a time, same as always.

### 5. Surface refactor opportunities

After all concerns are discussed and resolved, the reviewer should also return a separate list of refactor opportunities it noticed — things that aren't bugs or wrong, but that would improve the codebase if addressed separately. These are future work, not blockers.

For each refactor opportunity:
- Name the area of code and show the relevant lines.
- Explain what's awkward and what a cleaner version would look like.
- Estimate scope: is this a 20-minute cleanup or a multi-day restructure?

Present these to the human as potential tickets, not as things to fix now. The human decides which (if any) are worth creating issues for. Offer to create them in their issue tracker if they want.

## The reviewer prompt

When spawning the subagent, include this framing:

> You are reviewing a diff as an adversarial code reviewer. Your job is to find the most important problems — bugs, wrong abstractions, missing edge cases, insufficient tests. Assume the code is wrong and try to prove it. For each concern: quote the specific code, explain the risk, and state exactly what you would change. Return your top 5 concerns ranked by severity. Be specific and concrete — no vague suggestions. You are critical of the code, not the author.
>
> Separately, list any refactor opportunities you noticed — things that aren't wrong but would benefit from future cleanup. For each: name the area, show the code, explain what's awkward, and estimate scope (quick cleanup vs. larger restructure). These are potential future tickets, not blockers.

Include the full diff and any relevant context files the human specifies.

## Anti-patterns

- Returning 15+ concerns → the human won't read them all. Pick the 5 that matter most.
- Flagging style issues → this isn't a linter. Focus on correctness and design.
- "This looks good overall with a few minor suggestions" → if everything is actually fine, say so and stop. Don't manufacture concerns.
- Presenting all findings at once → one at a time. Wait for the human.
- Being defensive about findings that the human disagrees with → the reviewer had less context. That's expected. Move on.
