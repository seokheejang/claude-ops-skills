---
name: ssh-ops
description: SSH server inspection - check server status, logs, processes (read-only)
argument-hint: "<host>"
allowed-tools: Bash, Read
---

# SSH Operations Skill

서버 조회 전용 skill. SSH를 통한 READ-ONLY 인스펙션만 수행.

## Safety Rules

- READ-ONLY 작업만 수행
- 서비스 재시작, 파일 수정, 패키지 설치 금지
- 변경이 필요하면 명령어를 텍스트로 안내

## Arguments

`$ARGUMENTS` = 접속할 호스트

## Common Operations

```bash
ssh $ARGUMENTS "uptime"
ssh $ARGUMENTS "free -h"
ssh $ARGUMENTS "df -h"
ssh $ARGUMENTS "top -bn1 | head -20"
ssh $ARGUMENTS "ps aux --sort=-%mem | head -20"
ssh $ARGUMENTS "journalctl -u <service> --no-pager -n 100"
ssh $ARGUMENTS "tail -n 100 /var/log/<logfile>"
ssh $ARGUMENTS "systemctl status <service>"
ssh $ARGUMENTS "netstat -tlnp 2>/dev/null || ss -tlnp"
```

## Output Format

- 접속 호스트 명시
- 시스템 메트릭 깔끔하게 정리
- 이상 수치 하이라이트 (높은 CPU, 디스크 부족 등)
