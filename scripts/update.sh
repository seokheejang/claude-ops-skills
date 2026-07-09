#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "최신 변경사항 pull 중..."
cd "$REPO_DIR"
git pull

# --external 플래그: 외부 skill(configs/external-skills.tsv)의 upstream도 git pull
# (기본 미포함 — 로컬 변경을 덮지 않도록 명시적 opt-in)
if [ "${1:-}" = "--external" ]; then
    EXTERNAL_SKILLS_DIR="${EXTERNAL_SKILLS_DIR:-$HOME/.claude/external-skills}"
    manifest="$REPO_DIR/configs/external-skills.tsv"
    if [ -f "$manifest" ]; then
        echo ""
        echo "외부 skill upstream 갱신 중..."
        while IFS=$'\t' read -r name clone_url skill_subdir description || [ -n "$name" ]; do
            case "$name" in
                ''|\#*) continue ;;
            esac
            clone_path="$EXTERNAL_SKILLS_DIR/$name"
            if [ -d "$clone_path/.git" ]; then
                echo "  $name: git pull"
                git -C "$clone_path" pull --ff-only || echo "  $name: pull 실패 (로컬 변경 확인 필요)"
            fi
        done < "$manifest"
    fi
fi

echo ""
echo "install.sh 재실행 중..."
bash "$SCRIPT_DIR/install.sh"
