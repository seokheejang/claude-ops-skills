---
name: best-practice
description: DevOps best practice research - industry patterns, community wisdom, alternative comparison with evidence
argument-hint: "<topic or question>"
allowed-tools: WebSearch, WebFetch, Read, Grep, Glob
---

# Best Practice - DevOps 업계 사례 리서치

DevOps 의사결정을 위한 체계적 리서치 skill.
업계 사례, 커뮤니티 지혜, 공식 문서를 종합하여 근거 기반 비교 분석을 제공한다.

## Safety Rules

- 인프라 변경 절대 금지. 리서치 결과만 제공.
- 검색 쿼리에 내부 정보(클러스터명, IP, 엔드포인트)를 포함하지 않음.
- 출처가 불분명하거나 오래된 정보(2년+)는 명시적으로 표기.

## Arguments

`$ARGUMENTS` = 리서치 주제 또는 질문.

예시:
- `/best-practice EKS에서 CNI 선택 - aws-vpc-cni vs Cilium`
- `/best-practice Helm umbrella chart vs app-of-apps 패턴`
- `/best-practice blockchain RPC 노드 HA 구성 방법`
- `/best-practice K8s PV 백업 전략`
- `/best-practice ArgoCD ApplicationSet 대규모 클러스터 운영 패턴`

인자가 없으면 주제를 요청한다.

## Workflow

### 1단계: 주제 분석 & 검색 전략 수립

`$ARGUMENTS`에서 다음을 파악:

| 항목 | 판별 |
|------|------|
| **도메인** | K8s/EKS, Helm, Terraform, ArgoCD, CNI, Blockchain, 일반 DevOps |
| **질문 유형** | 도구 선택, 아키텍처 패턴, 트러블슈팅, 마이그레이션, 보안 |
| **비교 대상** | 명시된 대안(A vs B)이 있는가, 없으면 대안 탐색 필요 |
| **맥락** | 프로덕션 규모, 클라우드 환경(AWS/EKS), 특수 요구사항 |

주제 분석 결과를 바탕으로 검색 쿼리 3~5개를 설계한다.

### 2단계: 다층 소스 리서치

아래 소스 카테고리를 순서대로 조사한다. 각 카테고리에서 최소 1개 이상의 소스를 확보하는 것을 목표로 한다.

#### (A) 공식 문서 & 프로젝트

| 소스 | 예시 |
|------|------|
| 공식 문서 | kubernetes.io/docs, helm.sh/docs, docs.aws.amazon.com/eks |
| CNCF 프로젝트 | CNCF Landscape, 프로젝트 README, 공식 블로그 |
| GitHub 저장소 | README, Issues, Discussions, release notes |

#### (B) 엔지니어링 블로그 & 업계 사례

검색 쿼리 예시: `"<topic>" site:engineering.*.com OR "how we" OR "lessons learned"`

| 소스 | 비고 |
|------|------|
| 테크 기업 블로그 | Netflix, Spotify, Airbnb, Uber, Datadog, Grafana Labs, Isovalent, Solo.io |
| 개인 블로그/발표 | Kelsey Hightower, Brendan Burns, Joe Beda, Liz Rice, Ian Coldwater |
| 컨퍼런스 발표 | KubeCon, HashiConf, re:Invent 발표 자료 |

#### (C) 커뮤니티 토론 & 실사용 경험

검색 쿼리 예시: `"<topic>" site:reddit.com/r/kubernetes OR site:news.ycombinator.com`

| 소스 | 비고 |
|------|------|
| Reddit | r/kubernetes, r/devops, r/aws, r/docker |
| Hacker News | 관련 토론 스레드 |
| Stack Overflow | 높은 투표 답변 |
| GitHub Discussions/Issues | 실제 사용자 경험, 알려진 한계 |

#### (D) 프로젝트 건강도 (도구 비교 시)

도구/라이브러리 비교가 포함된 경우:

| 지표 | 확인 방법 |
|------|-----------|
| GitHub Stars | 프로젝트 인지도 (절대값보다 추세) |
| 최근 커밋/릴리스 | 유지보수 활성도. 6개월+ 무활동은 경고 |
| Open Issues/PRs | 커뮤니티 참여도, 미해결 문제 규모 |
| CNCF 상태 | Sandbox / Incubating / Graduated (해당시) |
| 라이선스 | Apache-2.0, MIT 등 상업적 사용 가능 여부 |
| Adopters | 공식 ADOPTERS.md, 케이스 스터디 |

### 3단계: 기존 학습 기록 참조

`docs/learnings/` 디렉토리에서 관련 학습 기록이 있는지 확인한다.
이전에 비슷한 주제를 조사한 이력이 있으면 참조하고 업데이트 필요 여부를 판단한다.

### 4단계: 종합 분석

수집한 정보를 바탕으로:

1. **대안 정리** - 각 선택지의 핵심 특징
2. **Pros/Cons 비교** - 근거 기반 장단점 분석
3. **맥락별 적합성** - 사용자 환경(EKS, 블록체인 등)에 맞는 평가
4. **합의 vs 논란** - 업계에서 합의된 부분과 의견이 갈리는 부분 구분

### 5단계: 결과 보고

아래 출력 포맷에 따라 정리한다.

## Output Format

```
=== Best Practice: <주제 요약> ===

## 배경

<주제의 맥락과 왜 이 결정이 중요한지 2-3문장>

## 대안 비교

| 항목 | <Option A> | <Option B> | <Option C (있으면)> |
|------|-----------|-----------|-----------|
| 핵심 특징 | ... | ... | ... |
| 장점 | ... | ... | ... |
| 단점 | ... | ... | ... |
| 적합한 환경 | ... | ... | ... |
| GitHub Stars | ... | ... | ... |
| CNCF 상태 | ... | ... | ... |
| 최근 릴리스 | ... | ... | ... |

## 업계 동향

- <기업/개인>의 사례: ... [출처]
- <기업/개인>의 사례: ... [출처]
- 커뮤니티 의견: ... [출처]

## 사용자 환경 고려

<EKS/블록체인 등 사용자의 특수한 맥락에서의 분석>

## 권장 사항

**상황별 추천:**
- <조건 A>인 경우 → <Option X> 권장. 근거: ...
- <조건 B>인 경우 → <Option Y> 권장. 근거: ...

**주의 사항:**
- ...

## 출처

1. [제목](URL) - 소스 유형 (공식 문서/블로그/커뮤니티/GitHub)
2. [제목](URL) - 소스 유형
3. ...

정보 기준일: YYYY-MM-DD
⚠️ 오래된 정보(1년+)는 날짜 표기
```

## Quality Criteria

- **최소 출처 수**: 3개 이상 (가능하면 5개+)
- **출처 다양성**: 공식 문서 + 커뮤니티 + 블로그/사례 중 최소 2개 카테고리
- **시의성**: 2년 이상 된 정보는 `⚠️ YYYY년 기준` 명시
- **근거 없는 주장 금지**: 모든 주장에 출처 필수
- **불확실성 명시**: 정보가 부족하거나 확인 불가한 부분은 "확인 필요"로 표기
