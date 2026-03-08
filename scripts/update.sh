#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "최신 변경사항 pull 중..."
cd "$REPO_DIR"
git pull

echo ""
echo "install.sh 재실행 중..."
bash "$SCRIPT_DIR/install.sh"
