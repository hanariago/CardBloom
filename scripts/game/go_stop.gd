class_name GoStop
extends RefCounted

## 고/스톱 상태 관리

enum Decision { NONE, GO, STOP }

var go_count: int = 0            # 고를 선택한 횟수 (최대 3)
var last_decision: Decision = Decision.NONE

const MAX_GO := 3
const EXTRA_TURNS_PER_GO := 3


## 점수 배율 (고 횟수에 따라)
func get_score_multiplier() -> float:
	match go_count:
		0: return 1.0
		1: return 2.0
		2: return 4.0
		3: return 8.0
		_: return 8.0


## 추가 턴 수 (고를 선택할 때마다 +3)
func get_extra_turns() -> int:
	return go_count * EXTRA_TURNS_PER_GO


## 고 선택 가능 여부
func can_go() -> bool:
	return go_count < MAX_GO


## 고 선택
func choose_go() -> void:
	assert(can_go(), "쓰리고 이후 추가 고 불가")
	go_count += 1
	last_decision = Decision.GO


## 스톱 선택
func choose_stop() -> void:
	last_decision = Decision.STOP


## 고 실패 패널티 계산
## 반환: { "score_lost": bool, "coins_penalty": int, "ki_card_lost": bool }
func get_fail_penalty() -> Dictionary:
	match go_count:
		1:
			return {"score_lost": true, "coins_penalty": 0, "ki_card_lost": false}
		2:
			return {"score_lost": true, "coins_penalty": -1, "ki_card_lost": false}  # 엽전 절반 (호출측에서 계산)
		3:
			return {"score_lost": true, "coins_penalty": 0, "ki_card_lost": true}
		_:
			return {"score_lost": false, "coins_penalty": 0, "ki_card_lost": false}


## 고 횟수 텍스트
func get_go_label() -> String:
	match go_count:
		1: return "고"
		2: return "고고"
		3: return "쓰리고"
		_: return ""


## 다음 고 선택 시 배율 미리보기
func get_next_multiplier() -> float:
	match go_count:
		0: return 2.0
		1: return 4.0
		2: return 8.0
		_: return 8.0


## 리셋 (판 시작 시)
func reset() -> void:
	go_count = 0
	last_decision = Decision.NONE
