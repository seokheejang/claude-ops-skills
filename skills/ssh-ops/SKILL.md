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
- `rm`, `mv`, `cp`, `systemctl start/stop/restart`, `apt/yum install` 등 변경 명령 금지
- 변경이 필요하면 명령어를 텍스트로 안내

## When to Use

- 서버 상태(CPU, 메모리, 디스크)를 점검할 때
- 특정 서비스의 로그를 확인할 때
- 프로세스 상태를 확인할 때
- 서버 장애 원인을 조사할 때
- 네트워크 포트/연결 상태를 확인할 때

## Arguments

`$ARGUMENTS` = 접속할 호스트 (예: `user@host`, `user@10.0.0.1`)

## Step-by-Step Workflow

### Step 1: 기본 상태 확인
```bash
ssh $ARGUMENTS "uptime"
ssh $ARGUMENTS "cat /proc/cpuinfo | grep 'model name' | head -1 && nproc"
```
- uptime, load average 확인
- CPU 코어 수 파악 (load average 판단 기준)

### Step 2: 메모리 상태
```bash
ssh $ARGUMENTS "free -h"
```
- available 메모리가 총 메모리의 10% 미만이면 Warning
- swap 사용량이 높으면 메모리 부족 신호

### Step 3: 디스크 상태
```bash
ssh $ARGUMENTS "df -h"
```
- 사용률 85% 이상 파티션 Warning
- 사용률 95% 이상이면 Critical
- /tmp, /var/log 등 빠르게 차는 파티션 주의

### Step 4: 프로세스 확인
```bash
# CPU 상위 소비 프로세스
ssh $ARGUMENTS "ps aux --sort=-%cpu | head -15"
# 메모리 상위 소비 프로세스
ssh $ARGUMENTS "ps aux --sort=-%mem | head -15"
```

### Step 5: 서비스 및 로그 (필요시)
```bash
ssh $ARGUMENTS "systemctl status <service>"
ssh $ARGUMENTS "journalctl -u <service> --no-pager -n 100"
ssh $ARGUMENTS "tail -n 100 /var/log/<logfile>"
```

### Step 6: 네트워크 상태 (필요시)
```bash
ssh $ARGUMENTS "ss -tlnp"
ssh $ARGUMENTS "ss -s"
```

## Warning 임계값 기준

| 항목 | Warning | Critical |
|------|---------|----------|
| Load Average (1min) | > CPU cores | > CPU cores x 2 |
| 메모리 available | < 10% | < 5% |
| 디스크 사용률 | > 85% | > 95% |
| Swap 사용 | > 50% | > 80% |

## Troubleshooting

### 높은 CPU (Load Average)
1. `ps aux --sort=-%cpu` → CPU 소비 상위 프로세스 확인
2. 특정 프로세스가 비정상적으로 높은지 확인
3. `top -bn1` → 실시간 CPU 사용률 스냅샷

### 메모리 부족
1. `free -h` → available vs total 비교
2. `ps aux --sort=-%mem` → 메모리 소비 상위 프로세스
3. OOM Killer 발동 여부: `dmesg | grep -i "oom\|killed" | tail -10`

### 디스크 풀
1. `df -h` → 어떤 파티션이 찼는지 확인
2. `du -sh /var/log/* | sort -rh | head -10` → 큰 로그 파일 찾기
3. `journalctl --disk-usage` → systemd 저널 크기 확인

### 서비스 장애
1. `systemctl status <service>` → 현재 상태 확인
2. `journalctl -u <service> --since "1 hour ago"` → 최근 로그
3. `systemctl is-enabled <service>` → 자동 시작 설정 확인

## Output Format

- 접속 호스트 명시
- 시스템 메트릭을 깔끔하게 정리
- 임계값 초과 항목은 **굵게** 또는 Warning/Critical 표시
- 이상 수치 하이라이트 (높은 CPU, 디스크 부족 등)
- 조치가 필요하면 명령어를 텍스트로 안내 (직접 실행 금지)
