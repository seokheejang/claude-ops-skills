#!/usr/bin/env bash
set -euo pipefail

# =========================================
#  claude-ops-skills installer
#  - Skills를 ~/.claude/skills/에 심링크
#  - settings.json allow/deny 규칙 머지
#  - CLAUDE.md 마커 기반 머지
#  - settings.local.json은 절대 건드리지 않음
# =========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
BACKUP_DIR="$CLAUDE_DIR/backups/claude-ops-skills/$(date +%Y%m%d_%H%M%S)"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CLAUDE_MD_FILE="$CLAUDE_DIR/CLAUDE.md"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "${BLUE}[STEP]${NC} $1"; }

backed_up=false

# --- 의존성 확인 ---
check_dependencies() {
    local missing=()
    command -v jq &> /dev/null    || missing+=("jq")
    command -v shfmt &> /dev/null || missing+=("shfmt")

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "필수 의존성이 없습니다: ${missing[*]}"
        log_error "설치: brew install ${missing[*]}"
        exit 1
    fi
}

# --- 백업 ---
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        backed_up=true
        log_info "  백업: $(basename "$file") → $BACKUP_DIR/"
    fi
}

backup_dir() {
    local dir="$1"
    local name="$2"
    if [ -d "$dir" ]; then
        mkdir -p "$BACKUP_DIR/skills"
        cp -r "$dir" "$BACKUP_DIR/skills/$name"
        backed_up=true
        log_info "  백업: skills/$name/ → $BACKUP_DIR/skills/"
    fi
}

# --- Skills 심링크 ---
install_skills() {
    log_step "Skills 설치 중..."
    mkdir -p "$SKILLS_DIR"

    for skill_dir in "$REPO_DIR"/skills/*/; do
        [ -d "$skill_dir" ] || continue
        local skill_name
        skill_name="$(basename "$skill_dir")"
        local target="$SKILLS_DIR/$skill_name"
        local source="${skill_dir%/}"

        # 이미 올바른 심링크인 경우
        if [ -L "$target" ]; then
            local current_link
            current_link="$(readlink "$target")"
            if [ "$current_link" = "$source" ]; then
                log_info "  $skill_name: 이미 심링크됨 ✓"
                continue
            else
                log_warn "  $skill_name: 다른 곳을 가리키는 심링크 → 업데이트"
                rm "$target"
            fi
        # 일반 디렉토리인 경우
        elif [ -d "$target" ]; then
            log_warn "  $skill_name: 기존 디렉토리 발견 → 백업 후 교체"
            backup_dir "$target" "$skill_name"
            rm -rf "$target"
        # 일반 파일인 경우
        elif [ -e "$target" ]; then
            log_warn "  $skill_name: 기존 파일 발견 → 백업 후 교체"
            backup_file "$target"
            rm "$target"
        fi

        ln -s "$source" "$target"
        log_info "  $skill_name: 심링크 생성 → $source"
    done
}

# --- settings.json 머지 ---
merge_settings() {
    log_step "settings.json 머지 중..."
    local template="$REPO_DIR/configs/settings.json.template"

    if [ ! -f "$template" ]; then
        log_error "템플릿 없음: $template"
        return 1
    fi

    # __REPO_DIR__ 치환된 임시 템플릿 생성
    local resolved_template
    resolved_template=$(mktemp)
    sed "s|__REPO_DIR__|${REPO_DIR}|g" "$template" > "$resolved_template"

    # settings.json이 없으면 새로 생성
    if [ ! -f "$SETTINGS_FILE" ]; then
        log_warn "기존 settings.json 없음 → 템플릿에서 생성"
        jq 'del(._comment) | del(._categories)' "$resolved_template" > "$SETTINGS_FILE"
        log_info "  settings.json 생성 완료"
        rm -f "$resolved_template"
        return
    fi

    backup_file "$SETTINGS_FILE"

    # permissions + hooks 머지 (기존 설정 보존)
    local merged
    merged=$(jq -s --arg repo_dir "$REPO_DIR" '
        .[0] as $template | .[1] as $existing |

        # permissions 머지
        ($existing * {
            permissions: {
                allow: (
                    (($existing.permissions.allow // []) + ($template.permissions.allow // []))
                    | unique
                ),
                deny: (
                    (($existing.permissions.deny // []) + ($template.permissions.deny // []))
                    | unique
                )
            }
        }) |

        # hooks 머지 (기존 hooks 보존 + 템플릿 hooks 추가)
        .hooks = (
            ($existing.hooks // {}) as $eh |
            ($template.hooks // {}) as $th |
            ($eh | to_entries) as $existing_entries |
            ($th | to_entries) as $template_entries |
            (
                $existing_entries + (
                    $template_entries | map(
                        .key as $k | .value as $v |
                        if ($eh | has($k)) then
                            # 같은 이벤트 타입이 있으면 command 기준으로 중복 제거 후 합침
                            {
                                key: $k,
                                value: (
                                    ($eh[$k] + $v)
                                    | unique_by(.hooks[0].command)
                                )
                            }
                        else
                            # 새 이벤트 타입이면 그대로 추가
                            {key: $k, value: $v}
                        end
                    )
                )
            ) | unique_by(.key) | from_entries
        )
    ' "$resolved_template" "$SETTINGS_FILE")

    # _comment, _categories 필드 제거
    echo "$merged" | jq 'del(._comment) | del(._categories)' > "$SETTINGS_FILE"
    rm -f "$resolved_template"
    log_info "  settings.json 머지 완료 (permissions + hooks)"
}

# --- CLAUDE.md 머지 ---
merge_claude_md() {
    log_step "CLAUDE.md 머지 중..."
    local template="$REPO_DIR/configs/claude.md.template"
    local start_marker="# === claude-ops-skills:start ==="
    local end_marker="# === claude-ops-skills:end ==="

    if [ ! -f "$template" ]; then
        log_error "템플릿 없음: $template"
        return 1
    fi

    # CLAUDE.md가 없으면 새로 생성
    if [ ! -f "$CLAUDE_MD_FILE" ]; then
        log_warn "기존 CLAUDE.md 없음 → 템플릿에서 생성"
        cp "$template" "$CLAUDE_MD_FILE"
        log_info "  CLAUDE.md 생성 완료"
        return
    fi

    backup_file "$CLAUDE_MD_FILE"

    if grep -qF "$start_marker" "$CLAUDE_MD_FILE"; then
        # 마커 사이 내용 교체
        local template_content
        template_content="$(cat "$template")"

        awk -v start="$start_marker" -v end="$end_marker" -v replacement="TEMPLATE_PLACEHOLDER" '
            index($0, start) { skip=1; print replacement; next }
            index($0, end) { skip=0; next }
            !skip { print }
        ' "$CLAUDE_MD_FILE" > "$CLAUDE_MD_FILE.tmp"

        # placeholder를 실제 내용으로 교체
        python3 -c "
import sys
with open('$CLAUDE_MD_FILE.tmp', 'r') as f:
    content = f.read()
with open('$template', 'r') as f:
    replacement = f.read()
content = content.replace('TEMPLATE_PLACEHOLDER', replacement)
with open('$CLAUDE_MD_FILE.tmp', 'w') as f:
    f.write(content)
"
        mv "$CLAUDE_MD_FILE.tmp" "$CLAUDE_MD_FILE"
        log_info "  CLAUDE.md: 마커 사이 내용 업데이트 완료"
    else
        # 마커가 없으면 기존 내용 뒤에 추가
        echo "" >> "$CLAUDE_MD_FILE"
        cat "$template" >> "$CLAUDE_MD_FILE"
        log_info "  CLAUDE.md: 기존 내용 보존 + 템플릿 추가"
    fi
}

# --- clusters.yaml 자동 생성 ---
generate_clusters_yaml() {
    local clusters_file="$REPO_DIR/skills/k8s-ops/clusters.yaml"
    local kube_dir="${KUBE_CONFIG_DIR:-$HOME/.kube}"

    if [ -f "$clusters_file" ]; then
        log_info "  clusters.yaml 이미 존재 → 스킵 (수동 수정 보호)"
        return
    fi

    log_step "clusters.yaml 자동 생성 중 (~/.kube/ 스캔)..."

    if [ ! -d "$kube_dir" ]; then
        log_warn "  $kube_dir 디렉토리 없음 → clusters.yaml.example 복사"
        cp "$REPO_DIR/skills/k8s-ops/clusters.yaml.example" "$clusters_file"
        return
    fi

    # kubeconfig 파일 탐색 (config, *_config, kubeconfig-* 패턴)
    local configs=()
    for f in "$kube_dir"/*; do
        [ -f "$f" ] || continue
        local basename
        basename="$(basename "$f")"
        # 숨김파일, 디렉토리, 캐시/http-cache, 확장자 있는 파일(*.crt, *.key, *.pem 등) 제외
        case "$basename" in
            .*|cache|http-cache|*.crt|*.key|*.pem|*.pub|*.bak|*.tmp|*.log) continue ;;
        esac
        configs+=("$f")
    done

    if [ ${#configs[@]} -eq 0 ]; then
        log_warn "  kubeconfig 파일을 찾을 수 없음 → clusters.yaml.example 복사"
        cp "$REPO_DIR/skills/k8s-ops/clusters.yaml.example" "$clusters_file"
        return
    fi

    # YAML 생성
    {
        echo "# Cluster configuration mapping (auto-generated by install.sh)"
        echo "# Maps friendly names to kubeconfig paths and metadata"
        echo "# No secrets - only names, paths, and descriptive metadata"
        echo "#"
        echo "# 이 파일을 수정하면 다음 install.sh 실행 시 덮어쓰지 않습니다."
        echo ""
        echo "clusters:"

        local first_name=""
        for config_path in "${configs[@]}"; do
            local filename
            filename="$(basename "$config_path")"
            # 파일명에서 friendly name 생성: _ → -, kubeconfig- 접두사 제거, _config 접미사 제거
            local friendly
            friendly="$(echo "$filename" | sed -E 's/^kubeconfig-//; s/_config$//; s/_/-/g')"

            [ -z "$first_name" ] && first_name="$friendly"

            echo "  $friendly:"
            echo "    kubeconfig: \"~/.kube/$filename\""
            echo "    description: \"$friendly cluster\""
            echo "    namespaces:"
            echo "      - default"
            echo ""
        done

        echo "default_cluster: $first_name"
    } > "$clusters_file"

    log_info "  clusters.yaml 생성 완료 (${#configs[@]}개 kubeconfig 감지)"
    log_warn "  → description, namespaces 등은 필요시 수동 편집하세요"
}

# --- pre-commit hook 설치 ---
install_precommit_hook() {
    log_step "pre-commit hook 설치 중..."
    local hook_source="$REPO_DIR/scripts/pre-commit.sh"
    local hook_target="$REPO_DIR/.git/hooks/pre-commit"

    if [ ! -f "$hook_source" ]; then
        log_warn "  pre-commit.sh 없음 → 스킵"
        return
    fi

    if [ -L "$hook_target" ] && [ "$(readlink "$hook_target")" = "$hook_source" ]; then
        log_info "  pre-commit hook: 이미 설치됨 ✓"
        return
    fi

    if [ -f "$hook_target" ]; then
        log_warn "  기존 pre-commit hook 발견 → 백업 후 교체"
        backup_file "$hook_target"
    fi

    ln -sf "$hook_source" "$hook_target"
    log_info "  pre-commit hook 심링크 생성 완료"
}

# --- 백업 정리 (최근 N개만 보존) ---
cleanup_backups() {
    local backup_base="$CLAUDE_DIR/backups/claude-ops-skills"
    local keep=3

    [ -d "$backup_base" ] || return

    local count
    count=$(find "$backup_base" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')

    if [ "$count" -le "$keep" ]; then
        log_info "  백업 ${count}개 — 정리 불필요"
        return
    fi

    local to_delete=$((count - keep))
    find "$backup_base" -maxdepth 1 -mindepth 1 -type d | sort | head -n "$to_delete" | while read -r dir; do
        rm -rf "$dir"
        log_info "  삭제: $(basename "$dir")"
    done
    log_info "  백업 정리 완료 (${to_delete}개 삭제, 최근 ${keep}개 보존)"
}

# --- 메인 ---
main() {
    echo ""
    echo "========================================"
    echo "  claude-ops-skills installer"
    echo "========================================"
    echo ""

    check_dependencies

    if [ ! -d "$REPO_DIR/skills" ]; then
        log_error "skills 디렉토리를 찾을 수 없습니다."
        exit 1
    fi

    generate_clusters_yaml
    echo ""
    install_skills
    echo ""
    merge_settings
    echo ""
    merge_claude_md
    echo ""

    install_precommit_hook
    echo ""

    log_step "백업 정리 중..."
    cleanup_backups

    echo ""
    echo "========================================"
    echo "  설치 완료"
    echo "========================================"
    echo ""

    echo "Skills 설치 위치: $SKILLS_DIR"
    if [ -d "$SKILLS_DIR" ]; then
        for item in "$SKILLS_DIR"/*/; do
            [ -d "$item" ] || continue
            local name
            name="$(basename "$item")"
            if [ -L "$item" ] || [ -L "${item%/}" ]; then
                echo "  /$name → $(readlink "${item%/}" 2>/dev/null || echo "symlink")"
            else
                echo "  /$name (local)"
            fi
        done
    fi

    echo ""
    if [ "$backed_up" = true ]; then
        echo "백업 위치: $BACKUP_DIR"
    else
        echo "백업 불필요 (클린 설치)"
    fi

    echo ""
    echo "⚠️  ~/.claude/settings.local.json은 수정하지 않았습니다."
    echo ""
    log_info "Claude Code를 재시작하면 변경사항이 적용됩니다."
    echo ""
}

main "$@"
