# Architect Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add architectural oversight to the centaur workflow via a new architect skill that detects code duplication and similarity using jscpd, ast-grep, and LLM judgment.

**Architecture:** Three detection layers (clone, structural, semantic) wrapped in a centaur skill with two modes: lightweight auto-check integrated into the implement loop, and deep on-demand scan. Configuration is two-level (user defaults + project overrides). Tool output feeds a shared JSON structure that powers both the text report and a future visual graph.

**Tech Stack:** jscpd (clone detection), ast-grep/sg (structural matching), shell/bash for tool invocation, JSON for intermediate data, markdown for skill definitions.

---

### Task 1: Default Configuration File

**Files:**
- Create: `skills/architect/default-config.json`

- [ ] **Step 1: Create the default config file**

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

This is the reference config. The skill instructions will tell the agent to look for config at `~/.claude/centaur-architect.json` (user level) and `.centaur/architect.json` (project level), falling back to this default. Project-level values override user-level values, which override defaults.

- [ ] **Step 2: Commit**

```bash
git add skills/architect/default-config.json
git commit -m "feat(architect): add default configuration"
```

---

### Task 2: Architect Skill — Auto-Check Mode

**Files:**
- Create: `skills/architect/SKILL.md`

- [ ] **Step 1: Write the architect skill file**

This is the core skill definition. It describes both modes (auto-check and deep) and the three detection layers with graceful degradation.

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/architect/SKILL.md
git commit -m "feat(architect): add architect skill with auto-check and deep check modes"
```

---

### Task 3: Update Implement Skill — Integrate Auto-Check

**Files:**
- Modify: `skills/implement/SKILL.md`

- [ ] **Step 1: Add auto-check integration to the implement loop**

Add the following section after the existing "The loop" section (after line 18 of `skills/implement/SKILL.md`):

```markdown
## Architectural auto-check

Before presenting each function for review, run the auto-check from `centaur:architect` (see `skills/architect/SKILL.md` — Auto-Check Mode).

The full loop becomes:

1. **Write the complete function.** Same as before.
2. **Run the auto-check.** Follow the auto-check steps in the architect skill. This checks for similar existing code using jscpd, ast-grep, and (when ambiguous) LLM judgment.
3. **Present for review.** If the auto-check found nothing, present the function normally. If it found similar patterns above the confidence threshold, append the findings summary and let the human choose: (a) investigate, (b) continue, (c) skip.
4. **Wait.** The human reads and responds.
5. **Next function.** Return to step 1.

The auto-check should not slow down the loop noticeably — layers 1-2 are shell commands that complete in seconds. If tools are not installed, the check degrades gracefully (see architect skill for details).
```

- [ ] **Step 2: Commit**

```bash
git add skills/implement/SKILL.md
git commit -m "feat(implement): integrate architect auto-check into the implement loop"
```

---

### Task 4: Update CLAUDE.md — Add Architect Route

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add the architect route to the routing table**

Add a new routing entry to the CLAUDE.md routing list:

```markdown
Route based on context:
- Starting something new → centaur/design/SKILL.md
- Writing or implementing code → centaur/implement/SKILL.md
- Reviewing existing code → centaur/review/SKILL.md
- Debugging → centaur/debug/SKILL.md
- Stress-testing a PR or finished work → centaur/adversarial/SKILL.md
- Checking architecture or code duplication → centaur/architect/SKILL.md
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "feat(centaur): add architect skill route to CLAUDE.md"
```

---

### Task 5: Verify Tool Integration

This task verifies that the skill instructions correctly describe how to invoke jscpd and ast-grep. No code to write — this is a manual verification step.

- [ ] **Step 1: Test jscpd invocation**

If jscpd is installed, run a test command against the Centaur repo itself to verify the command format works:

```bash
jscpd --min-tokens 50 --min-lines 5 --reporters json --output /tmp/centaur-architect-test/ --path ./skills/
```

Verify it produces valid JSON output. If the command flags or output format differ from what's documented in the skill, update `skills/architect/SKILL.md` to match reality.

- [ ] **Step 2: Test ast-grep invocation**

If sg is installed, test:

```bash
sg scan --pattern 'function $FUNC($$$) { $$$ }' --json ./skills/
```

Verify it produces valid JSON output. If the command flags or output format differ, update the skill.

- [ ] **Step 3: Update skill if commands needed adjustment**

If either tool's actual CLI differs from what's in the skill, edit `skills/architect/SKILL.md` with the corrected commands.

- [ ] **Step 4: Commit any fixes**

```bash
git add skills/architect/SKILL.md
git commit -m "fix(architect): correct tool invocation commands after testing"
```

(Skip this step if no changes were needed.)

---

### Task 6: Stretch Goal — Visual Graph Template

**Files:**
- Create: `skills/architect/graph-template.html`

This is the stretch goal. Only attempt if tasks 1-5 are complete and working.

- [ ] **Step 1: Create the HTML template**

A self-contained HTML file with inline D3.js that reads a JSON file (the architect report) and renders an interactive graph.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Centaur Architect — Code Similarity Graph</title>
  <script src="https://d3js.org/d3.v7.min.js"></script>
  <style>
    body { margin: 0; font-family: system-ui, sans-serif; background: #1a1a2e; color: #eee; }
    svg { width: 100vw; height: 100vh; }
    .node circle { stroke: #fff; stroke-width: 1.5px; cursor: pointer; }
    .node text { font-size: 11px; fill: #ccc; pointer-events: none; }
    .link { stroke-opacity: 0.6; }
    .link.clone { stroke: #4a90d9; }
    .link.structural { stroke: #e6a23c; }
    .link.semantic { stroke: #f56c6c; }
    #tooltip {
      position: absolute; background: #16213e; border: 1px solid #444;
      padding: 12px; border-radius: 6px; max-width: 500px; display: none;
      font-size: 13px; white-space: pre-wrap;
    }
    #controls { position: absolute; top: 16px; left: 16px; }
    #controls input { margin-right: 8px; }
    #legend { position: absolute; bottom: 16px; left: 16px; font-size: 12px; }
    .legend-item { display: flex; align-items: center; margin-bottom: 4px; }
    .legend-swatch { width: 24px; height: 4px; margin-right: 8px; border-radius: 2px; }
  </style>
</head>
<body>
  <div id="controls">
    <label>Load report: <input type="file" id="fileInput" accept=".json"></label>
  </div>
  <div id="legend">
    <div class="legend-item"><div class="legend-swatch" style="background:#4a90d9"></div>Clone match</div>
    <div class="legend-item"><div class="legend-swatch" style="background:#e6a23c"></div>Structural match</div>
    <div class="legend-item"><div class="legend-swatch" style="background:#f56c6c"></div>Semantic match</div>
  </div>
  <div id="tooltip"></div>
  <svg></svg>
  <script>
    const svg = d3.select("svg");
    const tooltip = d3.select("#tooltip");
    const width = window.innerWidth;
    const height = window.innerHeight;

    document.getElementById("fileInput").addEventListener("change", (e) => {
      const reader = new FileReader();
      reader.onload = (event) => {
        const report = JSON.parse(event.target.result);
        renderGraph(report);
      };
      reader.readAsText(e.target.files[0]);
    });

    function renderGraph(report) {
      svg.selectAll("*").remove();
      const g = svg.append("g");

      // Build nodes from cluster members
      const nodeMap = new Map();
      const links = [];

      report.clusters.forEach(cluster => {
        cluster.members.forEach(member => {
          const id = `${member.file}:${member.function}`;
          if (!nodeMap.has(id)) {
            nodeMap.set(id, {
              id,
              file: member.file,
              function: member.function,
              startLine: member.startLine,
              endLine: member.endLine,
              cluster: cluster.id,
              size: member.endLine - member.startLine
            });
          }
        });
        cluster.matches.forEach(match => {
          links.push({
            source: match.from,
            target: match.to,
            layer: match.layer,
            confidence: match.confidence
          });
        });
      });

      const nodes = Array.from(nodeMap.values());

      // Color clusters
      const clusterIds = [...new Set(nodes.map(n => n.cluster))];
      const color = d3.scaleOrdinal(d3.schemeTableau10).domain(clusterIds);

      const simulation = d3.forceSimulation(nodes)
        .force("link", d3.forceLink(links).id(d => d.id).distance(120))
        .force("charge", d3.forceManyBody().strength(-200))
        .force("center", d3.forceCenter(width / 2, height / 2))
        .force("collision", d3.forceCollide().radius(d => Math.sqrt(d.size) * 2 + 10));

      const link = g.append("g").selectAll("line")
        .data(links).join("line")
        .attr("class", d => `link ${d.layer}`)
        .attr("stroke-width", d => d.confidence / 30);

      const node = g.append("g").selectAll("g")
        .data(nodes).join("g").attr("class", "node")
        .call(d3.drag()
          .on("start", (e, d) => { if (!e.active) simulation.alphaTarget(0.3).restart(); d.fx = d.x; d.fy = d.y; })
          .on("drag", (e, d) => { d.fx = e.x; d.fy = e.y; })
          .on("end", (e, d) => { if (!e.active) simulation.alphaTarget(0); d.fx = null; d.fy = null; })
        );

      node.append("circle")
        .attr("r", d => Math.max(6, Math.sqrt(d.size) * 1.5))
        .attr("fill", d => color(d.cluster));

      node.append("text")
        .attr("dx", 12).attr("dy", 4)
        .text(d => d.function);

      node.on("mouseover", (e, d) => {
        tooltip.style("display", "block")
          .html(`<strong>${d.function}</strong>\n${d.file}:${d.startLine}-${d.endLine}\nLines: ${d.size}`);
      }).on("mousemove", (e) => {
        tooltip.style("left", (e.pageX + 16) + "px").style("top", (e.pageY - 16) + "px");
      }).on("mouseout", () => tooltip.style("display", "none"));

      simulation.on("tick", () => {
        link.attr("x1", d => d.source.x).attr("y1", d => d.source.y)
          .attr("x2", d => d.target.x).attr("y2", d => d.target.y);
        node.attr("transform", d => `translate(${d.x},${d.y})`);
      });

      // Zoom
      svg.call(d3.zoom().on("zoom", (e) => g.attr("transform", e.transform)));
    }
  </script>
</body>
</html>
```

- [ ] **Step 2: Add graph generation instructions to the skill**

Add the following section to the end of `skills/architect/SKILL.md`, before the Anti-patterns section:

```markdown
## Visual Graph (stretch goal)

After generating the deep check JSON report, offer to generate a visual graph:

> "I've saved the report to `.centaur/architect-report.json`. Want me to open a visual graph of the results in your browser?"

If yes:
1. Copy `skills/architect/graph-template.html` to `.centaur/architect-graph.html`
2. Tell the human to open it in their browser and load the JSON file
3. Explain the color coding: blue = clone, orange = structural, red = semantic
```

- [ ] **Step 3: Commit**

```bash
git add skills/architect/graph-template.html skills/architect/SKILL.md
git commit -m "feat(architect): add visual graph template (stretch goal)"
```
