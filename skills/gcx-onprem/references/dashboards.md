# 대시보드 작업 — 명령·형식·권한

모두 사내 on-prem Grafana 12.2.1 에서 직접 호출해 확인했다.

## 먼저 권한을 확인한다

**조회가 된다고 변경 권한이 있는 것이 아니다.** 조회는 전부 되는데 `update` 가 `403 Forbidden ... can not edit dashboard` 로 거부되는 상태가 있었다. 인증이 아니라 인가 문제다. 권한은 **폴더 단위로 갈린다.**

변경 작업을 시작하기 전에 대상 폴더에 쓰기가 되는지부터 확인한다. 순서를 지키지 않으면 매니페스트를 다 만들고 마지막에 막힌다.

## 스냅샷은 시각 확인 근거가 아니다

이미지 렌더러가 없어서 `dashboards snapshot` 이 **종료 코드 0 으로 성공한 것처럼 끝나고 PNG 파일까지 생성되지만**, 내용은 "No image renderer available/installed" 오류 화면이다. 크기가 약 9KB 로 작은 것이 유일한 단서다.

- 스냅샷 결과를 보고 "대시보드가 잘 나왔다"고 보고하면 거짓 보고가 된다
- 매니페스트를 올리고, 시각 확인은 사용자가 브라우저로 한다. 건너뛰었다고 밝힌다

## 생성과 수정은 명령이 다르다

| 작업 | 명령 | 필수 |
|---|---|---|
| 신규 | `gcx dashboards create -f <manifest>` | 폴더는 `metadata.annotations["grafana.app/folder"]` |
| 수정 | `gcx dashboards update <name> -f <manifest>` | `metadata.resourceVersion` |

- 변경 명령은 `push` 가 아니라 `update` 다
- `update` 에는 `metadata.resourceVersion` 이 반드시 있어야 한다(낙관적 동시성 제어). `gcx dashboards get <name> -o json` 결과에서 그대로 가져온다. `create` 에는 필요 없다
- **폴더를 `spec.folderUID` 로 지정하면 무시되고 General 로 간다.** `metadata.annotations` 쪽을 쓴다
- `folders` 서브커맨드는 존재하지 않으므로 폴더 목록은 gcx 로 확인할 수 없다

**실행은 하지 않고 명령어만 안내한다** — `create`·`update`·`delete`·`restore`·`push`. Grafana 설정을 덮어쓰면 팀이 깨진 화면을 본다.

## Loki `query` 타입 변수의 형식

```json
{"label": "<라벨명>", "refId": "LokiVariableQueryEditor-VariableQuery", "stream": "{<셀렉터>}", "type": 1}
```

사내 선례 3종이 모두 이 형태다. `stream` 안에서 상위 변수를 참조해 체이닝할 수 있다.

**이 변수는 대시보드 시간 범위 안에 로그가 있는 값만 반환한다.** 그래서 드롭다운에 값이 안 보이는 것은 대시보드 결함이 아니라 그 대상의 로그가 끊겼다는 신호일 수 있다 — `logs.md` 의 "로그가 안 나올 때의 판단" 을 본다.

데이터소스마다 `k8s_cluster` 값 체계가 다르므로 **클러스터 선택 변수를 두 데이터소스에 공유하면 한쪽이 반드시 빈 결과가 된다.** 데이터소스별로 분리하거나 `custom` 타입으로 양쪽 값을 담는다.
