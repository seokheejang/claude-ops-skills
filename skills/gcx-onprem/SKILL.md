---
name: gcx-onprem
description: 사내 on-prem Grafana 를 gcx 로 다룰 때만 성립하는 제약과 조회 판단 규칙. gcx 명령 문법이 아니라 "이 인스턴스에서 무엇이 안 되는지"와 "어떻게 판단할지"를 담는다. Use when gcx로 Grafana를 조회할 때, 로그·메트릭·알림·대시보드 요청을 받았을 때, 사용자가 "로그 봐줘", "알림 왜 떠", "대시보드 만들어줘", "ERROR 추이" 라고 할 때.
allowed-tools: Bash, Read, Grep, Glob
---

# gcx on-prem 제약과 판단 규칙

사내 Grafana 는 on-prem 이라 Grafana Cloud 기능이 다수 빠져 있다. 이 문서는 **그 차이와 전반 규칙**만 담고, 영역별 세부는 참조 파일로 나눠 뒀다.

**담지 않는 것** — gcx 명령 문법과 플래그. 번들 스킬 `gcx`, `debug-with-grafana`, `investigate-alert`, `manage-dashboards` 가 이미 가지고 있다. **표준 gcx 사용법은 이미 아는 걸 쓴다.** gcx 설치·버전 관리·인증 설정도 범위 밖이다.

## 참조 파일 — 작업을 시작하기 전에 해당 파일을 읽는다

| 파일 | 언제 |
|---|---|
| `references/logs.md` | 로그를 질의할 때. 라벨 함정·에러 검색 정규식·시간 범위·로그 공백 판단 |
| `references/dashboards.md` | 대시보드를 만들거나 고칠 때. 권한 확인·create/update 차이·변수 형식 |
| `references/chains.md` | 특정 체인을 조회할 때. 실제 라벨 값·지표 체계·토폴로지 (로컬 전용, 공개되지 않음) |

`chains.md` 는 gitignore 대상이라 새로 클론하면 없다. 없을 때는 **그 내용을 추측으로 메우지 않고 조회로 확인한 뒤 새로 적는다.**

## 어떤 스킬로 갈지 — 찔러 보지 말고 이 표로 판단한다

| 스킬 | 이 환경에서 | 판단 |
|---|---|---|
| `gcx` | 가능 | 전반 조회의 기본 진입점 |
| `investigate-alert` | 가능 | 알림 원인 분석. 라벨에 노드 정보가 실려 있어 바로 좁혀진다 |
| `manage-dashboards` | 부분 | `list`·`search`·`get`·`list-versions` 는 되고 `snapshot` 만 불가 |
| `create-dashboard` | 부분 | 스냅샷 피드백 루프를 쓸 수 없다. `references/dashboards.md` 참조 |
| `debug-with-grafana` | 부분 | 메트릭·로그만. 트레이스 절차는 건너뛴다 |
| `setup-gcx` | 가능 | 인증은 사용자가 직접 한다. 실패하면 안내만 |
| 미설치 18개 | 불가 | 대부분 Grafana Cloud 전용. `gcx agent skills list` 로 확인 |

미설치 스킬을 설치할 때는 `--dir` 을 반드시 명시한다. 기본값 `~/.agents` 는 Claude Code 가 읽지 않는다.

```bash
gcx agent skills install <name> --dir ~/.claude
```

## 쓸 수 없는 기능

2026-09-15 에 사내 on-prem Grafana 12.2.1 에서 직접 호출해 확인했다. 대상 컨텍스트는 `gcx config current-context` 로 확인한다.

- **이미지 렌더러 없음** — `dashboards snapshot` 이 종료 코드 0 으로 성공한 것처럼 끝나지만 내용은 오류 화면이다. **스냅샷을 시각 확인 근거로 삼으면 거짓 보고가 된다.** 세부는 `references/dashboards.md`
- **OnCall 플러그인 없음** — `gcx irm oncall ...` 이 `HTTP 404: Plugin not found` 로 실패한다. `oncall-triage` 는 무의미하다. 발생 중인 알림은 `gcx alert instances list --state firing` 으로 본다
- **Tempo·Pyroscope 없음** — 트레이스·프로파일을 쓸 수 없다. `gcx traces diff` 는 Grafana Cloud 전용이라 데이터소스를 추가해도 막힌다. 관측 신호는 메트릭과 로그 둘로 진행한다

## 전반 판단 규칙

### 조회는 직접 실행하고, 변경은 명령어만 안내한다

저장소 `CLAUDE.md:33`("인프라 스킬은 복붙 가능한 READ-ONLY 명령 묶음 출력이 기본")를 이 스킬만 벗어난다. 그 규칙이 존재하는 이유는 K8s·SSH·DB 가 **접근 자체가 불가능한 대상**이기 때문인데, gcx 는 접근이 가능하므로 근거가 성립하지 않는다.

- **직접 실행** — `logs query`·`logs metrics`·`metrics query`·`alert *`·`dashboards list|search|get|list-versions`·`datasources list`·`config check`
- **실행하지 않고 명령어만 안내** — `push`·`create`·`update`·`delete`·`restore`

### `No data` 가 나오면 라벨 값부터 의심한다

오류 없이 빈 결과만 돌아오므로 알아채기 어렵다. 짐작한 축약형과 실제 값이 대소문자나 접두사에서 어긋난 경우가 많다. `gcx logs labels -d <uid> -l <label>` 로 실제 값을 확인한다. **데이터소스마다 값 체계가 다르다** — `references/logs.md`

### 범위가 크면 실행 전에 확인받는다

기간이나 대상이 불명확하면 최근 15분~1시간으로 잡고 진행하되 **잡은 범위를 밝힌다.** 넓은 범위가 필요하면 먼저 말하고 승인받는다.

### 출처를 남기고, 낡을 값은 기록하지 않는다

어느 데이터소스(UID)에서 언제 받은 값인지 같이 적는다. 반대로 **데이터소스 UID·대시보드 목록·알림 규칙 이름은 문서에 박지 않고 매번 조회한다.** 박아두면 바뀌었을 때 틀린 값을 쓰게 된다.

### 인증 실패는 안내만 한다

`gcx config check` 결과를 보여주고 사용자가 직접 로그인하도록 안내한다. 참고로 `config check` 는 쓰지 않는 컨텍스트가 설정에 남아 있으면 그것 때문에 종료 코드 1 로 끝난다. 활성 컨텍스트 블록만 확인하면 된다.

## 새로 발견한 것을 기록하는 방법

**이 저장소는 공개(public)다.** pre-commit 훅의 인프라명 검사는 `skills/k8s-ops/clusters.yaml` 이 있을 때만 동작하므로 **훅을 믿지 말고 직접 판단한다.**

**공개 파일에 절대 넣지 않는 것** — 클러스터명·네임스페이스명·호스트명·IP·데이터소스 UID·라벨 실제 값·팀명·대시보드명, 그리고 **체인명·체인 개수·체인별 로그량**. 체인 정보는 사내 운영 대상을 그대로 드러낸다. 도구 동작을 설명하는 예시로 필요하더라도 `<체인>`·`<접두사>_*` 로 바꾼다. 오픈소스 프레임워크·클라이언트 이름(Cosmos SDK, CloudNativePG 등)은 사내 식별자가 아니므로 써도 된다.

기록은 세 단계다.

1. **발견 즉시 `pending.md` 에 적는다** (gitignore 됨). 적기 전에 **`references/*.md` 와 `pending.md` 에 같은 케이스가 있는지 먼저 본다** — 있으면 새 발견이 아니다. 기존 기록이 더 부정확하면 새 줄을 추가하지 말고 그 항목을 고친다. 발견한 그 자리에서 적고, **어느 명령으로 언제 확인했는지**를 같이 남긴다. 추측은 적지 않고 확인 못 한 것은 `(미확인)` 으로 둔다. 적었다고 한 줄 보고한다
2. **사용자 검토 후 옮긴다.** 도구 동작이면 해당 `references/*.md`, 사내 실제 값이면 `references/chains.md`, 전반 규칙이면 이 파일이다. **이 파일은 최소한으로 유지한다** — 세부 절차가 늘어나면 참조 파일로 보낸다
3. **옮긴 항목은 `pending.md` 에서 지운다.** 남겨 둬도 재발견을 막아 주지 못한다(pending.md 를 읽는 경로가 없다). 대신 옮길 때 **실측 날짜와 확인 명령을 목적지 파일에 같이 적어** 출처가 끊기지 않게 한다. `pending.md` 는 아직 검토받지 않은 것만 담는다

커밋은 하지 않는다. 커밋 메시지만 제안한다.
