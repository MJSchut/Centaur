#!/usr/bin/env bash
set -euo pipefail

REPO="MJSchut/Centaur"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

SKILLS_DIR="$HOME/.claude/skills/centaur"

echo "Installing Centaur skills to $SKILLS_DIR..."

mkdir -p "$SKILLS_DIR/design/examples" "$SKILLS_DIR/implement" "$SKILLS_DIR/review" "$SKILLS_DIR/debug" "$SKILLS_DIR/adversarial" "$SKILLS_DIR/architect"

curl -fsSL "$BASE_URL/SKILL.md"                 -o "$SKILLS_DIR/SKILL.md"
curl -fsSL "$BASE_URL/skills/design/SKILL.md"    -o "$SKILLS_DIR/design/SKILL.md"
curl -fsSL "$BASE_URL/skills/design/examples/design-summary.md" -o "$SKILLS_DIR/design/examples/design-summary.md"
curl -fsSL "$BASE_URL/skills/implement/SKILL.md" -o "$SKILLS_DIR/implement/SKILL.md"
curl -fsSL "$BASE_URL/skills/review/SKILL.md"    -o "$SKILLS_DIR/review/SKILL.md"
curl -fsSL "$BASE_URL/skills/debug/SKILL.md"         -o "$SKILLS_DIR/debug/SKILL.md"
curl -fsSL "$BASE_URL/skills/adversarial/SKILL.md"   -o "$SKILLS_DIR/adversarial/SKILL.md"
curl -fsSL "$BASE_URL/skills/architect/SKILL.md"          -o "$SKILLS_DIR/architect/SKILL.md"
curl -fsSL "$BASE_URL/skills/architect/default-config.json" -o "$SKILLS_DIR/architect/default-config.json"
curl -fsSL "$BASE_URL/skills/architect/graph-template.html" -o "$SKILLS_DIR/architect/graph-template.html"

echo ""
echo "Centaur installed. Use /centaur or say 'centaur mode' in any Claude Code session."
