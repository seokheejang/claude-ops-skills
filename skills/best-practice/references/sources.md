# best-practice — Sources Reference

소스 카테고리와 AI 생성 콘텐츠 식별 휴리스틱.

## 소스 카테고리

각 카테고리에서 **최소 1개 이상** 확보하는 것이 목표다. 구체적인 사이트·인물 목록은 적지 않는다 — 낡아서 오히려 검색 범위를 좁힌다.

| 구분 | 무엇을 찾나 | 검색 쿼리 패턴 |
|------|------------|---------------|
| **(A) 공식** | 프로젝트 공식 문서, CNCF Landscape, GitHub README·Issues·release notes | `"<topic>" site:<공식도메인>` |
| **(B) 업계 사례** | 테크 기업 엔지니어링 블로그, 컨퍼런스 발표, 해당 분야 실무자 글 | `"<topic>" site:engineering.*.com OR "how we" OR "lessons learned"` |
| **(C) 커뮤니티** | Reddit, Hacker News, Stack Overflow, GitHub Discussions — 실사용 경험과 알려진 한계 | `"<topic>" site:reddit.com OR site:news.ycombinator.com` |
| **(D) 프로젝트 건강도** | 도구를 비교할 때만 | 아래 표 |

### (D) 프로젝트 건강도 지표

| 지표 | 확인 방법 |
|------|-----------|
| 최근 커밋/릴리스 | 유지보수 활성도. **6개월+ 무활동은 경고** |
| Open Issues/PRs | 커뮤니티 참여도, 미해결 문제 규모 |
| GitHub Stars | 절대값이 아니라 **추세**로 본다 |
| CNCF 상태 | Sandbox / Incubating / Graduated |
| 라이선스 | 상업적 사용 가능 여부 |
| Adopters | 공식 ADOPTERS.md, 케이스 스터디 |

## AI 생성 콘텐츠 식별 휴리스틱

검색 결과에 AI 생성 콘텐츠(SEO 스팸, LLM 작성 블로그)가 섞여 들어온다. 이런 글은 **보조 참고로만** 쓰고 1차 출처로 인용하지 않는다.

### 의심 신호 (2개 이상 해당 시)

- **작성자 프로필 부재/얕음** — 다른 글 없음, About 페이지 없음
- **코드 예시가 동작하지 않음** — placeholder 잔존, import 누락
- **표현 패턴** — 과도한 bullet, "in conclusion", 거의 동일한 글이 여러 사이트에 존재
- **출처 부재** — 1차 출처 링크 없이 단정적 주장만 나열
- **저품질 퍼블리싱 플랫폼 + 출처 없음** — 누구나 쓸 수 있는 블로그 플랫폼에 올라온 글이 1차 출처를 달지 않은 경우

### 반대 지표 (신뢰 가능 신호)

- 글에 **실제 운영 환경 수치나 장애 경험**이 있다
- 코드 예시가 실제 GitHub 저장소와 연결된다
- 공식 문서나 release notes를 정확히 인용한다
- "Last updated" / "Last verified" 날짜가 명시돼 있다

### 처리

1. 그 글이 인용한 **1차 출처를 찾아 그것을 인용**한다
2. 1차 출처를 못 찾으면 **출처에서 제외**한다
3. 핵심 주장은 다른 출처로 교차 검증한 뒤 보고한다
4. 그래도 남겨야 하면 `⚠️ AI 가능성` 태그를 붙인다
