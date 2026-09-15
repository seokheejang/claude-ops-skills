---
name: sh-craft
description: Author and review shell scripts for infra ops — bash by default, POSIX sh fallback for minimal pod images, shellcheck/shfmt validation. Use when the user wants to write, review, or refactor a shell script or .sh file, or a script to run inside a K8s pod, asks "스크립트 짜줘", "쉘 스크립트", "bash script", "파드에서 실행할 스크립트".
argument-hint: "<script purpose or path>"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# sh-craft

셸 스크립트 작성/리뷰 스킬. **스크립트 파일 출력 + 실행 명령어 텍스트 안내만** 한다.

표준 bash 문법·관용구(`set -euo pipefail`, quote, `trap`, exit code 등)는 네가 이미 아는 걸 쓴다.
이 파일은 **우리 실행 환경의 결정사항과 가드레일**만 고정한다.

## Safety Rules

파드 안 상태를 바꾸는 명령은 직접 실행 금지 — 글로벌 CLAUDE.md K8s READ-ONLY 규칙.

| 동작 | 허용 |
|------|------|
| 스크립트 파일 출력 (Write/Edit) | ✅ |
| `shellcheck`, `shfmt`, `bash -n` (로컬 검증) | ✅ 직접 실행 |
| `kubectl exec ... -- bash -s < script.sh` (조회 스크립트) | ⚠️ 명령어만 안내, 실행은 사용자 |
| 파드 안 패키지 설치 (`apk add`, `apt-get install`) | ❌ 명령어만 안내 |
| K8s 리소스 변경 (`apply / patch / delete / scale / edit`) | ❌ |

## 실행 환경 — bash 기본값

```bash
#!/usr/bin/env bash
set -euo pipefail
```

`#!/bin/bash` 하드코딩 금지. macOS 기본 bash 는 3.2 라 `${x,,}` / `declare -A` 가 로컬에서만 깨져 거짓 실패를 만든다. `env` 로 PATH 우선 해석하게 둔다.

| 타깃 | 방언 | 검증 |
|------|------|------|
| 로컬·운영 호스트, Debian/Ubuntu 계열 파드 (`/bin/bash` 상재) | bash | `shellcheck -s bash` |
| bash 없는 파드 (alpine, busybox) | POSIX sh — `#!/bin/sh` + `set -eu`, **pipefail 없음** | `shellcheck -s sh` |
| distroless 파드 | 셸 자체가 없다 → **대상 아님.** 실행을 시도하지 말고 사용자에게 알린다 | — |

방언을 bash 에서 POSIX 로 내렸으면 그 이유를 결과에 한 줄로 남긴다.

## 파드 실행 — 감지와 설치를 분리한다

스크립트는 로컬 파일로 두고 stdin 으로 넘긴다. `sh -c '...'` 인라인은 쓰지 않는다 (인용부호 중첩 + 행 끝 주석이 뒤 명령을 삼킨다).

```bash
# 1) preflight — bash 유무만 확인
kubectl exec -n $NS $POD --context $CTX -- \
  sh -c 'command -v bash >/dev/null && bash --version | head -1 || echo NO_BASH'

# 2) 실행 — -i 필수
kubectl exec -i -n $NS $POD --context $CTX -- bash -s -- arg1 arg2 < script.sh
```

`-i` 를 빼면 stdin 이 안 열려서 **빈 스크립트가 exit 0 으로 조용히 성공한다.** 실패로 보이지 않으니 반드시 붙인다.

`NO_BASH` 가 나오면 순서대로:

1. **POSIX 로 재작성 가능한지 먼저 본다** → 가능하면 `bash -s` 를 `sh -s` 로 바꿔 실행. 조회 스크립트는 대개 여기서 끝난다
2. bash 기능이 꼭 필요할 때만 설치 명령을 안내한다 — `apk add --no-cache bash` (약 470KB). 실행은 사용자
3. 안내할 때 **실패 조건 3개를 함께 알린다**: `runAsNonRoot`, `readOnlyRootFilesystem`, egress 차단 NetworkPolicy. 하나라도 걸리면 런타임 설치는 불가능하고 **이미지에 bash 를 넣는 것(Dockerfile/차트 수정)이 유일한 해결책**이다

런타임 설치는 컨테이너 재시작으로 사라진다 → 재현 가능한 해결책이 아니다. 같은 파드에서 반복되면 이미지 수정을 제안한다.

## 셸을 계속 쓸지 판정

**줄 수는 기준이 아니다.** kubectl/curl/jq 를 순서대로 호출하는 조회 스크립트는 200줄이어도 셸이 맞다 (Google Shell Style Guide 도 "mostly calling other utilities" 는 셸이 적합하다고 본다). 데이터 조작이 호출보다 많아지거나 팀원이 못 읽으면 갈아탈 신호다.

갈아탈 때 제안할 것은 파드 안에서 언어를 바꾸는 게 아니라 **스크립트를 파드 밖으로 빼는 것**이다 — Python 은 bash 보다 무거워서 bash 없는 이미지에 있을 가능성이 더 낮다. 운영 호스트에서 돌리고 `kubectl` 로 데이터만 가져온다.

## 구조 — 두 등급

| 조건 | 구조 |
|------|------|
| 인자 없음 + 로직 30줄 미만 | `main()` 없이 위에서 아래로. `usage()` 도 만들지 않는다 |
| 인자를 받거나 로직 30줄 이상 | `usage()` → `main()` → 로직 함수 순, `main "$@"` 가 마지막 줄 |

## MUST NOT DO

- **색상 변수·이모지·`print_success` 류 출력 헬퍼** — `kubectl exec` 는 기본 TTY 가 없어 이스케이프 코드가 로그에 그대로 박힌다. 취향 문제가 아니라 고장이다
- **행 끝 주석** (`cmd # 설명`) — 한 줄로 넘겨지는 경로에서 `#` 뒤 명령 전체가 주석이 된다. 주석은 독립 행
- **`kubectl exec -t`** — TTY 는 stdout/stderr 를 합쳐버린다. 파이프로 받을 거면 절대 붙이지 않는다
- **stdout 에 데이터 아닌 것 섞기** — `kubectl exec` 는 `-t` 없이도 stderr 를 stdout 으로 섞어 보내는 동작이 있다 (k8s 이슈 #38998). 표준 규칙대로 `>&2` 를 써도 수신 측에서 섞여 도착해 `jq` 파이프가 깨진다. 파드용 스크립트의 stdout 은 **데이터 전용**으로 두고, 진단 메시지는 최소화하거나 접두사(`[warn]` 등)를 붙여 필터 가능하게 만든다
- 패키지 설치를 스크립트 본문에 포함 — 자기 런타임을 바꾸는 스크립트는 리뷰도 dry-run 도 안 된다

## Output

- 파일 경로: 사용자 지정 또는 `scripts/<name>.sh`
- 작성 후 **직접 검증하고 결과를 보고한다**: `shellcheck -s bash <file>` + `shfmt -i 4 -ci -d <file>`
  (repo 다수 스타일이 4-space. 기존 스크립트는 shfmt 미적용 상태이므로 **신규 파일에만** 적용하고, 기존 파일 재포맷은 별도 제안으로 분리한다)
- 도구가 없으면 설치 명령 안내: `brew install shellcheck shfmt`
- 파드에서 돌릴 스크립트면 preflight + 실행 명령을 복붙 블록으로 함께 낸다
