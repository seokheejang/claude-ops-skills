---
name: best-practice
description: DevOps best practice research - industry patterns, community wisdom, alternative comparison with evidence. Includes Citation verification, AI content detection, source independence checks, domain-aware recency.
argument-hint: "<topic or question>"
allowed-tools: WebSearch, WebFetch, Read, Grep, Glob
---

# Best Practice - DevOps 업계 사례 리서치

DevOps 의사결정을 위한 체계적 리서치 스킬. 업계 사례, 커뮤니티 지혜, 공식 문서를 종합하여 **검증된 근거 기반** 비교 분석을 제공한다.

상세 정책은 [references/](references/) 참조.

## Safety Rules

- 인프라 변경 절대 금지. 리서치 결과만 제공.
- 검색 쿼리에 내부 정보(클러스터명, IP, 엔드포인트) 포함 금지.
- 출처 미명시 또는 검증 실패 시 ⚠️ 태그 명시.

## Arguments

`$ARGUMENTS` = 리서치 주제 또는 질문. 인자 없으면 주제를 요청.

예시:
- `/best-practice EKS에서 CNI 선택 - aws-vpc-cni vs Cilium`
- `/best-practice Helm umbrella chart vs app-of-apps 패턴`
- `/best-practice ArgoCD ApplicationSet 대규모 클러스터 운영 패턴`

## Reference Guide

| Topic | File | Load When |
|-------|------|-----------|
| 소스 카테고리 + AI 콘텐츠 식별 | [references/sources.md](references/sources.md) | 2단계 다층 소스 리서치 |
| Citation 검증 + 출처 독립성 + 도메인 시의성 | [references/verification.md](references/verification.md) | 4단계 종합 분석, 5단계 보고 전 |
| Output Format + 학습 저장 권유 + Quality Criteria | [references/output.md](references/output.md) | 5단계 결과 보고 |

## Workflow

### 1단계: 주제 분석 & 검색 전략

`$ARGUMENTS`에서 다음을 파악하여 검색 쿼리 3~5개를 설계한다.

| 항목 | 판별 |
|------|------|
| 도메인 | K8s/EKS, Helm, Terraform, ArgoCD, CNI, Blockchain, 일반 DevOps |
| 질문 유형 | 도구 선택, 아키텍처 패턴, 트러블슈팅, 마이그레이션, 보안 |
| 비교 대상 | 명시된 대안(A vs B), 없으면 대안 탐색 필요 |
| 맥락 | 프로덕션 규모, 클라우드 환경, 특수 요구사항 |

도메인은 시의성 기준에도 사용된다 (verification.md).

### 2단계: 학습 기록 우선 검색

작업 중인 프로젝트(현재 working directory)의 `docs/learnings/`를 먼저 확인한다.
> claude-ops-skills 저장소가 아닌, /best-practice를 호출하는 **사용자 프로젝트**의 학습.

검색 전략:
- 주제 도메인 → 파일명 매핑: helm 주제 → `helm.md`, K8s → `k8s.md`, ArgoCD → `argocd.md`
- 매칭 파일에서 키워드 grep
- 학습 발견 시 출처 목록에 포함 (예: `[docs/learnings/helm.md, 2025-09-15] - 사내 학습`)
- 학습이 충분히 최신이면 외부 검색 보완 정도만, 오래됐으면 정상 검색

### 3단계: 다층 소스 리서치 (외부)

[references/sources.md](references/sources.md)의 4개 카테고리(A/B/C/D)에서 최소 1개씩 확보.
검색 결과 평가 시 AI 생성 콘텐츠 식별 휴리스틱 적용 — 의심 신호 2개+ 시 ⚠️ 태그 또는 1차 출처로 대체.

### 4단계: 종합 분석 + 검증

수집한 정보를 분석하기 전 [references/verification.md](references/verification.md) 절차 수행:

1. **Citation 검증**: 모든 출처 URL을 WebFetch로 200 OK 확인 + 인용 내용 실제 존재 확인
2. **출처 독립성**: 1차 출처까지 추적, 같은 1차 소스 인용은 1개로 카운트
3. **도메인 시의성**: 도메인별 임계값 적용 (K8s 1년, Helm 2년, SRE 5년+ 등)

검증 후 분석:
1. 대안 정리 (각 선택지의 핵심 특징)
2. Pros/Cons 비교 (근거 기반)
3. 맥락별 적합성 (사용자 환경)
4. 합의 vs 논란 (업계 합의된 부분과 의견 갈리는 부분 구분)

### 5단계: 결과 보고 + 학습 저장 권유

[references/output.md](references/output.md) 포맷으로 정리 후 출력.

리서치가 의미 있는 결과(명확한 결론, 비자명한 인사이트, 재참조 가치)일 때만 끝에 학습 저장 권유 메시지 추가. 단순 정보 조회나 결론 모호 시 권유 생략.
