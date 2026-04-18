class_name KiCardData
extends RefCounted

## 기운(氣) 카드 — 이 게임의 "조커"
## M3: 10종 구현. 내부 클래스로 모두 정의.

enum Rarity { COMMON, RARE, LEGENDARY, MYTHIC }

var id: String = ""
var display_name: String = ""
var emoji: String = ""
var description: String = ""
var rarity: Rarity = Rarity.COMMON
var price: int = 5


## 점수 계산 후 breakdown에 ki 효과 적용 (subclass에서 override)
func apply_to_breakdown(breakdown: Scoring.ScoreBreakdown, collected: Dictionary) -> void:
	pass


## 판 종료 시 추가 엽전 반환 (기본 0 — 먹보 등에서 override)
func apply_end_of_round_coins(collected: Dictionary) -> int:
	return 0


## 등급 색상
func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON:    return Color(0.75, 0.75, 0.75)
		Rarity.RARE:      return Color(0.18, 0.37, 0.54)
		Rarity.LEGENDARY: return Color(0.79, 0.66, 0.30)
		Rarity.MYTHIC:    return Color(0.78, 0.24, 0.23)
	return Color.WHITE


## 등급 이름
func get_rarity_label() -> String:
	match rarity:
		Rarity.COMMON:    return "일반"
		Rarity.RARE:      return "희귀"
		Rarity.LEGENDARY: return "전설"
		Rarity.MYTHIC:    return "신화"
	return ""


## 카드 풀 (M3 기준 10종)
static func get_pool_m1() -> Array[KiCardData]:
	var pool: Array[KiCardData] = []
	pool.append(BomBaram.new())
	pool.append(Boreumdag.new())
	pool.append(HongdanShin.new())
	pool.append(Isulpul.new())
	pool.append(Dalbich.new())
	pool.append(Mulanage.new())
	pool.append(Doksurit.new())
	pool.append(NagariPung.new())
	pool.append(Meokbo.new())
	pool.append(Paewang.new())
	return pool


# ──────────────────────────────────────────────────────
## 🌸 봄바람 (일반) — 1~3월 패를 수집할 때마다 +3점
# ──────────────────────────────────────────────────────
class BomBaram extends KiCardData:
	func _init() -> void:
		id = "bom_baram"
		display_name = "봄바람"
		emoji = "🌸"
		description = "1~3월 패를 수집할 때마다 +3점"
		rarity = Rarity.COMMON
		price = 4

	func apply_to_breakdown(breakdown: Scoring.ScoreBreakdown, collected: Dictionary) -> void:
		var count := 0
		for category in collected.values():
			for card in category:
				if (card as CardData.Card).month <= 3:
					count += 1
		if count > 0:
			breakdown.add_ki_bonus("🌸 봄바람 (%d장)" % count, count * 3)


# ──────────────────────────────────────────────────────
## 🌙 보름달 (희귀) — 광 패 점수 ×1.5
# ──────────────────────────────────────────────────────
class Boreumdag extends KiCardData:
	func _init() -> void:
		id = "boreumdag"
		display_name = "보름달"
		emoji = "🌙"
		description = "광 패 점수 ×1.5 (광 기본점수 50% 추가)"
		rarity = Rarity.RARE
		price = 7

	func apply_to_breakdown(breakdown: Scoring.ScoreBreakdown, collected: Dictionary) -> void:
		var gwang: Array = collected.get("gwang", [])
		if gwang.is_empty():
			return
		var gwang_base := 0
		for c in gwang:
			gwang_base += (c as CardData.Card).base_score
		var bonus := int(gwang_base * 0.5)
		if bonus > 0:
			breakdown.add_ki_bonus("🌙 보름달 (광×1.5)", bonus)


# ──────────────────────────────────────────────────────
## 🔴 홍단신 (희귀) — 빨간 띠 3장 보유 시 판 점수 ×2
# ──────────────────────────────────────────────────────
class HongdanShin extends KiCardData:
	func _init() -> void:
		id = "hongdan_shin"
		display_name = "홍단신"
		emoji = "🔴"
		description = "빨간 띠 3장(1·2·3월) 보유 시 판 점수 ×2"
		rarity = Rarity.RARE
		price = 8

	func apply_to_breakdown(breakdown: Scoring.ScoreBreakdown, collected: Dictionary) -> void:
		var ribbons: Array = collected.get("ribbon", [])
		var red_months := [1, 2, 3]
		for m in red_months:
			var found := false
			for c in ribbons:
				if (c as CardData.Card).month == m and \
				   (c as CardData.Card).ribbon_color == CardData.RibbonColor.RED:
					found = true
					break
			if not found:
				return  # 3장 미완성
		# 조건 달성: ×2 배율 적용
		breakdown.apply_ki_multiplier("🔴 홍단신 (×2)", 2.0)


# ──────────────────────────────────────────────────────
## 🌿 이슬풀 (일반) — 초록 띠(4·5·7월) 수집마다 +2점
# ──────────────────────────────────────────────────────
class Isulpul extends KiCardData:
	func _init() -> void:
		id = "isulpul"
		display_name = "이슬풀"
		emoji = "🌿"
		description = "초록 띠(4·5·7월) 수집마다 +2점"
		rarity = Rarity.COMMON
		price = 4

	func apply_to_breakdown(breakdown: Scoring.ScoreBreakdown, collected: Dictionary) -> void:
		var ribbons: Array = collected.get("ribbon", [])
		var count := 0
		for c in ribbons:
			if (c as CardData.Card).ribbon_color == CardData.RibbonColor.GREEN:
				count += 1
		if count > 0:
			breakdown.add_ki_bonus("🌿 이슬풀 (%d장)" % count, count * 2)


# ──────────────────────────────────────────────────────
## 🌟 달빛 (일반) — 열끗 패 수집마다 +2점
# ──────────────────────────────────────────────────────
class Dalbich extends KiCardData:
	func _init() -> void:
		id = "dalbich"
		display_name = "달빛"
		emoji = "🌟"
		description = "열끗 패 수집마다 +2점"
		rarity = Rarity.COMMON
		price = 4

	func apply_to_breakdown(breakdown: Scoring.ScoreBreakdown, collected: Dictionary) -> void:
		var count: int = collected.get("animal", []).size()
		if count > 0:
			breakdown.add_ki_bonus("🌟 달빛 (%d장)" % count, count * 2)


# ──────────────────────────────────────────────────────
## 🌊 물안개 (희귀) — 청단(6·9·10월 파란 띠 3장) 달성 시 +15점
# ──────────────────────────────────────────────────────
class Mulanage extends KiCardData:
	func _init() -> void:
		id = "mulanage"
		display_name = "물안개"
		emoji = "🌊"
		description = "청단(파란 띠 3장) 달성 시 +15점"
		rarity = Rarity.RARE
		price = 6

	func apply_to_breakdown(breakdown: Scoring.ScoreBreakdown, collected: Dictionary) -> void:
		var ribbons: Array = collected.get("ribbon", [])
		var blue_months := [6, 9, 10]
		for m in blue_months:
			var found := false
			for c in ribbons:
				if (c as CardData.Card).month == m and \
				   (c as CardData.Card).ribbon_color == CardData.RibbonColor.BLUE:
					found = true
					break
			if not found:
				return
		breakdown.add_ki_bonus("🌊 물안개 (청단 달성)", 15)


# ──────────────────────────────────────────────────────
## 🦅 독수리 (전설) — 고도리(2·4·8월 열끗) 달성 시 점수 ×1.5
# ──────────────────────────────────────────────────────
class Doksurit extends KiCardData:
	func _init() -> void:
		id = "doksurit"
		display_name = "독수리"
		emoji = "🦅"
		description = "고도리(2·4·8월 열끗) 달성 시 점수 ×1.5"
		rarity = Rarity.LEGENDARY
		price = 9

	func apply_to_breakdown(breakdown: Scoring.ScoreBreakdown, collected: Dictionary) -> void:
		var animals: Array = collected.get("animal", [])
		var godori_months := [2, 4, 8]
		for m in godori_months:
			var found := false
			for c in animals:
				if (c as CardData.Card).month == m:
					found = true
					break
			if not found:
				return
		breakdown.apply_ki_multiplier("🦅 독수리 (고도리 ×1.5)", 1.5)


# ──────────────────────────────────────────────────────
## 💨 나가리 풍 (전설) — 피 10점 이상 달성 시 +20점
# ──────────────────────────────────────────────────────
class NagariPung extends KiCardData:
	func _init() -> void:
		id = "nagari_pung"
		display_name = "나가리 풍"
		emoji = "💨"
		description = "피 10점(장) 이상 달성 시 +20점"
		rarity = Rarity.LEGENDARY
		price = 8

	func apply_to_breakdown(breakdown: Scoring.ScoreBreakdown, collected: Dictionary) -> void:
		var pi_cards: Array = collected.get("pi", [])
		var total_pi := 0
		for c in pi_cards:
			if (c as CardData.Card).type == CardData.Type.DOUBLE_PI:
				total_pi += 2
			else:
				total_pi += 1
		if total_pi >= 10:
			breakdown.add_ki_bonus("💨 나가리 풍 (피 10점+)", 20)


# ──────────────────────────────────────────────────────
## 🐷 먹보 (전설) — 판 종료 시 수집 패 수만큼 엽전 +1 (최대 15)
# ──────────────────────────────────────────────────────
class Meokbo extends KiCardData:
	func _init() -> void:
		id = "meokbo"
		display_name = "먹보"
		emoji = "🐷"
		description = "판 종료 시 수집 패 수만큼 엽전 +1 (최대 15)"
		rarity = Rarity.LEGENDARY
		price = 9

	func apply_to_breakdown(_breakdown: Scoring.ScoreBreakdown, _collected: Dictionary) -> void:
		pass  # 엽전 효과는 apply_end_of_round_coins()에서 처리

	func apply_end_of_round_coins(collected: Dictionary) -> int:
		var total := 0
		for category in collected.values():
			total += (category as Array).size()
		return mini(total, 15)


# ──────────────────────────────────────────────────────
## 🃏 패왕 (신화) — 오광(광 5장) 달성 시 점수 ×5
# ──────────────────────────────────────────────────────
class Paewang extends KiCardData:
	func _init() -> void:
		id = "paewang"
		display_name = "패왕"
		emoji = "🃏"
		description = "오광(광 5장) 달성 시 점수 ×5"
		rarity = Rarity.MYTHIC
		price = 12

	func apply_to_breakdown(breakdown: Scoring.ScoreBreakdown, collected: Dictionary) -> void:
		var gwang: Array = collected.get("gwang", [])
		if gwang.size() >= 5:
			breakdown.apply_ki_multiplier("🃏 패왕 (오광 ×5)", 5.0)
