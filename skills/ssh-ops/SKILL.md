---
name: ssh-ops
description: SSH server inspection - composes copy-paste read-only command bundles for the operator to run, then interprets the pasted output against thresholds
argument-hint: "<user@host>"
allowed-tools: Bash, Read
---

# SSH Operations Skill

서버 조회 전용. **READ-ONLY만** (`uptime`, `free`, `df`, `du`, `ps`, `top`, `ss`, `systemctl status`, `journalctl`, `tail`, `cat`, `grep`, `find`, `stat`).
금지: `rm`, `mv`, `cp`, `systemctl start/stop/restart`, 패키지 설치, 파일 수정. 변경이 필요하면 텍스트로만 안내.

## 실행 모델 — 명령은 내가, 실행은 사용자가

**서버가 VPN 뒤에 있어 직접 닿지 않는 것을 전제한다.** 시도해서 실패한 뒤 알아차리지 말고 처음부터 그렇게 움직인다.

- 필요한 조회를 **한 번에 묶어** 복붙 가능한 블록 하나로 낸다. 한 줄씩 찔끔 요청하지 않는다
- **반드시 `ssh` 호출을 포함한 형태로** 낸다 — 맨 명령만 내면 사용자가 자기 로컬 머신을 조회하게 된다
- 결과가 **스크린샷으로 돌아오므로 화면에 담기게** 줄인다 — `head -n`, `grep`, `--sort=` 로 필요한 줄만
- **장시간 명령 금지** — `tail -f`, `top`(without `-bn1`), `watch`는 붙여넣으면 세션이 걸린다. batch 종료형만 쓴다
- 돌아온 출력은 **실측**으로 다룬다. 단 어느 호스트에서 나왔는지 불분명하면 그것부터 되묻는다
- 확인 못 한 것은 `(미확인)`으로 남긴다. **추측으로 메우지 않는다.** 그 답에 의존하지 않는 분석을 먼저 끝내고 요청한다
- 예외: 사용자가 "직접 실행해봐"라고 하면 그때만 시도한다

## Arguments

`$ARGUMENTS` = 접속 대상 (`user@host`). 포트가 다르면 `user@host:2222` → `-p 2222`로 변환한다. 인자가 없으면 호스트부터 묻는다.

## SSH 옵션 — 모든 호출에 필수

대화형 prompt·행 걸림·MITM을 막기 위해 아래 4개를 **항상** 포함한다.

| 옵션 | 이유 |
|------|------|
| `BatchMode=yes` | 비밀번호/passphrase prompt 차단 — 키 인증 실패시 즉시 종료 |
| `ConnectTimeout=10` | 응답 없을 때 10초 내 실패 |
| `StrictHostKeyChecking=accept-new` | 첫 접속만 TOFU 등록, 이후 키 변경되면 거부 |
| `ServerAliveInterval=30` | 세션 유지 |

## 1차 진단 묶음

증상이 특정되지 않았을 때 이 한 덩어리를 낸다. 원격에서 한 번에 실행되고 바로 종료된다.

```bash
HOST="<user@host>"        # ← 여기만 채우고 통째로 붙여넣기
ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30 "$HOST" '
  echo "--- load/uptime ---"; uptime; nproc
  echo "--- memory ---";      free -h
  echo "--- disk ---";        df -h | grep -Ev "tmpfs|udev"
  echo "--- top cpu ---";     ps aux --sort=-%cpu | head -8
  echo "--- top mem ---";     ps aux --sort=-%mem | head -8
  echo "--- sockets ---";     ss -s
'
```

## 2차 조회 — 증상별

| 증상 | 명령 |
|------|------|
| 높은 CPU | `top -bn1 \| head -20`, `ps aux --sort=-%cpu \| head -15` |
| 메모리 부족 | `ps aux --sort=-%mem \| head -15`, `dmesg -T \| grep -i oom \| tail -10` |
| 디스크 풀 | `du -sh /var/log/* \| sort -rh \| head -10`, `journalctl --disk-usage` |
| 서비스 장애 | `systemctl status <svc> --no-pager`, `journalctl -u <svc> -n 100 --no-pager`, `systemctl is-enabled <svc>` |
| 네트워크 | `ss -tlnp`, `ss -tn state established \| head -20` |

이 표의 명령은 **위 1차 묶음과 같은 `ssh ... "$HOST" '...'` 래퍼 안에 넣어서** 낸다. 맨 명령만 내보내지 않는다.

## 임계치

| 항목 | Warning | Critical |
|------|---------|----------|
| Load (1min) | > cores | > cores × 2 |
| 메모리 available | < 10% | < 5% |
| 디스크 사용률 | > 85% | > 95% |
| Swap | > 50% | > 80% |

## 연결 실패 처리

- **exit 255** — `known_hosts` 충돌이면 호스트 키 변경 가능성. 재접속 전 반드시 사용자 확인. 키 인증 실패면 `~/.ssh/config`·에이전트·키 배포 상태 확인 안내
- **Permission denied** — 사용자명/포트 재확인 안내. 쓰기 작업으로 우회하지 않는다

## Output

어느 호스트 기준인지 명시. 메트릭 정리 후 임계치 초과 항목 **굵게** 최상단. 미확인은 `(미확인)`. 조치는 텍스트 안내.
