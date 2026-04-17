#!/usr/bin/env bash
# pre-commit hook: CLAUDE.md 보안 체크리스트 자동 검증 (7항목 중 5항목)
# install.sh에서 .git/hooks/pre-commit으로 심링크됨
#
# 자동 검증: 로컬경로, 인프라명, kubeconfig, IP, credentials, 민감파일(.env/.pem/.key)
# 수동 확인 필요: 예시 파일 일반화 (my-cluster 등 제네릭명 사용 여부)

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

failed=false

# staged 파일만 대상 (삭제된 파일 제외)
staged_files=$(git diff --cached --name-only --diff-filter=d 2>/dev/null || true)
[ -z "$staged_files" ] && exit 0

staged_content=$(git diff --cached 2>/dev/null || true)

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
    infra_names=$(grep -E "^  [a-zA-Z]" "$CLUSTERS_YAML" | sed 's/:.*//' | tr -d ' ' \
        | grep -vE '^(config|default|local|test|prod|dev|staging)$' \
        | awk 'length >= 6' \
        | paste -sd '|' -)
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
        non_cluster_diff=$(git diff --cached -- $non_cluster_files 2>/dev/null || true)
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

# 4. IP 주소 하드코딩 (private/localhost 제외)
if echo "$staged_content" | grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | grep -qvE "127\.0\.0\.1|0\.0\.0\.0|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\."; then
    echo -e "${RED}[FAIL]${NC} 공인 IP 주소 하드코딩"
    echo "$staged_content" | grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | grep -vE "127\.0\.0\.1|0\.0\.0\.0|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\." | head -5
    echo ""
    failed=true
fi

# 5. credentials (bash 변수 참조 $VAR, ${VAR}, ${!VAR}는 이름 참조일 뿐 값 아님 → 제외)
cred_pattern="(password|secret|token|api_key|apikey|api-key)\s*[:=]\s*['\"][^'\"]{8,}"
cred_matches=$(echo "$staged_content" | grep -inE "$cred_pattern" | grep -vE '\$\{?!?[A-Z_][A-Z0-9_]*\}?' || true)
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

if [ "$failed" = true ]; then
    echo -e "${YELLOW}커밋이 차단되었습니다. 위 항목을 확인 후 다시 시도하세요.${NC}"
    echo "무시하려면: git commit --no-verify"
    exit 1
else
    echo -e "전체 통과 ✓"
fi
