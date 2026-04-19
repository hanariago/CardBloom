class_name ChainBonus
extends RefCounted

## 연쇄 매칭 보너스 추적
## 산패 뒤집기(턴B)에서 연속 매칭 성공 시 배율 상승

var _consecutive_count: int = 0
var chain_score_bonus: int = 0  # 이번 판 연쇄로 쌓인 점수 보너스 합계

## 배율 텍스트 (연출용)
const CHAIN_LABELS := {
	2: "연쇄!",
	3: "대연쇄!!",
	4: "기적!!!",
}

## 산패 뒤집기 결과를 받아 카운터 업데이트, 현재 배율 반환
func record_flip(matched: bool) -> float:
	if matched:
		_consecutive_count += 1
		match _consecutive_count:
			2: chain_score_bonus += 8
			3: chain_score_bonus += 15
			_:
				if _consecutive_count >= 4:
					chain_score_bonus += 25
	else:
		_consecutive_count = 0
	return get_multiplier()


## 현재 연쇄 배율
func get_multiplier() -> float:
	match _consecutive_count:
		0, 1:
			return 1.0
		2:
			return 1.5
		3:
			return 2.0
		_:  # 4 이상
			return 3.0


## 현재 연쇄 수
func get_count() -> int:
	return _consecutive_count


## 연쇄 텍스트 (2연속 미만이면 빈 문자열)
func get_label() -> String:
	if _consecutive_count < 2:
		return ""
	var key: int = mini(_consecutive_count, 4)
	return CHAIN_LABELS.get(key, "기적!!!")


## 보너스 엽전 (4연속 이상 시 +5)
func get_bonus_coins() -> int:
	if _consecutive_count >= 4:
		return 5
	return 0


## 리셋 (판 시작 시 호출)
func reset() -> void:
	_consecutive_count = 0
	chain_score_bonus = 0
