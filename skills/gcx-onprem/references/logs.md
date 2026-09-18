# Loki 로그 질의 — 라벨 함정과 판단

모두 사내 on-prem Grafana(Loki) 에서 직접 질의해 확인했다. 실제 라벨 값은 `chains.md`(로컬 전용)에 있다.

## 도구 선택 — 추이인가 로그 줄인가

`logs query` 는 기본 50줄만 반환한다. 그것을 세어서 "추이"라고 답하면 표본만 센 것이다.

- **추이·건수·발생 구간** → `logs metrics`
- **로그 내용** → `logs query`

반환된 로그 중 가장 오래된 줄은 **그 표본에서 가장 오래된 것일 뿐 최초 발생 시점이 아니다.** "언제부터 시작됐나"는 집계로 구간을 좁힌 뒤 그 구간의 로그를 본다.

## 라벨

컨테이너 로그의 스트림 라벨은 `k8s_cluster`·`namespace`·`pod_name`·`container_name`·`service_name`·`host_name`·`level`·`log_type`·`stream` 이다.

- **`pod` 를 쓰지 않는다.** `pod` 라벨은 `loki-canary-*` 전용이고 실제 파드는 `pod_name` 에 있다. 변수나 질의에서 `pod` 를 쓰면 거의 항상 빈 결과가 나온다
- **데이터소스마다 `k8s_cluster` 값 체계가 다르다.** 같은 클러스터를 Loki 와 Mimir 가 서로 다른 문자열로 부른다. 두 데이터소스를 하나의 대시보드 변수로 묶으면 한쪽이 반드시 빈 결과가 되므로, 클러스터 선택 변수는 데이터소스별로 분리하거나 `custom` 타입으로 양쪽 값을 담는다
- `No data` 는 오류 없이 돌아온다. 짐작한 축약형과 실제 값이 대소문자나 접두사에서 어긋난 것을 먼저 의심하고 `gcx logs labels -d <uid> -l <label>` 로 확인한다

## 에러 검색 — `level` 라벨을 신뢰하지 않는다

본문에 ANSI 색상 코드와 함께 `INF`·`ERR`·`WRN` 을 넣는 로거(Cosmos SDK 계열이 그렇다)는 Loki 가 인식하지 못하고 **전부 `INFO` 로 분류한다.** 그래서 `level="ERROR"` 로 질의하면 에러가 수천 건 있는데도 "에러 없음"이라는 잘못된 결론이 나온다. 한 클러스터를 15분 기준으로 재어 보니 **level 라벨로 잡히는 네임스페이스가 본문 정규식으로 잡히는 것의 3분의 1**이었다.

에러는 본문 정규식으로 찾고, 형태는 `ERR|FATAL|PANIC` 과 `WRN|WARN` 으로 고정한다. 세 가지가 모두 필요하다.

1. **대소문자를 구분한다** — 소문자 `err=` 는 에러가 아니라 필드명이라 오탐이 된다
2. **단어경계 `\b` 를 쓰지 않는다** — `\x1b[31mERR\x1b[0m` 는 앞의 `m` 때문에 경계가 생기지 않아 매칭이 0건이 된다
3. **단순 문자열 대안으로 둔다** — Loki 의 빠른 부분문자열 경로를 탄다. 같은 범위에서 `ERR|FATAL|PANIC` 은 **1.6초**, `(?i)\b(...)\b` 조합은 **17.8초** 였다

`ERROR` 는 `ERR` 에 포함되고 `WARNING` 은 `WARN` 에 포함되므로 저 두 개면 충분하다. 교차 검증: level 라벨이 제대로 붙는 워크로드에서는 라벨 집계와 정규식 집계가 같은 값(1건 == 1건)이었다.

## 본문 파싱 — 봉투를 벗긴다

- **logfmt 봉투** — 노드 컨테이너 로그는 클라이언트 종류와 무관하게 `message="..." ts=... service=...` 형태로 감싸져 있다(노드 클라이언트 여러 종에서 동일 확인). `| logfmt | line_format "{{.message}}"` 로 벗기고, 파싱 실패에 대비해 `{{if .message}}{{.message}}{{else}}{{__line__}}{{end}}` 형태로 쓴다
- **이중 JSON 봉투** — CloudNativePG 의 PostgreSQL 로그는 Loki line 이 `{"message":"<CNPG JSON 문자열>"}` 이고 그 안의 `.record` 에 `log_time`·`error_severity`·`message`·`query`·`sql_state_code` 가 있다. `jq -r '.line' | jq -r '.message' | jq '.record'` 로 두 번 벗겨야 실제 SQL 과 에러가 보인다. 한 번만 벗기면 `session_line_num` 근처에서 잘려 정작 필요한 필드를 못 본다

## 컨테이너 밖의 로그 — `log_type`

Loki 는 컨테이너 로그만 모으는 것이 아니다. `log_type` 에 `container`·`journal`·`k8s_event`·`kube-audit` 네 종류가 있다.

- **`{log_type="k8s_event"}`** — OOMKilled·CrashLoopBackOff·이미지 풀 실패 같은 파드 시스템 오류를 여기서 본다. **K8s 클러스터에 접근하지 못해도 이벤트는 Loki 로 확인된다**
- **`{log_type="journal"}`** — kubelet 로그
- `k8s_event` 본문은 logfmt 이고 `kind=`·`reason=`·`type=`·`message=`·`count=`·`firstTimestamp=`·`lastTimestamp=` 를 담는다. 대상 오브젝트는 `object_name` 라벨에 있다. `| logfmt` 로 파싱해 `sum by (reason, type)` 집계가 된다. 다만 `DNSConfigForming` 경고가 압도적으로 많아 제외하지 않으면 다른 이벤트가 묻힌다

## 시간 범위

- **`logs query` 의 기본 범위는 짧다.** 로그가 드문 대상(예: 5분 간격 출력)은 기본값으로 0건이 나온다. `--since` 를 반드시 명시하고, 잡은 범위를 사용자에게 밝힌다. 범위를 안 밝히면 "로그가 없다"는 잘못된 결론이 된다
- **`logs labels` 에는 시간 범위 플래그가 없다.** 기본 범위로만 조회되므로 최근에 로그가 끊긴 라벨 값은 목록에서 통째로 빠지고, 이것을 "그런 값은 원래 없다"로 오해하기 쉽다. 과거에 존재했는지는 범위를 명시한 집계로 확인한다 — `gcx logs metrics 'sum by (k8s_cluster, log_type) (count_over_time({namespace="<대상>"}[1h]))' --from now-7d --to now`
- **`--to <시점> --since <기간>` 조합이 과거 임의 구간의 instant query 가 된다.** 발생 시작 시점을 이분 탐색으로 좁힐 때 쓴다. 데이터가 없으면 `{"resultType":"vector","result":[]}` 가 오므로 jq 에서 `length==0` 을 따로 처리하지 않으면 전 구간이 0 으로 보인다
- **로그량이 많은 대상에 6h 집계를 걸면 게이트웨이가 끊는다**(`net/http: timeout awaiting response headers`). 15분~1시간으로 잡는다

## 로그가 안 나올 때의 판단

- **대시보드 변수 드롭다운에서 값이 사라진 것은 대시보드 결함이 아니다.** Loki `query` 타입 변수는 대시보드 시간 범위 안에 로그가 있는 라벨 값만 반환하므로, **그 대상의 로그가 끊겼다는 신호**로 먼저 의심한다. 범위를 `now-24h` 로 넓히면 값이 다시 나타난다
- **로그 공백을 노드 장애와 동일시하지 않는다.** 노드가 살아 있는데(`up{namespace="<대상>"}` 이 1) 컨테이너 로그만 끊긴 상태가 실제로 발생한다. 로그 수집 경로와 노드 프로세스를 분리해 확인하고, 같은 네임스페이스의 `log_type="k8s_event"` 가 계속 수집되고 있다면 클러스터 단위 파이프라인은 살아 있다는 뜻이므로 범위가 그 파드로 좁혀진다

## 출력 파싱

`gcx logs metrics` 는 시간 플래그를 주지 않아도 `resultType: matrix` 로 돌아온다. `--jq '.data.result[].value[1]'` 은 실패하므로 `values` 배열을 다뤄야 한다. 또한 `--jq` 출력은 배열 여는 대괄호가 hint 줄과 함께 잘려서 `json.load` 가 깨진다 — **파싱이 필요하면 `-o json` 을 쓴다.**

## 메트릭 쪽 함정 하나

`gcx metrics list-names` 결과는 전체 목록이 아니다. 한 데이터소스에서 107개만 반환되어 특정 접두사군이 하나도 안 나왔지만 실제로는 존재했다. 메트릭을 찾을 때는 `gcx metrics query -d <uid> 'count by (__name__) ({namespace="<ns>"})'` 로 확인한다. **list-names 만 믿고 "메트릭이 없다"고 판단하면 틀린다.**

게이지가 0 으로 보이는 것은 측정 실패가 아니라 해상도 미만(밀리초 단위 응답시간이 1ms 미만)일 수 있다. `max_over_time(...[6h])` 로 확인한 뒤 판단한다.
