# 꽃판 (Card Bloom)

화투 기반 2D 럭빌더 로그라이크. Godot 4.x + GDScript.

## 게임 설계 문서 (Notion)
- 메인: https://www.notion.so/3397060afba8815e92a7e033414cdb22
- GDD Part 1: https://www.notion.so/3397060afba8812aa9d8dabb75eef1ef
- GDD Part 2: https://www.notion.so/3397060afba88105b907fb67233d7c4d

## 세션 시작 시
1. 이 파일 읽기
2. CHANGELOG.md 확인 (마지막 작업 내용)
3. 필요 시 Notion GDD 참조

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

## 현재 마일스톤: M1 프로토타입
- 코어 루프: 딜링 → 매칭 → 정산 → 고/스톱
- 주스 연출 (점수 카운터 "두두두두" 애니메이션)
- 연쇄 매칭 보너스 (2연속×1.5 / 3연속×2 / 4연속+×3)

## 주의사항
- Godot 4.x의 GDScript 2.0 문법 사용 (class_name, @export, @onready 등)
- 3.x 문법 사용 금지 (yield → await, onready → @onready 등)
- 숫자 카운터는 항상 애니메이션으로 상승 — 최종값 즉시 표시 금지
