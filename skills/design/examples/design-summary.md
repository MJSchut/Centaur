# Example: design summary before transitioning to implementation

This is what a good end-of-design summary looks like. It's concrete, names the actual code artifacts, and ends with a clear next step.

---

Agreed. So to summarize where we've landed:

One new dict in tool_categories.py — `CONTEXT_KEY_MAPPING: dict[str, list[str]]` — maps each intent category to the query key prefixes that belong to it. Lives right next to `TOOL_CATEGORIES` so they stay visible together.

One new function — `filter_page_context(page_context: dict, categories: list[str]) -> dict` — takes the raw page_context and returns only keys matching the union of category prefixes. General/broad/off_topic -> empty dict.

Called in llm.py between intent routing (line ~461) and prompt assembly (line ~291).

One test — asserts every key in `TOOL_CATEGORIES` has a corresponding entry in `CONTEXT_KEY_MAPPING` and vice versa.

Token logging — before/after `len(json.dumps(...))` so we can see the reduction.

That's 3 moving parts. Want me to start with the mapping dict and filter function?

---

## Why this works

- **Concrete artifacts**: names exact types, files, and locations — not vague descriptions
- **Minimal**: only the moving parts, no filler
- **Counts the complexity**: "that's 3 moving parts" — gives the human a sanity check on scope
- **Clear transition**: ends with a specific next step, not "shall we proceed?"
