#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"

echo ""
echo "========================================"
echo "  claude-ops-skills uninstaller"
echo "========================================"
echo ""

# 이 repo가 만든 심링크만 제거
for skill_dir in "$REPO_DIR"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    target="$SKILLS_DIR/$skill_name"
    source="${skill_dir%/}"

    if [ -L "$target" ]; then
        current="$(readlink "$target")"
        if [ "$current" = "$source" ]; then
            rm "$target"
            echo "  심링크 제거: $skill_name"
        fi
    fi
done

# CLAUDE.md에서 관리 영역 제거
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    start_marker="# === claude-ops-skills:start ==="
    end_marker="# === claude-ops-skills:end ==="
    if grep -qF "$start_marker" "$CLAUDE_DIR/CLAUDE.md"; then
        awk -v start="$start_marker" -v end="$end_marker" '
            index($0, start) { skip=1; next }
            index($0, end) { skip=0; next }
            !skip { print }
        ' "$CLAUDE_DIR/CLAUDE.md" > "$CLAUDE_DIR/CLAUDE.md.tmp"
        mv "$CLAUDE_DIR/CLAUDE.md.tmp" "$CLAUDE_DIR/CLAUDE.md"
        echo "  CLAUDE.md에서 관리 영역 제거 완료"
    fi
fi

echo ""
echo "제거 완료."
echo "settings.json은 수정하지 않았습니다 (필요시 수동으로 규칙을 제거하세요)."
echo ""
