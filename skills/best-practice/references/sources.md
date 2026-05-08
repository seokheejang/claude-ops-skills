# best-practice — Sources Reference

다층 소스 카테고리 상세 + AI 생성 콘텐츠 식별 휴리스틱.

## 소스 카테고리

각 카테고리에서 최소 1개 이상의 소스 확보 목표.

### (A) 공식 문서 & 프로젝트

| 소스 | 예시 |
|------|------|
| 공식 문서 | kubernetes.io/docs, helm.sh/docs, docs.aws.amazon.com/eks |
| CNCF 프로젝트 | CNCF Landscape, 프로젝트 README, 공식 블로그 |
| GitHub 저장소 | README, Issues, Discussions, release notes |

### (B) 엔지니어링 블로그 & 업계 사례

검색 쿼리 예시: `"<topic>" site:engineering.*.com OR "how we" OR "lessons learned"`

| 소스 | 비고 |
|------|------|
| 테크 기업 블로그 | Netflix, Spotify, Airbnb, Uber, Datadog, Grafana Labs, Isovalent, Solo.io |
| 개인 블로그/발표 | Kelsey Hightower, Brendan Burns, Joe Beda, Liz Rice, Ian Coldwater |
| 컨퍼런스 발표 | KubeCon, HashiConf, re:Invent 발표 자료 |

### (C) 커뮤니티 토론 & 실사용 경험

검색 쿼리 예시: `"<topic>" site:reddit.com/r/kubernetes OR site:news.ycombinator.com`

| 소스 | 비고 |
|------|------|
| Reddit | r/kubernetes, r/devops, r/aws, r/docker |
| Hacker News | 관련 토론 스레드 |
| Stack Overflow | 높은 투표 답변 |
| GitHub Discussions/Issues | 실제 사용자 경험, 알려진 한계 |

### (D) 프로젝트 건강도 (도구 비교 시)

| 지표 | 확인 방법 |
|------|-----------|
| GitHub Stars | 프로젝트 인지도 (절대값보다 추세) |
| 최근 커밋/릴리스 | 유지보수 활성도. 6개월+ 무활동은 경고 |
| Open Issues/PRs | 커뮤니티 참여도, 미해결 문제 규모 |
| CNCF 상태 | Sandbox / Incubating / Graduated (해당시) |
| 라이선스 | Apache-2.0, MIT 등 상업적 사용 가능 여부 |
| Adopters | 공식 ADOPTERS.md, 케이스 스터디 |

## AI 생성 콘텐츠 식별 휴리스틱

검색 결과에 **AI 생성 콘텐츠**(SEO 스팸, ChatGPT 작성 블로그)가 점점 증가하는 추세.
이런 글은 **보조 참고로만** 사용하고 1차 출처로 인용하지 않는다.

### 식별 신호 (다음 중 2개 이상 해당 시 의심)

- **작성자 프로필 부재/얕음**: LinkedIn 없음, 다른 글 없음, About 페이지 부재
- **코드 예시 문제**: 동작 안 함, placeholder가 그대로 남음, import 누락
- **표현 패턴**: "as of [date]", "in conclusion", 과도한 bullet point, 거의 동일한 글이 여러 사이트에 존재
- **출처 부재**: 1차 출처 링크 없이 단정적 주장만 나열
- **도메인 + 발행 시점**: 2023년 이후 + medium.com / dev.to / hashnode + 1차 출처 없음

### 의심 사례 처리

```
출처 보고 시 태그 부착:
1. [Title](URL) - 블로그 ⚠️ AI 가능성

권장 액션:
- 가능하면 그 글이 인용한 1차 출처를 찾아서 그것을 인용
- 1차 출처를 찾지 못하면 출처에서 제외
- 핵심 주장은 다른 신뢰 가능한 출처로 교차 검증 후 보고
```

### 신뢰 가능 신호 (반대 지표)

- 작성자가 그 분야 컨퍼런스 발표/오픈소스 기여자
- 글에 실제 운영 환경 수치/장애 경험
- 코드 예시가 실제 GitHub 저장소와 연결됨
- 발행일 + "Last updated" 또는 "Last verified" 명시
- 공식 문서/release notes를 정확히 인용
