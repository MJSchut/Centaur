#!/usr/bin/env bash
set -euo pipefail

REPO="MJSchut/Centaur"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

SKILLS_DIR="$HOME/.claude/skills"

echo "Installing Centaur skills to $SKILLS_DIR..."

mkdir -p \
  "$SKILLS_DIR/centaur" \
  "$SKILLS_DIR/centaur-design/examples" \
  "$SKILLS_DIR/centaur-implement" \
  "$SKILLS_DIR/centaur-review" \
  "$SKILLS_DIR/centaur-debug" \
  "$SKILLS_DIR/centaur-adversarial" \
  "$SKILLS_DIR/centaur-architect"

# Router
curl -fsSL "$BASE_URL/skills/centaur/SKILL.md" -o "$SKILLS_DIR/centaur/SKILL.md"

# Sub-skills
curl -fsSL "$BASE_URL/skills/centaur-design/SKILL.md"    -o "$SKILLS_DIR/centaur-design/SKILL.md"
curl -fsSL "$BASE_URL/skills/centaur-design/examples/design-summary.md" -o "$SKILLS_DIR/centaur-design/examples/design-summary.md"
curl -fsSL "$BASE_URL/skills/centaur-implement/SKILL.md"  -o "$SKILLS_DIR/centaur-implement/SKILL.md"
curl -fsSL "$BASE_URL/skills/centaur-review/SKILL.md"     -o "$SKILLS_DIR/centaur-review/SKILL.md"
curl -fsSL "$BASE_URL/skills/centaur-debug/SKILL.md"      -o "$SKILLS_DIR/centaur-debug/SKILL.md"
curl -fsSL "$BASE_URL/skills/centaur-adversarial/SKILL.md" -o "$SKILLS_DIR/centaur-adversarial/SKILL.md"
curl -fsSL "$BASE_URL/skills/centaur-architect/SKILL.md"   -o "$SKILLS_DIR/centaur-architect/SKILL.md"
curl -fsSL "$BASE_URL/skills/centaur-architect/default-config.json" -o "$SKILLS_DIR/centaur-architect/default-config.json"
curl -fsSL "$BASE_URL/skills/centaur-architect/graph-template.html" -o "$SKILLS_DIR/centaur-architect/graph-template.html"

echo ""
echo "Centaur installed. Use /centaur or say 'centaur mode' in any Claude Code session."
