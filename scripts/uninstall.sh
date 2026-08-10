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

# repo에서 이미 삭제된 skill의 잔여 심링크도 제거.
# 위 루프는 "$REPO_DIR"/skills/*/ 를 순회하므로 삭제된 skill은 잡히지 않는다.
# 이 repo의 skills/ 를 가리키면서 대상이 사라진 심링크만 지운다 (남의 링크는 유지).
for target in "$SKILLS_DIR"/*; do
    [ -L "$target" ] || continue
    [ -e "$target" ] && continue
    case "$(readlink "$target")" in
        "$REPO_DIR"/skills/*)
            rm "$target"
            echo "  잔여 심링크 제거: $(basename "$target") (repo에서 삭제된 skill)"
            ;;
    esac
done

# 외부 skill 심링크 제거 (clone된 코드 자체는 보존 — 재다운로드 비용, 타 프로젝트 공유 가능성)
EXTERNAL_SKILLS_DIR="${EXTERNAL_SKILLS_DIR:-$HOME/.claude/external-skills}"
manifest="$REPO_DIR/configs/external-skills.tsv"
if [ -f "$manifest" ]; then
    while IFS=$'\t' read -r name clone_url skill_subdir description || [ -n "$name" ]; do
        case "$name" in
            ''|\#*) continue ;;
        esac
        target="$SKILLS_DIR/$name"
        expected="$EXTERNAL_SKILLS_DIR/$name/$skill_subdir"
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$expected" ]; then
            rm "$target"
            echo "  외부 skill 심링크 제거: $name (clone은 $EXTERNAL_SKILLS_DIR/$name 에 보존)"
        fi
    done < "$manifest"
fi

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
