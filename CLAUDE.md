# 꽃판 (Card Bloom)

화투 기반 2D 럭빌더 로그라이크. Godot 4.x + GDScript.

## 게임 설계 문서 (Notion)
- 메인: https://www.notion.so/3397060afba8815e92a7e033414cdb22
- GDD Part 1: https://www.notion.so/3397060afba8812aa9d8dabb75eef1ef
- GDD Part 2: https://www.notion.so/3397060afba88105b907fb67233d7c4d
- 변경 이력: https://www.notion.so/33f7060afba881e981d2f5dffb3cd904

## 세션 시작 시
1. 이 파일 읽기
2. Notion 변경 이력 확인 (마지막 작업 내용)
3. 필요 시 Notion GDD 참조

## 세션 종료 시
- Notion 변경 이력 업데이트 (오늘 작업 내용 추가)
- 다음 할 일 명시

## 코딩 규칙
- GDScript 스타일 가이드 준수 (snake_case, 탭 들여쓰기)
- 에셋 경로 하드코딩 금지 — @export var 또는 리소스 파일 사용
- 커밋 메시지: 한국어, "[영역] 변경 내용" 형식
- 씬과 스크립트 분리 원칙

## 기술 설정
- 해상도: 1920×1080 기본 / 최소 1280×720
- Stretch: canvas_items / expand
- 기본 언어: 한국어 (ko)
- 폰트:
  - 팝업·족보·카드명: 본명조 (Source Han Serif KR) — res://assets/fonts/SourceHanSerifKR-Regular.otf
  - HUD·숫자·보조정보: Pretendard — res://assets/fonts/Pretendard-Regular.otf
- 글자 크기: 점수카운터 64px / 팝업타이틀 36px / HUD 24px / 카드텍스트 20px / 보조정보 16px

## 완료된 마일스톤
- ✅ M1 프로토타입 (v0.3.0, 2026-04-11): 코어 루프, UI/UX 전면 개선, 손맛 애니메이션
- ✅ M2 연출 & 시스템 확장 (v0.6.0, 2026-04-17): 고/스톱 연출, 꽃비 시스템, 상점 슬롯 교체 UI
- ✅ M3 런 구조 기반 (v0.8.0, 2026-04-18): 기운 카드 10종, 판 번호 HUD, 게임오버/승리 화면
- ✅ M4 Sprint 1 (v0.9.0, 2026-04-19): 연쇄 점수화, 숨겨진 족보 4종, 패 제거 상점

## 현재 마일스톤: M4 Sprint 2
후보 (우선순위 미확정):
- 기운 카드 40종 확장 (현재 10종)
- 특수패 시스템 (산패 특수 효과)
- 밸런스 패스 — 목표 점수 곡선 조정 + 플레이테스트
- 사운드 연결 (카드 플레이/매칭/족보 달성) — M2 이월

## 핵심 아키텍처
- `RoundManager` (Node): 상태머신 — 딜링→턴A→턴B→정산→고스톱
- `Scoring.calculate_with_ki()`: 족보+기운 카드 점수 계산
- `HiddenCombo.check_all()`: 숨겨진 족보 4종 판정
- `ChainBonus`: 연쇄 매칭 추적 + 점수 누적
- `GameManager` (autoload): RunState (엽전/기운카드/제거패/판번호)
- `Shop` (CanvasLayer): 기운 카드 구매/교체 + 패 제거

## 주의사항
- Godot 4.x의 GDScript 2.0 문법 사용 (class_name, @export, @onready 등)
- 3.x 문법 사용 금지 (yield → await, onready → @onready 등)
- 숫자 카운터는 항상 애니메이션으로 상승 — 최종값 즉시 표시 금지
- `add_late_bonus()`: ki_multiplier 미적용 플랫 보너스 (연쇄·숨겨진족보 전용)
