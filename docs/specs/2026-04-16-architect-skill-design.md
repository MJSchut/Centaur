# Architect Skill — Design Spec

## Problem

Agentic coding loses architectural oversight. When an AI writes code function-by-function, nobody checks whether similar code already exists, whether the new code should reuse an existing pattern, or whether the codebase is accumulating structural debt. The human in the loop sees each function but not the big picture.

## Solution

A new centaur skill (`skills/architect/SKILL.md`) that provides architectural oversight through two modes:

1. **Lightweight auto-check** — runs automatically during the implement loop, before each function is presented for review
2. **Deep on-demand check** — invoked explicitly for a full architectural scan

## Target Languages

Python, JavaScript, TypeScript, Java, Go, C# (the big 5 + TypeScript as a JS superset). Other languages are a stretch goal.

## Detection Layers

Three layers, each covering a different kind of similarity:

### Layer 1 — Clone detection (jscpd)

- Token-based duplicate detection across the codebase
- Runs `jscpd` with JSON output
- Configurable `minTokens` and `minLines` thresholds per language
- **Auto-check:** scoped to comparing the new function against the existing codebase
- **Deep check:** full repo scan

### Layer 2 — Structural matching (ast-grep)

- AST-based pattern matching using tree-sitter
- Generates a pattern from the function just written (auto-check) or runs a broader set of architectural patterns (deep check)
- Finds structurally similar code even when names and values differ
- Architectural patterns for deep check include: large files, deeply nested logic, god functions

### Layer 3 — LLM semantic judgment

- Only used in the deep check, or when layers 1-2 return results in the 50-70% confidence range during auto-check (below threshold but not trivially low)
- Reads tool output plus actual code of flagged matches
- Makes the judgment call: "genuinely the same concern" vs "superficially similar but different responsibilities"
- Source of refactoring suggestions

### Graceful Degradation

- If jscpd is not installed: skip layer 1 with a one-time warning
- If ast-grep (`sg`) is not installed: skip layer 2 with a one-time warning
- If neither is installed: fall back to LLM-only (layer 3 for everything) with a clear message that results will be less reliable and slower

## Auto-Check Flow

Integrated into the implement skill's loop, between "write function" and "present for review":

1. Function is written
2. Skill extracts the function body
3. Runs jscpd against the codebase with the function as input (layer 1)
4. Generates an ast-grep pattern from the function signature/shape and searches (layer 2)
5. Collates results, filters by confidence threshold
6. **If nothing above threshold:** present the function normally, no mention of the check
7. **If findings above threshold:** present the function with a summary:

```
Found 2 similar patterns:
- 78% match: src/utils/parse.ts:45-62 (parseUserInput)
- 72% match: src/services/validator.ts:30-41 (validateInput)

Should we: (a) look at these before proceeding, (b) continue as-is, (c) skip checks for this function?
```

Option (a) opens the door to a future investigative/refactor mode. Option (c) reduces friction when the user knows the match is irrelevant.

**Performance:** Layers 1-2 are shell commands on local files. For a medium codebase (~10k files), jscpd takes 2-5 seconds, ast-grep under 1 second. Fast enough to not break the implement rhythm.

## Deep On-Demand Check

Invoked explicitly for a full architectural scan. Runs all three layers across the entire codebase.

### Output: Text Report

**Similarity clusters** — groups of functions/blocks that do roughly the same thing:

```
Cluster 1: Input validation (4 functions)
  - src/api/users.ts:validateUser (lines 12-35)
  - src/api/orders.ts:validateOrder (lines 8-28)
  - src/api/products.ts:validateProduct (lines 15-40)
  - src/middleware/auth.ts:validateToken (lines 22-45)
  Detection: jscpd 82% match (first 3), LLM semantic match (4th)
  Suggestion: Extract shared validation pattern, specialize per domain
```

**Architectural observations:**
- Large files (by function count or line count)
- Functions with high structural complexity (deep nesting, many branches)
- Circular or surprising dependency patterns

**Prioritized action:** The report ends with "if you were going to refactor one thing, start here."

### Output: JSON Structure

The deep check produces a structured JSON intermediate that both the text report and the future visual graph consume. This JSON is the contract between detection and presentation.

```json
{
  "clusters": [
    {
      "id": "cluster-1",
      "label": "Input validation",
      "members": [
        {
          "file": "src/api/users.ts",
          "function": "validateUser",
          "startLine": 12,
          "endLine": 35
        }
      ],
      "matches": [
        {
          "from": "src/api/users.ts:validateUser",
          "to": "src/api/orders.ts:validateOrder",
          "layer": "clone",
          "confidence": 82
        }
      ],
      "suggestion": "Extract shared validation pattern, specialize per domain"
    }
  ],
  "observations": [
    {
      "type": "large_file",
      "file": "src/services/legacy.ts",
      "detail": "42 functions, 1800 lines"
    }
  ],
  "prioritizedAction": "Cluster 1 — 4 near-identical validation functions"
}
```

## Configuration

Two-level config: user defaults at `~/.claude/centaur-architect.json`, project overrides at `.centaur/architect.json`. Project-level values win when present.

```json
{
  "autoCheck": {
    "enabled": true,
    "confidenceThreshold": 70,
    "maxResultsShown": 3
  },
  "deepCheck": {
    "minTokens": 50,
    "minLines": 5,
    "includeSemanticLayer": true,
    "reportFormat": "text"
  },
  "languages": {
    "python": { "enabled": true },
    "javascript": { "enabled": true },
    "typescript": { "enabled": true },
    "java": { "enabled": true },
    "go": { "enabled": true },
    "csharp": { "enabled": true }
  },
  "tools": {
    "jscpd": { "path": "jscpd" },
    "astGrep": { "path": "sg" }
  }
}
```

- `confidenceThreshold`: below this, findings are silently noted for the deep check but don't interrupt the implement flow
- `maxResultsShown`: caps the summary in auto-check mode
- `tools.*.path`: custom install paths for external tools

## Stretch Goal: Visual Graph

A self-contained HTML file (no server) that visualizes deep check results in a browser.

**Design:**
- Bundled HTML template with inline D3.js
- Consumes the same JSON output as the text report
- Nodes = functions/modules, sized by complexity
- Edges = similarity connections, color-coded by detection layer (blue = clone, orange = structural, red = semantic)
- Clusters visually grouped
- Click a node to see code snippet and matches

**What we build now:** The JSON output structure that feeds this graph.
**What we build later:** The HTML/D3 template.

## Future Work (Not In Scope)

- **Investigative/refactor mode:** branching off from auto-check finding (a) into a guided refactoring workflow
- **Additional language support** beyond the big 5
- **Embedding-based semantic search** (UniXcoder + vector store) for deeper semantic similarity
- **Integration with dependency-cruiser, madge, pyan3** for language-specific graph enrichment
