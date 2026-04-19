class_name HiddenCombo
extends RefCounted

## 숨겨진 족보 — 판 종료 시 특수 조건 달성 보너스
## add_late_bonus() 사용 — ki_multiplier 미적용

var id: String
var display_name: String
var bonus: int


## 조건 달성 여부 (서브클래스 오버라이드)
func check(_collected: Dictionary) -> bool:
	return false


## 전체 숨겨진 족보 목록
static func get_all() -> Array:
	return [Sagyejeol.new(), Dongmulwon.new(), Mujigae.new(), Dalbam.new()]


## collected 기준 달성된 족보 반환
static func check_all(collected: Dictionary) -> Array:
	var result: Array = []
	for entry: HiddenCombo in get_all():
		if entry.check(collected):
			result.append(entry)
	return result


# ── 족보 정의 ────────────────────────────────────────────

## 사계절: 1·4·7·10월 각 1장 이상 수집  (+20)
class Sagyejeol extends HiddenCombo:
	func _init() -> void:
		id = "사계절"
		display_name = "사계절"
		bonus = 20

	func check(collected: Dictionary) -> bool:
		var all_cards: Array = []
		for arr: Array in collected.values():
			all_cards.append_array(arr)
		for m: int in [1, 4, 7, 10]:
			var found := false
			for c: CardData.Card in all_cards:
				if c.month == m:
					found = true
					break
			if not found:
				return false
		return true


## 동물원: 열끗 6장 이상 수집  (+15)
class Dongmulwon extends HiddenCombo:
	func _init() -> void:
		id = "동물원"
		display_name = "동물원"
		bonus = 15

	func check(collected: Dictionary) -> bool:
		return (collected.get("animal", []) as Array).size() >= 6


## 무지개: 홍단+청단+초단 동시 달성  (+20)
class Mujigae extends HiddenCombo:
	func _init() -> void:
		id = "무지개"
		display_name = "무지개"
		bonus = 20

	func check(collected: Dictionary) -> bool:
		var ribbons: Array = collected.get("ribbon", [])
		return _has_months(ribbons, [1, 2, 3]) \
			and _has_months(ribbons, [6, 9, 10]) \
			and _has_months(ribbons, [4, 5, 7])

	func _has_months(cards: Array, months: Array) -> bool:
		for m: int in months:
			var found := false
			for c: CardData.Card in cards:
				if c.month == m:
					found = true
					break
			if not found:
				return false
		return true


## 달밤: 8월 광 + 8월 열끗 동시 보유  (+25)
class Dalbam extends HiddenCombo:
	func _init() -> void:
		id = "달밤"
		display_name = "달밤"
		bonus = 25

	func check(collected: Dictionary) -> bool:
		var has_g := (collected.get("gwang", []) as Array).any(
			func(c: CardData.Card) -> bool: return c.month == 8
		)
		var has_a := (collected.get("animal", []) as Array).any(
			func(c: CardData.Card) -> bool: return c.month == 8
		)
		return has_g and has_a
