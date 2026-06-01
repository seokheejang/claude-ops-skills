---
name: troubleshoot
description: Evidence-based troubleshooting discipline for infra/service failures (k8s, SSH). Forbids conclusions without observed command output - judgments must cite evidence, fixes are cross-checked from multiple angles, side effects enumerated, and remediation stays operator-confirmed manual guidance, never auto-executed. Use when the user wants to diagnose a failure, find root cause with evidence, stress-test a hypothesis, says "트러블슈팅", "장애 분석", "원인 분석", "troubleshoot", or pastes logs/errors to diagnose.
argument-hint: "<현상/증상 설명>"
allowed-tools: Read, Grep, Glob
---

# Troubleshoot — 근거 기반 장애 진단 규율

인프라/서비스 장애를 **추측 없이** 진단하는 방법론 스킬. 직접 명령을 실행하지 않는다 — 조회는 [k8s-ops](../k8s-ops/), [ssh-ops](../ssh-ops/) 등 READ-ONLY 스킬로 위임하고, 이 스킬은 **수집된 증거에 대한 추론 규율**을 강제한다. (`allowed-tools`에 Bash 없음 = 어떤 명령도 직접 실행 불가)

## 절대 규칙 (위반 금지)

1. **근거 없는 단정 금지.** 모든 판단은 실제로 관찰된 명령 출력에 근거한다. 출력을 본 적 없으면 "확정"이라 말하지 않는다.
2. **관찰 / 가설 / 결론을 구분**해서 표기한다. 추론은 "가설"로 명시하고 검증 방법을 함께 제시한다.
3. **증거가 부족하면 멈춘다.** 부족한 항목과 "이걸 확인하려면 무엇을 조회해야 하는지"를 보고하고, 빈칸을 추측으로 채우지 않는다.
4. **조치를 직접 실행하지 않는다.** 변경/복구 명령은 실행 가능한 형태로 적되 가이드(텍스트)로만 제공한다.
5. **후속 조치는 작업자가 수동으로, 컨펌 후 진행.** 롤백 절차를 반드시 동봉한다.

## Evidence Ledger (보고 형식)

발견 사항은 한 줄씩 원장으로 적는다. 근거 칸이 비면 그 행은 자동으로 "가설"이다.

| 증상 | 근거 (명령 + 출력 발췌) | 판단 | 확신도 |
|------|------------------------|------|--------|
| Pod 반복 재시작 | `logs --previous` → `exit 137`, `describe` → `OOMKilled` | 메모리 limit 초과 | 확정 |
| 응답 지연 | (미수집) | DB 커넥션 고갈 의심 | 가설 |

**확신도 정의**
- **확정** — 직접 관찰된 출력으로 인과가 명확
- **유력** — 정황 증거는 있으나 직접 확인 안 됨 → 추가 검증 항목을 함께 명시
- **가설** — 근거 미확보 → 검증 방법만 제시 (단정 금지)

## Workflow

1. **현상 수집** — 증상을 정리하고, 필요한 데이터는 k8s-ops/ssh-ops로 수집(위임)하도록 요청한다. 요약·가공 전에 **원본 출력**을 확보한다.
2. **증거 원장 작성** — 발견마다 근거(명령+출력)를 붙인다. 근거 없는 행은 "가설"로 강등한다.
3. **다각도 검증** — 결론 전에 *반증*을 시도한다. 대안 원인을 최소 1~2개 세우고 증거로 배제한다. 단일 증거로 단정하지 않는다.
4. **사이드 이펙트 전수 조사** — 제안 조치가 건드리는 모든 대상(연결 워크로드, 의존 서비스, 데이터, 트래픽, 재시작·재스케줄 영향)을 나열한다. 모르면 "영향 불명 — 확인 필요"로 표기한다.
5. **수동 조치 가이드** — 각 조치에 (a) 전제 확인 (b) 명령 (c) 예상 사이드 이펙트 (d) 롤백 절차를 붙인다. 직접 실행하지 않고, 작업자 컨펌 후 수동 진행.

## Output

장애 요약 → Evidence Ledger → 근본 원인(확신도 명시) → 배제한 대안 → 사이드 이펙트 → 수동 조치 가이드(롤백 포함). 증거가 부족한 영역은 숨기지 말고 "근거 부족"으로 드러낸다.
