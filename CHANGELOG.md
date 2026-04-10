# CHANGELOG

## [0.3.0] — 2026-04-11 | UI/UX 전면 개선 (M1 P2)

### UI 시스템
- UITheme 오토로드 — Pretendard + 본명조 폰트 캐싱, apply_pretendard/apply_serif 헬퍼
- CardNode 전면 재설계 — 100×150px 크림 배경, 유형색 테두리/띠, 월 숫자(38px) + 한자(40px)
- StatusBanner — 전폭 1920px, set_text/flash 분리
- ComboTracker — 좌측 패널, 10개 족보 ●○ 실시간 진행도
- ScorePopup — 수집 시 떠오르는 점수 팝업
- TutorialHint — 첫 판 오버레이 튜토리얼

### 레이아웃 재설계
- 바닥(녹색 패널) / 손패(남색 패널) 구역 명확히 분리, 파란 구분선
- 산패 우상단 패널(x=1680, y=132), 수집 현황 그 아래 배치
- 바닥 카드 0.8 스케일 — 손패(1.0)와 크기 차이로 구역 구분
- 손패 중심 x=FLOOR_CX로 정렬

### 연출/애니메이션
- 손패 카드 날아가기 — 들기(0.08s) + ±22° 기울기 + 날아가기(0.36s) + 착지 후 z_index=-1(아래 패 보임)
- 비행 중 반투명(0.78) + 0.88 축소 → 겹침 시 아래 카드 비쳐보임
- 겹침 유지 0.55s 후 페이드아웃 (손맛)
- 산패 카드 — z_index=5 최상위, 목표 슬롯으로 날아가기
- 매칭 카드 튀기기 — 착지 직전 1.25배 bounce
- 턴 전환 플래시 — 손패→산패 페이즈 구분 (0.12s 어두워짐)
- is_interactive=false 시 hover_exit 무시 (tween 충돌 방지)

### 게임플레이
- 손패 선택 호버 예측 — "✔ 3월 광 → 바닥에 같은 월 1장!" 실시간 표시
- 매칭 힌트 — 수집 후 가장 가까운 족보 완성 힌트
- 목표 점수 60점 기본 (이전 20점에서 상향)
- 달성 시 점수 내역 한 줄 요약

### 버그 픽스
- global_script_class_cache.cfg 수동 등록 (StatusBanner 등 신규 class_name)
- class_name UITheme 제거 (오토로드 이름 충돌)
- Dictionary 값 Variant 타입 캐스트 오류 수정 (ComboTracker)

## [0.2.0] — 2026-04-08 | M1 P1 완료

### 추가
- 기운 카드 시스템 (ki_card_data.gd) — 봄바람/보름달/홍단신 3종 구현
- scoring.gd ki 지원 — ki_bonus/ki_multiplier 필드, calculate_with_ki() 함수
- HUD 기운 카드 슬롯 5칸 (장착 카드 이모지 표시)
- 상점 오버레이 (shop.gd) — 3종 선택, 구매/리롤(1엽전+1)/스킵

### 버그 픽스
- 손패 카드 플레이 후 시각적 제거 누락 수정 (_last_played_node 추적)
- 턴 처리 후 바닥 패 미갱신 수정 (refresh_floor 추가)
- hud.screen_shake_target 미노출 수정 (setter로 score_display에 전달)
- 런 미초기화 시 null 오류 수정 (round.gd _ready에서 자동 시작)
- round_manager 점수 체크에 ki 카드 효과 반영

### 다음 작업 (M2)
- [ ] 고/스톱 연출 강화 (BGM 템포 변화, 카운트다운)
- [ ] 꽃비 시스템 (판 시작 15~20% 확률)
- [ ] 패 매칭 피드백 강화 (사운드 연결)
- [ ] 상점 — 기운 카드 슬롯 교체 UI (5칸 초과 시)

## [0.1.0] — 2026-04-05 | M1 프로토타입 시작

### 추가
- Git 저장소 초기화 및 GitHub 연결
- Godot 4.x 프로젝트 초기 세팅 (project.godot)
- 폴더 구조 생성 (assets, scenes, scripts, resources)
- CLAUDE.md, CHANGELOG.md 작성
- 폰트 배치: 본명조(SourceHanSerifKR) + Pretendard
- 화투 48장 카드 데이터 정의 (scripts/data/card_data.gd)
- GameManager, AudioManager 오토로드 기본 구조

### 확정된 설계
- 해상도: 1920×1080, canvas_items/expand stretch
- 언어: 한국어 기본
- 폰트 전략: 본명조(팝업/카드명) + Pretendard(HUD/숫자) 혼용

### 다음 작업 (M1 계속)
- [ ] 기본 매칭 로직 (matching.gd)
- [ ] 한 판 진행 시스템 (round_manager.gd)
- [ ] 족보 점수 계산 (scoring.gd)
- [ ] 고/스톱 UI
- [ ] 주스 연출 (점수 카운터 애니메이션)
- [ ] 연쇄 매칭 보너스
