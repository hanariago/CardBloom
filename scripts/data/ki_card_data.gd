class_name KiCardData
extends RefCounted

## 기운(氣) 카드 — 이 게임의 "조커"
## M1: 3종 구현. 내부 클래스로 모두 정의.

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


## M1 카드 풀 (3종)
static func get_pool_m1() -> Array[KiCardData]:
	var pool: Array[KiCardData] = []
	pool.append(BomBaram.new())
	pool.append(Boreumdag.new())
	pool.append(HongdanShin.new())
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
