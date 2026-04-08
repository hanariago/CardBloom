# CHANGELOG

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
