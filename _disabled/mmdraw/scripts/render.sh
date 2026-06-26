#!/usr/bin/env bash
# mmdraw render — .mmd 를 .png 로 렌더링
# 우선순위: 로컬 mmdc > npx @mermaid-js/mermaid-cli
#
# 사용법:
#   render.sh <file.mmd> [--width N] [--bg COLOR]
#
# 옵션:
#   --width    가로 해상도 (기본 1400, 복잡하면 1800 권장)
#   --bg       배경색 (기본 white, 투명은 transparent)

set -euo pipefail

WIDTH=1400
BG="white"
INPUT=""

while [ $# -gt 0 ]; do
    case "$1" in
        --width) WIDTH="$2"; shift 2 ;;
        --bg)    BG="$2";    shift 2 ;;
        -h|--help)
            grep -E '^#( |$)' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *)
            if [ -z "$INPUT" ]; then
                INPUT="$1"
            else
                echo "[ERROR] 알 수 없는 인자: $1" >&2
                exit 2
            fi
            shift ;;
    esac
done

if [ -z "$INPUT" ]; then
    echo "[ERROR] 입력 파일이 필요합니다. 사용법: render.sh <file.mmd>" >&2
    exit 2
fi

if [ ! -f "$INPUT" ]; then
    echo "[ERROR] 파일을 찾을 수 없습니다: $INPUT" >&2
    exit 2
fi

OUTPUT="${INPUT%.mmd}.png"

if command -v mmdc >/dev/null 2>&1; then
    echo "[INFO] 로컬 mmdc 사용"
    mmdc -i "$INPUT" -o "$OUTPUT" -b "$BG" -w "$WIDTH"
else
    echo "[INFO] mmdc 없음, npx로 fallback (첫 실행은 60-120초 소요)"
    npx -y -p @mermaid-js/mermaid-cli mmdc -i "$INPUT" -o "$OUTPUT" -b "$BG" -w "$WIDTH"
fi

if [ -f "$OUTPUT" ]; then
    echo "[OK] $OUTPUT"
else
    echo "[ERROR] 렌더링 실패. .mmd 파일은 보존됨: $INPUT" >&2
    exit 1
fi
