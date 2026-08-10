#!/usr/bin/env bash
# pre-commit hook: 보안 체크리스트 + SKILL.md frontmatter 검증
# install.sh에서 .git/hooks/pre-commit으로 심링크됨
#
# 자동 검증: 로컬경로, 인프라명, kubeconfig, IP, credentials, 민감파일,
#           skills/*/SKILL.md frontmatter 필수 필드 (name, description)
# 수동 확인 필요: 예시 파일 일반화 (my-cluster 등 제네릭명 사용 여부)

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

failed=false

# staged 파일만 대상 (삭제된 파일 제외)
staged_files=$(git diff --cached --name-only --diff-filter=d 2>/dev/null || true)
[ -z "$staged_files" ] && exit 0

# 추가되는 줄(+)만 검사한다. diff 전체를 보면 "시크릿을 제거하는 커밋"까지
# 차단되어(삭제 줄이 - 로 잡힘) 정리 작업이 막힌다. 문맥 줄은 애초에 diff에
# 안 실리므로 + 로 좁혀도 탐지력 손실은 없다.
added_lines() {
    git diff --cached "$@" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true
}

staged_content=$(added_lines)

check() {
    local label="$1" pattern="$2"
    if echo "$staged_content" | grep -qiE "$pattern"; then
        echo -e "${RED}[FAIL]${NC} $label"
        echo "$staged_content" | grep -inE "$pattern" | head -5
        echo ""
        failed=true
    fi
}

# clusters.yaml에서 인프라명 추출
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
CLUSTERS_YAML="$REPO_ROOT/skills/k8s-ops/clusters.yaml"
infra_names=""
if [ -f "$CLUSTERS_YAML" ]; then
    # 일반적인 단어(config, default 등)와 6자 미만 키는 오탐 방지를 위해 제외
    names=$(grep -E "^  [a-zA-Z]" "$CLUSTERS_YAML" | sed 's/:.*//' | tr -d ' ' \
        | grep -vE '^(config|default|local|test|prod|dev|staging)$' \
        | awk 'length >= 6' || true)

    # clusters.yaml.example의 placeholder(my-cluster 등)도 제외.
    # 이 이름들은 CLAUDE.md가 예시/템플릿에 쓰라고 규정한 제네릭 이름이므로
    # 문서에 등장하는 게 정상이다. install.sh가 example을 그대로 복사한
    # 상태(kubeconfig 미검출)라면 전체가 placeholder라 이 검사는 무력화된다.
    if [ -f "${CLUSTERS_YAML}.example" ]; then
        placeholders=$(grep -E "^  [a-zA-Z]" "${CLUSTERS_YAML}.example" \
            | sed 's/:.*//' | tr -d ' ' || true)
        if [ -n "$placeholders" ] && [ -n "$names" ]; then
            names=$(echo "$names" | grep -vxF "$placeholders" || true)
        fi
    fi

    infra_names=$(echo "$names" | grep -v '^$' | paste -sd '|' - || true)
fi

echo "=== 보안 체크리스트 ==="
echo ""

# 1. 로컬 경로 노출
check "로컬 경로 노출" "/Users/[a-zA-Z0-9._-]+/dev/|/home/[a-zA-Z0-9._-]+/dev/"

# 2. 내부 인프라명 노출 (clusters.yaml 자체는 제외)
if [ -n "$infra_names" ]; then
    # clusters.yaml, clusters.yaml.example은 인프라명이 있어도 정상
    non_cluster_files=$(echo "$staged_files" | grep -vE "clusters\.yaml" || true)
    if [ -n "$non_cluster_files" ]; then
        non_cluster_diff=$(added_lines -- $non_cluster_files)
        if echo "$non_cluster_diff" | grep -qE "$infra_names"; then
            echo -e "${RED}[FAIL]${NC} 내부 인프라명 노출 (clusters.yaml 외 파일)"
            echo "$non_cluster_diff" | grep -E "$infra_names" | head -5
            echo ""
            failed=true
        fi
    fi
fi

# 3. kubeconfig 실제 파일명 (clusters.yaml 제외)
if echo "$staged_files" | grep -qvE "clusters\.yaml"; then
    check "kubeconfig 파일명 노출" "\.kube/[a-zA-Z0-9._-]+config"
fi

# 4. IP 주소 하드코딩 (private/localhost/공개DNS/문서용 예약대역 제외)
#    제외:
#      - private: 10/8, 172.16/12, 192.168/16
#      - localhost: 127.0.0.1, 0.0.0.0
#      - 공개 DNS: 8.8.8.8, 8.8.4.4, 1.1.1.1, 1.0.0.1
#      - RFC 5737 문서용: 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24
ip_excludes="127\.0\.0\.1|0\.0\.0\.0|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|8\.8\.(8\.8|4\.4)|1\.(1\.1\.1|0\.0\.1)|192\.0\.2\.|198\.51\.100\.|203\.0\.113\."
if echo "$staged_content" | grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | grep -qvE "$ip_excludes"; then
    echo -e "${RED}[FAIL]${NC} 공인 IP 주소 하드코딩"
    echo "$staged_content" | grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | grep -vE "$ip_excludes" | head -5
    echo ""
    failed=true
fi

# 5. credentials — 다음은 변수/placeholder 참조라 실제 시크릿 아님 → 제외:
#   - bash 변수: $VAR, ${VAR}, ${!VAR}
#   - YAML/Helm placeholder: <PLACEHOLDER>, {{ .Values.x }}, "${VAR}", "${{ secrets.X }}"
#   - GitHub Actions: ${{ secrets.X }}, ${{ env.X }}
#   - 단순 reference: secretRef, secretKeyRef, valueFrom (manifest 키워드)
cred_pattern="(password|secret|token|api_key|apikey|api-key)\s*[:=]\s*['\"][^'\"]{8,}"
cred_matches=$(echo "$staged_content" | grep -inE "$cred_pattern" \
    | grep -vE '\$\{?!?[A-Z_][A-Z0-9_]*\}?' \
    | grep -vE '"[<{$]' \
    | grep -vE "'[<{\$]" \
    | grep -vE '\$\{\{' \
    | grep -vE '(secretRef|secretKeyRef|valueFrom|configMapKeyRef|configMapRef)' \
    || true)
if [ -n "$cred_matches" ]; then
    echo -e "${RED}[FAIL]${NC} 시크릿/토큰 노출"
    echo "$cred_matches" | head -5
    echo ""
    failed=true
fi

# 6. 민감 파일 커밋 시도 (.env, credentials, 키 파일)
sensitive_pattern='\.env$|/\.env$|\.env\.|credentials|\.pem$|\.key$|\.p12$|\.pfx$|\.jks$|id_rsa|id_ed25519|id_ecdsa'
if echo "$staged_files" | grep -qE "$sensitive_pattern"; then
    echo -e "${RED}[FAIL]${NC} 민감 파일 커밋 시도"
    echo "$staged_files" | grep -E "$sensitive_pattern"
    echo ""
    failed=true
fi

# 7. SKILL.md frontmatter 필수 필드 (name, description) — templates/ 제외
skill_files=$(echo "$staged_files" | grep -E '^skills/[^/]+/SKILL\.md$' || true)
if [ -n "$skill_files" ]; then
    while IFS= read -r skill_file; do
        [ -z "$skill_file" ] && continue
        [ ! -f "$skill_file" ] && continue
        # frontmatter 영역(첫 --- ~ 두번째 ---)에서 name/description 확인
        frontmatter=$(awk '/^---$/{c++; next} c==1' "$skill_file")
        if ! echo "$frontmatter" | grep -qE '^name:[[:space:]]*[^[:space:]]+'; then
            echo -e "${RED}[FAIL]${NC} $skill_file: frontmatter에 name 필드 누락"
            failed=true
        fi
        if ! echo "$frontmatter" | grep -qE '^description:[[:space:]]*[^[:space:]]+'; then
            echo -e "${RED}[FAIL]${NC} $skill_file: frontmatter에 description 필드 누락"
            failed=true
        fi
    done <<< "$skill_files"
fi

if [ "$failed" = true ]; then
    echo -e "${YELLOW}커밋이 차단되었습니다. 위 항목을 확인 후 다시 시도하세요.${NC}"
    echo "무시하려면: git commit --no-verify"
    exit 1
else
    echo -e "전체 통과 ✓"
fi
