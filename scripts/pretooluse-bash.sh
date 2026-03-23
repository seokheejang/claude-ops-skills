#!/usr/bin/env bash
# =========================================
#  PreToolUse Hook: Bash 복합 명령 자동 승인
#
#  settings.json의 allow/deny 목록을 재사용하여
#  복합 명령(파이프, 체이닝, 리다이렉트 등)의
#  모든 서브 명령을 검증합니다.
#
#  - 모든 서브 명령이 allow → approve
#  - 하나라도 deny → block
#  - 판단 불가 → 기존 permission 시스템으로 위임
#
#  의존성: jq, shfmt
#  참고: github.com/oryband/claude-code-auto-approve
# =========================================

set -uo pipefail

# --- macOS bash 3.x 호환: 최신 bash로 re-exec ---
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  for try_bash in /opt/homebrew/bin/bash /usr/local/bin/bash; do
    if [[ -x "$try_bash" ]]; then
      exec "$try_bash" "$0" "$@"
    fi
  done
  exit 0  # 최신 bash 못 찾으면 pass through
fi

# --- 출력 형식 (hookSpecificOutput 표준) ---
readonly ALLOW_JSON='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'

approve() { echo "$ALLOW_JSON"; exit 0; }
block() {
  echo "$1" >&2
  exit 2
}

# --- 의존성 확인 ---
for dep in jq shfmt; do
  if ! command -v "$dep" &>/dev/null; then
    exit 1  # 의존성 없으면 permission 시스템으로 위임
  fi
done

# --- stdin에서 JSON 읽기 ---
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Bash 도구만 처리
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 1
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 1

# --- settings.json에서 allow/deny prefix 로드 ---
find_git_root() {
  git rev-parse --show-toplevel 2>/dev/null || true
}

load_prefixes() {
  local git_root
  git_root=$(find_git_root)

  local files=(
    "$HOME/.claude/settings.json"
    "$HOME/.claude/settings.local.json"
  )
  if [ -n "$git_root" ]; then
    files+=("$git_root/.claude/settings.json" "$git_root/.claude/settings.local.json")
  fi

  for file in "${files[@]}"; do
    [ -f "$file" ] || continue
    jq -r '
      def extract_prefix: sub("^Bash\\("; "") | sub("( \\*|\\*|:\\*)\\)$"; "") | sub("\\)$"; "");
      (.permissions.allow[]? // empty | select(startswith("Bash(")) | "allow:" + extract_prefix),
      (.permissions.deny[]?  // empty | select(startswith("Bash(")) | "deny:"  + extract_prefix)
    ' "$file" 2>/dev/null || true
  done | sort -u
}

ALLOWED_PREFIXES=()
DENIED_PREFIXES=()

while IFS= read -r line; do
  case "$line" in
    allow:*) ALLOWED_PREFIXES+=("${line#allow:}") ;;
    deny:*)  DENIED_PREFIXES+=("${line#deny:}") ;;
  esac
done < <(load_prefixes)

# allow 목록이 비어있으면 판단 불가 → 위임
[ ${#ALLOWED_PREFIXES[@]} -eq 0 ] && exit 1

# --- shfmt AST에서 명령 추출하는 jq 필터 ---
read -r -d '' SHFMT_JQ_FILTER << 'JQEOF' || true
def get_part_value:
  if (type == "object" | not) then ""
  elif .Type == "Lit" then .Value // ""
  elif .Type == "DblQuoted" then
    ([.Parts[]? | get_part_value] | join(""))
  elif .Type == "SglQuoted" then
    (.Value // "")
  elif .Type == "ParamExp" then
    "$" + (.Param.Value // "")
  elif .Type == "CmdSubst" then "$(..)"
  else ""
  end;

def find_cmd_substs:
  if type == "object" then
    if .Type == "CmdSubst" or .Type == "ProcSubst" then .
    elif .Type == "DblQuoted" then .Parts[]? | find_cmd_substs
    elif .Type == "ParamExp" then
      (.Exp?.Word | find_cmd_substs),
      (.Repl?.Orig | find_cmd_substs),
      (.Repl?.With | find_cmd_substs)
    elif .Parts then .Parts[]? | find_cmd_substs
    else empty
    end
  elif type == "array" then .[] | find_cmd_substs
  else empty
  end;

def get_arg_value:
  [.Parts[]? | get_part_value] | join("");

def get_command_string:
  if .Type == "CallExpr" and .Args then
    [.Args[] | get_arg_value] | map(select(length > 0)) | join(" ")
  else empty
  end;

def extract_commands:
  if type == "object" then
    if .Type == "CallExpr" then
      get_command_string,
      (.Args[]? | find_cmd_substs | .Stmts[]? | extract_commands),
      (.Assigns[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands),
      (.Redirs[]?.Word | find_cmd_substs | .Stmts[]? | extract_commands)
    elif .Type == "BinaryCmd" then
      (.X | extract_commands), (.Y | extract_commands)
    elif .Type == "Subshell" or .Type == "Block" then
      (.Stmts[]? | extract_commands)
    elif .Type == "CmdSubst" then
      (.Stmts[]? | extract_commands)
    elif .Type == "IfClause" then
      (.Cond[]? | extract_commands),
      (.Then[]? | extract_commands),
      (.Else | extract_commands)
    elif .Type == "WhileClause" or .Type == "UntilClause" then
      (.Cond[]? | extract_commands), (.Do[]? | extract_commands)
    elif .Type == "ForClause" then
      (.Loop.Items[]? | find_cmd_substs | .Stmts[]? | extract_commands),
      (.Do[]? | extract_commands)
    elif .Type == "CaseClause" then
      (.Items[]?.Stmts[]? | extract_commands)
    elif .Type == "DeclClause" then
      (.Args[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands),
      (.Args[]?.Array?.Elems[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands)
    elif .Cmd then
      (.Cmd | extract_commands),
      (.Redirs[]?.Word | find_cmd_substs | .Stmts[]? | extract_commands)
    elif .Stmts then
      (.Stmts[] | extract_commands)
    else
      (.[] | extract_commands)
    end
  elif type == "array" then
    (.[] | extract_commands)
  else empty
  end;

extract_commands | select(length > 0)
JQEOF

# --- 복합 명령 판별 ---
needs_compound_parse() {
  # 쉘 메타문자가 있으면 복합 명령 (리다이렉트 >, >>, 서브셸 () 포함)
  [[ "$1" == *['|&;`>()']* || "$1" == *'$('* || "$1" == *'<('* ]]
}

# --- 환경변수 prefix 제거 후 명령 비교 ---
strip_env_vars() {
  local cmd="$1"
  local stripped="$cmd"
  while [[ "$stripped" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*) ]]; do
    stripped="${BASH_REMATCH[1]}"
  done
  echo "$stripped"
}

# --- wrapper 명령 (env, sudo, command, builtin) 제거 ---
strip_wrappers() {
  local cmd="$1"
  local stripped="$cmd"
  while [[ "$stripped" =~ ^(env|sudo|command|builtin)[[:space:]]+(.*) ]]; do
    stripped="${BASH_REMATCH[2]}"
  done
  echo "$stripped"
}

# --- prefix 매칭 ---
matches_list() {
  local full_command="$1"
  shift
  local prefixes=("$@")

  # 원본 + 환경변수 제거 + wrapper 제거 버전 모두 체크
  local stripped wrapped
  stripped=$(strip_env_vars "$full_command")
  wrapped=$(strip_wrappers "$full_command")
  local env_and_wrap
  env_and_wrap=$(strip_wrappers "$stripped")
  local candidates=("$full_command")
  [ "$stripped" != "$full_command" ] && candidates+=("$stripped")
  [ "$wrapped" != "$full_command" ] && candidates+=("$wrapped")
  [ "$env_and_wrap" != "$full_command" ] && [ "$env_and_wrap" != "$stripped" ] && [ "$env_and_wrap" != "$wrapped" ] && candidates+=("$env_and_wrap")

  for cmd in "${candidates[@]}"; do
    for prefix in "${prefixes[@]}"; do
      if [[ "$cmd" == "$prefix" ]] || [[ "$cmd" == "$prefix "* ]] || [[ "$cmd" == "$prefix/"* ]]; then
        return 0
      fi
    done
  done
  return 1
}

is_denied() {
  [ ${#DENIED_PREFIXES[@]} -eq 0 ] && return 1
  matches_list "$1" "${DENIED_PREFIXES[@]}"
}

is_allowed() {
  # deny가 우선
  is_denied "$1" && return 1
  matches_list "$1" "${ALLOWED_PREFIXES[@]}"
}

# --- 복합 명령 파싱 ---
parse_compound() {
  local cmd="$1"
  local ast
  if ! ast=$(shfmt -ln bash -tojson <<< "$cmd" 2>/dev/null); then
    return 1
  fi
  jq -r "$SHFMT_JQ_FILTER" <<< "$ast" 2>/dev/null || return 1
}

# --- 간접 실행 명령 추출 (bash -c, sh -c, eval) ---
extract_indirect_commands() {
  local cmd="$1"
  # bash -c "cmd" / sh -c "cmd" 패턴
  if [[ "$cmd" =~ ^(bash|sh)[[:space:]]+-c[[:space:]]+(.*) ]]; then
    local inner="${BASH_REMATCH[2]}"
    inner="${inner#\"}" ; inner="${inner%\"}"
    inner="${inner#\'}" ; inner="${inner%\'}"
    echo "$inner"
    return
  fi
  # eval "cmd" 패턴
  if [[ "$cmd" =~ ^eval[[:space:]]+(.*) ]]; then
    local inner="${BASH_REMATCH[1]}"
    inner="${inner#\"}" ; inner="${inner%\"}"
    inner="${inner#\'}" ; inner="${inner%\'}"
    echo "$inner"
    return
  fi
}

# --- bash/sh + redirect (heredoc/herestring) 감지 ---
is_shell_with_redirect() {
  local cmd="$1"
  [[ "$cmd" =~ ^(bash|sh)([[:space:]]|$) ]]
}

# --- 따옴표 제거 (단순 명령용) ---
strip_quotes() {
  local cmd="$1"
  echo "$cmd" | sed "s/['\"]//g"
}

# --- 메인 로직 ---

# 단순 명령 (쉘 메타문자 없음) → 직접 체크
if ! needs_compound_parse "$COMMAND"; then
  # 따옴표 제거 버전도 deny 체크
  UNQUOTED=$(strip_quotes "$COMMAND")
  if is_denied "$COMMAND" || is_denied "$UNQUOTED"; then
    block "차단된 명령입니다"
  fi
  # 간접 실행 (bash -c, eval) 내부 명령 deny 체크
  INDIRECT=$(extract_indirect_commands "$COMMAND")
  if [ -z "$INDIRECT" ]; then
    INDIRECT=$(extract_indirect_commands "$UNQUOTED")
  fi
  if [ -n "$INDIRECT" ]; then
    INDIRECT_UNQUOTED=$(strip_quotes "$INDIRECT")
    if is_denied "$INDIRECT" || is_denied "$INDIRECT_UNQUOTED"; then
      block "간접 실행에 차단된 명령이 포함되어 있습니다: $INDIRECT"
    fi
    exit 1  # 간접 실행은 allow 판단 불가 → 위임
  fi
  # bash/sh + herestring/heredoc → 위임
  if is_shell_with_redirect "$COMMAND" && [[ "$COMMAND" == *'<'* ]]; then
    exit 1  # 위임
  fi
  is_allowed "$COMMAND" && approve
  is_allowed "$UNQUOTED" && approve
  exit 1  # 판단 불가 → 위임
fi

# 복합 명령 → shfmt로 모든 서브 명령 추출
EXTRACTED=()
while IFS= read -r line; do
  [ -n "$line" ] && EXTRACTED+=("$line")
done < <(parse_compound "$COMMAND")

# 파싱 실패 또는 빈 결과 → 위임 (안전하지 않은 것을 승인하지 않음)
[ ${#EXTRACTED[@]} -eq 0 ] && exit 1

# 하나라도 deny → block (간접 실행 내부 명령도 검증)
for cmd in "${EXTRACTED[@]}"; do
  if is_denied "$cmd"; then
    block "복합 명령에 차단된 서브 명령이 포함되어 있습니다: $cmd"
  fi
  # bash -c / sh -c / eval 내부 명령도 deny 체크
  local_inner=$(extract_indirect_commands "$cmd")
  if [ -n "$local_inner" ]; then
    if is_denied "$local_inner"; then
      block "간접 실행에 차단된 명령이 포함되어 있습니다: $local_inner"
    fi
  fi
  # bash/sh + redirect 패턴 → 위임 (내부 명령 판단 불가)
  if is_shell_with_redirect "$cmd" && [[ "$COMMAND" == *'<'* || "$COMMAND" == *'<<'* ]]; then
    exit 1  # 위임
  fi
done

# 모든 서브 명령이 allow → approve
all_allowed=true
for cmd in "${EXTRACTED[@]}"; do
  # 변수 확장($)이 포함된 명령은 런타임에서만 결정 → 위임
  if [[ "$cmd" == *'$'* ]]; then
    all_allowed=false
    break
  fi
  # 간접 실행 명령은 내부를 재귀 검증
  local_inner=$(extract_indirect_commands "$cmd")
  if [ -n "$local_inner" ]; then
    if ! is_allowed "$local_inner"; then
      all_allowed=false
      break
    fi
    continue
  fi
  if ! is_allowed "$cmd"; then
    all_allowed=false
    break
  fi
done

if $all_allowed; then
  approve
fi

# 일부가 판단 불가 → 위임
exit 1
