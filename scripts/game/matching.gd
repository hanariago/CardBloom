class_name Matching
extends RefCounted

## 화투 매칭 로직 — 순수 함수 모음

## 매칭 결과
class MatchResult:
	var matched: bool = false
	var hand_card: CardData.Card = null
	var floor_cards: Array[CardData.Card] = []  # 매칭된 바닥 패
	var is_ssok: bool = false  # 쪽 여부 (바닥 2장 매칭)

	func _init(h: CardData.Card, floor: Array[CardData.Card], ssok: bool) -> void:
		matched = not floor.is_empty()
		hand_card = h
		floor_cards = floor
		is_ssok = ssok


## 손패 내리기 (턴 A) — 바닥에서 같은 월 카드 찾기
## 반환: MatchResult
static func play_hand_card(
	hand_card: CardData.Card,
	floor_cards: Array[CardData.Card]
) -> MatchResult:
	var same_month := _get_same_month(hand_card.month, floor_cards)

	match same_month.size():
		0:
			# 매칭 없음 — 바닥에 놓임
			return MatchResult.new(hand_card, [], false)
		1:
			# 일반 매칭 — 1장 가져감
			return MatchResult.new(hand_card, same_month, false)
		2:
			# 쪽! — 바닥 2장 + 손패 1장, 3장 전부 가져감
			return MatchResult.new(hand_card, same_month, true)
		3:
			# 바닥에 3장 모두 있는 경우 — 전부 가져감 (뻑 방지)
			return MatchResult.new(hand_card, same_month, false)
		_:
			return MatchResult.new(hand_card, [], false)


## 산패 뒤집기 (턴 B) — 바닥에서 같은 월 카드 찾기
## 반환: MatchResult
static func flip_mountain_card(
	mountain_card: CardData.Card,
	floor_cards: Array[CardData.Card]
) -> MatchResult:
	var same_month := _get_same_month(mountain_card.month, floor_cards)

	match same_month.size():
		0:
			return MatchResult.new(mountain_card, [], false)
		1:
			return MatchResult.new(mountain_card, same_month, false)
		2:
			# 바닥에 2장 → 뒤집은 패 포함 3장 전부 가져감
			return MatchResult.new(mountain_card, same_month, false)
		3:
			return MatchResult.new(mountain_card, same_month, false)
		_:
			return MatchResult.new(mountain_card, [], false)


## 바닥에서 특정 월 카드 반환
static func _get_same_month(month: int, floor_cards: Array[CardData.Card]) -> Array[CardData.Card]:
	var result: Array[CardData.Card] = []
	for card in floor_cards:
		if card.month == month:
			result.append(card)
	return result


## 바닥 패 업데이트 — 매칭 결과 적용 후 남은 바닥 패 반환
static func apply_match_to_floor(
	result: MatchResult,
	floor_cards: Array[CardData.Card]
) -> Array[CardData.Card]:
	if not result.matched:
		# 매칭 없음: 손패/산패를 바닥에 추가
		var new_floor := floor_cards.duplicate()
		new_floor.append(result.hand_card)
		return new_floor

	# 매칭된 바닥 패 제거
	var new_floor: Array[CardData.Card] = []
	for card in floor_cards:
		if not result.floor_cards.has(card):
			new_floor.append(card)
	return new_floor
