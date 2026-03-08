# Setup Handoff

## 현재 상태

- `install.sh` 실행 완료 → skills 심링크, settings.json 머지, CLAUDE.md 머지 완료
- 백업 위치: `~/.claude/backups/claude-ops-skills/<timestamp>/`

## 커밋 전 확인/수정 필요 사항

### 1. clusters.yaml (해결됨)
`clusters.yaml`은 이제 `.gitignore`에 포함 — repo에 커밋되지 않음.
`install.sh` 실행 시 `~/.kube/` 디렉토리를 스캔하여 로컬에 자동 생성.
- 이미 존재하면 덮어쓰지 않음 (수동 수정 보호)
- description, namespaces 등은 생성 후 필요시 수동 편집

### 2. settings.local.json 정리 (선택)
`~/.claude/settings.local.json`에 수동 누적된 개별 kubeconfig 규칙이 있을 수 있음.
`settings.json`에 와일드카드 패턴(`Bash(KUBECONFIG=* kubectl get *)`)이 머지되었으므로,
개별 규칙은 정리해도 됨. **단, 이건 선택사항.**

### 3. CLAUDE.md 추가 룰
`~/.claude/CLAUDE.md`의 `# Global Rules` 아래에 K8s 외의 개인 룰이 있었다면,
마커 블록 바깥에 다시 추가할 것 (현재는 마커 블록만 남아있음).

## 사용법

### Skills 호출
Claude Code (CLI 또는 VSCode) 재시작 후:
```
/k8s-ops <cluster-name>   # K8s 클러스터 조회
/ssh-ops user@host         # SSH 서버 인스펙션
/rpc-health http://...     # RPC 노드 헬스체크
/db-ops mydb               # DB 조회
```

### 업데이트
repo에서 skill 수정 후:
```bash
# 심링크이므로 skill 내용 변경은 즉시 반영 (재시작만 필요)
# settings.json이나 CLAUDE.md 템플릿을 수정한 경우:
./scripts/update.sh
```

### 제거
```bash
./scripts/uninstall.sh
```

## 다음 작업 후보

1. **프로젝트별 skill 적용 테스트**: 다른 프로젝트 repo에 `.claude/skills/` 추가해보기
2. **agents 테스트**: `k8s-debugger`, `rpc-monitor` 에이전트 실제 동작 확인
3. **skill 확장**: 자주 쓰는 워크플로우를 skill로 추가
