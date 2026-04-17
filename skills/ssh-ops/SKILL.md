---
name: ssh-ops
description: SSH server inspection - check server status, logs, processes (read-only)
argument-hint: "<host>"
allowed-tools: Bash, Read
---

# SSH Operations Skill

서버 조회 전용 skill. SSH를 통한 READ-ONLY 인스펙션만 수행.

## Safety: READ-ONLY

허용: uptime, free, df, du, ps, top, ss, systemctl status, journalctl, tail, cat, grep, find, stat.
금지: rm, mv, cp, systemctl start/stop/restart, apt/yum install, 파일 수정.
변경 필요시 명령어를 텍스트로 안내.

## SSH 연결 정책

모든 SSH 호출은 아래 옵션을 **반드시** 포함. 대화형 prompt·행 걸림·MITM 위험 차단.

| 옵션 | 값 | 이유 |
|------|-----|------|
| `BatchMode` | `yes` | 비밀번호/passphrase prompt 차단. 키 인증 실패시 즉시 종료 (자동화 중 행 걸림 방지) |
| `ConnectTimeout` | `10` | 네트워크 응답 없을 때 10초 내 실패 |
| `StrictHostKeyChecking` | `accept-new` | 첫 접속 시 자동 `known_hosts` 추가(TOFU), 이후 호스트 키 변경되면 거부 |
| `ServerAliveInterval` | `30` | 세션 중 연결 유지 |

**표준 호출 패턴**:
```
ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30 $ARGUMENTS "<command>"
```

**처리 분기**:
- 연결 실패 (exit 255): `known_hosts` 충돌이면 키 변경 가능성 — 재접속 전 사용자 확인 요청. 키 인증 실패면 `~/.ssh/config`, 에이전트, 키 배포 상태 확인 안내
- Permission denied: 사용자명/포트 재확인 안내, 쓰기 작업 금지
- 장시간 명령 (`tail -f`, `top` without `-bn1`): 금지 — batch 종료형 플래그 사용 (`journalctl -n 100`, `top -bn1`)

## Arguments

`$ARGUMENTS` = 접속 호스트 (예: `user@host`, `user@10.0.0.1`, `user@host:2222` — 포트는 `-p 2222`로 변환).

## Workflow

모든 명령은 위 **SSH 연결 정책**의 표준 호출 패턴 사용. 이하 표의 `<command>` 부분만 치환.

| 단계 | 명령어 | 확인 사항 |
|------|--------|-----------|
| 기본 상태 | `uptime`, `nproc` | load average (vs CPU cores), uptime |
| 메모리 | `free -h` | available<10% Warning, swap 높으면 부족 신호 |
| 디스크 | `df -h` | 85%+ Warning, 95%+ Critical, /tmp /var/log 주의 |
| 프로세스 | `ps aux --sort=-%cpu \| head -15`, `--sort=-%mem \| head -15` | CPU/메모리 상위 소비 |
| 서비스/로그 | `systemctl status <svc>`, `journalctl -u <svc> -n 100`, `tail -n 100 /var/log/<file>` | 필요시 |
| 네트워크 | `ss -tlnp`, `ss -s` | 필요시, 리스닝 포트 확인 |

## 임계치

| 항목 | Warning | Critical |
|------|---------|----------|
| Load (1min) | > cores | > cores x 2 |
| 메모리 available | < 10% | < 5% |
| 디스크 사용률 | > 85% | > 95% |
| Swap | > 50% | > 80% |

## Troubleshooting

- **높은 CPU**: `ps --sort=-%cpu`, `top -bn1`. 특정 프로세스 비정상 여부
- **메모리 부족**: `free -h`, `ps --sort=-%mem`, `dmesg | grep -i oom | tail -10`
- **디스크 풀**: `du -sh /var/log/* | sort -rh | head -10`, `journalctl --disk-usage`
- **서비스 장애**: `systemctl status`, `journalctl --since "1 hour ago"`, `is-enabled`

## Output

접속 호스트 명시. 메트릭 정리. 임계치 초과 **굵게**. 조치는 텍스트 안내.
