class_name Scoring
extends RefCounted

## 족보 점수 계산 — 순수 함수 모음

## 점수 내역 (UI 표시용)
class ScoreBreakdown:
	var base_score: int = 0       # 광+피 기본 합산
	var combo_bonus: int = 0      # 족보 보너스 합계
	var ki_bonus: int = 0         # 기운 카드 플랫 보너스
	var ki_multiplier: float = 1.0 # 기운 카드 배율 (홍단신 등)
	var total_score: int = 0
	var combos: Array[ComboEntry] = []  # 달성한 족보 목록

	func _init() -> void:
		pass

	func add_combo(name: String, points: int) -> void:
		var entry := ComboEntry.new(name, points)
		combos.append(entry)
		combo_bonus += points

	## 기운 카드 플랫 보너스
	func add_ki_bonus(name: String, points: int) -> void:
		var entry := ComboEntry.new(name, points)
		combos.append(entry)
		ki_bonus += points

	## 기운 카드 배율 적용 (누적 곱)
	func apply_ki_multiplier(name: String, mult: float) -> void:
		var preview := int((base_score + combo_bonus + ki_bonus) * (ki_multiplier * mult - ki_multiplier))
		var entry := ComboEntry.new(name, preview)
		combos.append(entry)
		ki_multiplier *= mult

	func finalize() -> void:
		total_score = int((base_score + combo_bonus + ki_bonus) * ki_multiplier)


class ComboEntry:
	var name: String
	var points: int

	func _init(n: String, p: int) -> void:
		name = n
		points = p


## 수집 패로 전체 점수 계산
## collected = { "gwang": [...], "ribbon": [...], "animal": [...], "pi": [...] }
static func calculate(collected: Dictionary) -> ScoreBreakdown:
	var breakdown := ScoreBreakdown.new()

	var gwang_cards: Array[CardData.Card] = collected.get("gwang", [])
	var ribbon_cards: Array[CardData.Card] = collected.get("ribbon", [])
	var animal_cards: Array[CardData.Card] = collected.get("animal", [])
	var pi_cards: Array[CardData.Card] = collected.get("pi", [])

	# 기본 점수: 광 각 20점, 피 각 1점 (쌍피 2점)
	for c in gwang_cards:
		breakdown.base_score += c.base_score
	for c in pi_cards:
		breakdown.base_score += c.base_score

	# 족보 체크
	_check_gwang_combos(gwang_cards, breakdown)
	_check_ribbon_combos(ribbon_cards, breakdown)
	_check_animal_combos(animal_cards, breakdown)
	_check_pi_combo(pi_cards, breakdown)

	breakdown.finalize()
	return breakdown


## 기운 카드 효과 포함 점수 계산
static func calculate_with_ki(collected: Dictionary, ki_cards: Array) -> ScoreBreakdown:
	var breakdown := calculate(collected)
	# finalize() 전 상태로 되돌려서 ki 적용 후 재계산
	breakdown.ki_bonus = 0
	breakdown.ki_multiplier = 1.0
	# combos에서 ki 항목만 제거 (아직 없으므로 그냥 진행)
	for ki in ki_cards:
		(ki as KiCardData).apply_to_breakdown(breakdown, collected)
	breakdown.finalize()
	return breakdown


## 광 족보
static func _check_gwang_combos(gwang: Array[CardData.Card], bd: ScoreBreakdown) -> void:
	var count := gwang.size()
	var has_rain := gwang.any(func(c: CardData.Card) -> bool: return c.month == 12)

	match count:
		5:
			bd.add_combo("오광", 30)
		4:
			if has_rain:
				bd.add_combo("사광(비포함)", 10)
			else:
				bd.add_combo("사광", 20)
		3:
			if has_rain:
				bd.add_combo("비광", 5)
			else:
				bd.add_combo("삼광", 15)


## 띠 족보
static func _check_ribbon_combos(ribbons: Array[CardData.Card], bd: ScoreBreakdown) -> void:
	var red_months   := [1, 2, 3]
	var blue_months  := [6, 9, 10]
	var green_months := [4, 5, 7]

	var has_red   := _has_all_months(ribbons, red_months)
	var has_blue  := _has_all_months(ribbons, blue_months)
	var has_green := _has_all_months(ribbons, green_months)

	if has_red:
		bd.add_combo("홍단", 10)
	if has_blue:
		bd.add_combo("청단", 10)
	if has_green:
		bd.add_combo("초단", 10)

	# 5장 이상 띠 보너스 (+2/장)
	var extra := ribbons.size() - 5
	if extra >= 0:
		bd.add_combo("띠 5장", 5 + extra * 2)


## 열끗 족보
static func _check_animal_combos(animals: Array[CardData.Card], bd: ScoreBreakdown) -> void:
	# 고도리: 2월 + 4월 + 8월 열끗
	var godori_months := [2, 4, 8]
	if _has_all_months(animals, godori_months):
		bd.add_combo("고도리", 15)

	# 5장 이상 열끗 보너스 (+2/장)
	var count := animals.size()
	if count >= 5:
		bd.add_combo("열끗 %d장" % count, 5 + (count - 5) * 2)


## 피 족보
static func _check_pi_combo(pi_cards: Array[CardData.Card], bd: ScoreBreakdown) -> void:
	# 피 점수 합산 (쌍피 포함)
	var total_pi := 0
	for c in pi_cards:
		if c.type == CardData.Type.DOUBLE_PI:
			total_pi += 2
		else:
			total_pi += 1

	# 10장(점) 이상 시 족보 보너스
	if total_pi >= 10:
		bd.add_combo("피 %d점" % total_pi, 5 + (total_pi - 10) * 2)


## 헬퍼: 특정 월 목록을 모두 보유하는지 확인
static func _has_all_months(cards: Array[CardData.Card], months: Array) -> bool:
	for m in months:
		var found := false
		for c in cards:
			if c.month == m:
				found = true
				break
		if not found:
			return false
	return true
