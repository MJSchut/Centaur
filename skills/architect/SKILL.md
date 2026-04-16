# Architect

## When to use

This skill has two modes:

1. **Auto-check** — runs automatically during `centaur:implement`. You do not invoke this mode directly; the implement skill triggers it.
2. **Deep check** — invoked explicitly when the human wants a full architectural scan of the codebase.

## Configuration

Load config by merging (in priority order):
1. `.centaur/architect.json` in the project root (if it exists)
2. `~/.claude/centaur-architect.json` (if it exists)
3. `skills/architect/default-config.json` (always exists)

Merge is shallow per top-level key: if the project config defines `autoCheck`, the entire `autoCheck` object replaces the default. This keeps behavior predictable.

## Tool Detection

Before the first check in a session, verify tool availability:

```bash
command -v jscpd >/dev/null 2>&1
command -v sg >/dev/null 2>&1
```

If a tool is missing, warn the human once:
> "jscpd is not installed — clone detection (layer 1) will be skipped. Install with `npm install -g jscpd` for better results."

Track which tools are available for the rest of the session. Do not warn again.

If neither tool is installed, say:
> "Neither jscpd nor ast-grep is installed. Falling back to LLM-only analysis — results will be slower and less reliable. Install both for best results: `npm install -g jscpd` and see https://ast-grep.github.io for sg."

## Auto-Check Mode

Runs between "write function" and "present for review" in the implement loop.

### Step 1: Extract the function

Write the function you're about to present to a temporary file. This is the input for layers 1 and 2.

### Step 2: Run Layer 1 — Clone detection (jscpd)

Only if jscpd is available. Run:

```bash
jscpd --min-tokens {config.deepCheck.minTokens} --min-lines {config.deepCheck.minLines} --reporters json --output /tmp/centaur-architect/ --path {source_directories} --files-to-compare {temp_function_file}
```

Parse the JSON output. Each duplicate found has a percentage match.

If jscpd doesn't support `--files-to-compare` in the installed version, fall back to running jscpd on the full source directory and filtering results that include code overlapping with the new function.

### Step 3: Run Layer 2 — Structural matching (ast-grep)

Only if `sg` is available. Generate a pattern from the function's shape:
- Extract the function signature structure (parameters, return type if present)
- Generalize names to wildcards: `function $FUNC($$$ARGS) { $$$ }` style patterns
- Run:

```bash
sg scan --pattern '{generated_pattern}' --json {source_directories}
```

Parse the JSON output for structural matches.

### Step 4: Collate and filter

Combine results from layers 1 and 2. Assign confidence scores:
- jscpd percentage maps directly to confidence
- ast-grep matches get a base confidence of 60 (structural match without token similarity)
- If both layers flag the same code region, boost confidence by 10

Filter by `config.autoCheck.confidenceThreshold`.

If any results fall in the 50-70% range (below threshold but not trivially low), and `config.deepCheck.includeSemanticLayer` is true, invoke Layer 3 (LLM judgment) on those specific matches to decide if they're worth surfacing.

### Step 5: Present results

**If no results above threshold:** Present the function normally. Say nothing about the check.

**If results above threshold:** Present the function, then append:

```
Found {N} similar patterns:
- {confidence}% match: {file}:{startLine}-{endLine} ({functionName})
- ...

Should we: (a) look at these before proceeding, (b) continue as-is, (c) skip checks for this function?
```

Cap results at `config.autoCheck.maxResultsShown`.

**If human chooses (a):** Show the code of each match side-by-side with the new function. Discuss whether to reuse, refactor, or proceed as-is. This is conversational — one match at a time.

**If human chooses (b):** Continue with the implement loop normally.

**If human chooses (c):** Skip and continue. Do not run auto-check for this specific function if it comes up again in the same session.

## Deep Check Mode

Invoked explicitly. Runs all three layers across the entire codebase.

### Step 1: Detect source directories

Find directories containing source files in supported languages. Exclude common non-source directories: `node_modules`, `vendor`, `dist`, `build`, `.git`, `__pycache__`, `venv`, `.venv`.

### Step 2: Run Layer 1 — Full repo clone scan

```bash
jscpd --min-tokens {config.deepCheck.minTokens} --min-lines {config.deepCheck.minLines} --reporters json --output /tmp/centaur-architect-deep/ --path {source_directories}
```

### Step 3: Run Layer 2 — Architectural pattern scan

Run ast-grep with a set of generic patterns that indicate architectural issues:

**Large function bodies** (language-specific patterns for functions > 50 lines):
```bash
sg scan --pattern 'function $FUNC($$$) { $$$ }' --json {source_directories}
```
Filter results by line count.

**Deeply nested logic** (3+ levels of nesting):
Use language-appropriate patterns for nested if/for/while blocks.

**Similar function signatures** across different files:
Generate patterns from the most common function shapes found in step 2 results.

### Step 4: Run Layer 3 — LLM semantic analysis

Only if `config.deepCheck.includeSemanticLayer` is true.

Review the combined output of layers 1 and 2. For each cluster of similar code:
- Read the actual source code of each member
- Judge: are these genuinely the same concern, or superficially similar with different responsibilities?
- For genuine duplicates, suggest a specific refactoring approach
- For false positives, drop them from the report

### Step 5: Build JSON output

Assemble the structured JSON:

```json
{
  "clusters": [
    {
      "id": "cluster-{N}",
      "label": "{human-readable description}",
      "members": [
        {
          "file": "{path}",
          "function": "{name}",
          "startLine": 0,
          "endLine": 0
        }
      ],
      "matches": [
        {
          "from": "{file}:{function}",
          "to": "{file}:{function}",
          "layer": "clone|structural|semantic",
          "confidence": 0
        }
      ],
      "suggestion": "{specific refactoring suggestion}"
    }
  ],
  "observations": [
    {
      "type": "large_file|complex_function|deep_nesting",
      "file": "{path}",
      "detail": "{description}"
    }
  ],
  "prioritizedAction": "{single most impactful refactoring}"
}
```

Save to `.centaur/architect-report.json` in the project root.

### Step 6: Generate text report

From the JSON, produce a human-readable report. Present it to the human section by section:

1. **Similarity clusters** — one at a time. Show the code snippets, the detection layer, and the suggestion. Wait for the human to respond before showing the next cluster.
2. **Architectural observations** — grouped by type. Present as a summary, expand on any the human wants to discuss.
3. **Prioritized action** — "If you were going to refactor one thing, start here: {description}."

## Anti-patterns

- Running the deep check without being asked → the auto-check is automatic, the deep check is not
- Presenting tool installation as a blocker → graceful degradation means it always works, just better with tools
- Flooding the human with 20 matches → respect `maxResultsShown` for auto-check, and present deep check results one cluster at a time
- Treating similarity as a bug → similar code isn't necessarily wrong. Present findings, let the human decide
- Silently skipping the auto-check when tools aren't installed → always warn once so the human knows the limitation
