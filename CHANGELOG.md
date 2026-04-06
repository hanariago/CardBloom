# CHANGELOG

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
