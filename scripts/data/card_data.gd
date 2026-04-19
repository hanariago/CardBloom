class_name CardData
extends Resource

## 화투 카드 유형
enum Type {
	GWANG,    # 광 (光) — 20점
	RIBBON,   # 띠 (帶) — 족보용
	ANIMAL,   # 열끗 (動物) — 족보용
	PI,       # 피 (皮) — 1점
	DOUBLE_PI # 쌍피 — 2점 (특수)
}

## 띠 색상 (족보 구분용)
enum RibbonColor {
	NONE,
	RED,   # 홍단 — 1, 2, 3월
	BLUE,  # 청단 — 6, 9, 10월
	GREEN  # 초단 — 4, 5, 7월
}

## 카드 1장 정의
class Card:
	var month: int          # 1~12
	var type: Type
	var ribbon_color: RibbonColor
	var base_score: int
	var label: String       # 표시 텍스트 (예: "1월 光")
	var color_hint: Color   # Placeholder 배경색

	func _init(m: int, t: Type, rc: RibbonColor, score: int, lbl: String, color: Color) -> void:
		month = m
		type = t
		ribbon_color = rc
		base_score = score
		label = lbl
		color_hint = color


## 전체 48장 덱 생성
static func create_deck() -> Array[Card]:
	var deck: Array[Card] = []

	# 1월 — 솔 (松) | 홍단
	deck.append(Card.new(1, Type.GWANG,  RibbonColor.NONE, 20, "1월 光",  Color(0.78, 0.24, 0.23)))  # 광: 학
	deck.append(Card.new(1, Type.RIBBON, RibbonColor.RED,   0, "1월 홍단", Color(0.78, 0.24, 0.23)))
	deck.append(Card.new(1, Type.PI,     RibbonColor.NONE,  1, "1월 피",   Color(0.78, 0.24, 0.23)))
	deck.append(Card.new(1, Type.PI,     RibbonColor.NONE,  1, "1월 피",   Color(0.78, 0.24, 0.23)))

	# 2월 — 매화 (梅) | 홍단
	deck.append(Card.new(2, Type.ANIMAL, RibbonColor.NONE,  0, "2월 열끗", Color(0.91, 0.65, 0.75)))  # 꾀꼬리
	deck.append(Card.new(2, Type.RIBBON, RibbonColor.RED,   0, "2월 홍단", Color(0.91, 0.65, 0.75)))
	deck.append(Card.new(2, Type.PI,     RibbonColor.NONE,  1, "2월 피",   Color(0.91, 0.65, 0.75)))
	deck.append(Card.new(2, Type.PI,     RibbonColor.NONE,  1, "2월 피",   Color(0.91, 0.65, 0.75)))

	# 3월 — 벚꽃 (桃) | 홍단
	deck.append(Card.new(3, Type.GWANG,  RibbonColor.NONE, 20, "3월 光",  Color(0.93, 0.50, 0.68)))  # 광: 막걸리
	deck.append(Card.new(3, Type.RIBBON, RibbonColor.RED,   0, "3월 홍단", Color(0.93, 0.50, 0.68)))
	deck.append(Card.new(3, Type.PI,     RibbonColor.NONE,  1, "3월 피",   Color(0.93, 0.50, 0.68)))
	deck.append(Card.new(3, Type.PI,     RibbonColor.NONE,  1, "3월 피",   Color(0.93, 0.50, 0.68)))

	# 4월 — 흑싸리 (棣) | 초단
	deck.append(Card.new(4, Type.ANIMAL, RibbonColor.NONE,  0, "4월 열끗", Color(0.23, 0.49, 0.37)))  # 뻐꾸기
	deck.append(Card.new(4, Type.RIBBON, RibbonColor.GREEN, 0, "4월 초단", Color(0.23, 0.49, 0.37)))
	deck.append(Card.new(4, Type.PI,     RibbonColor.NONE,  1, "4월 피",   Color(0.23, 0.49, 0.37)))
	deck.append(Card.new(4, Type.PI,     RibbonColor.NONE,  1, "4월 피",   Color(0.23, 0.49, 0.37)))

	# 5월 — 난초 (蘭) | 초단
	deck.append(Card.new(5, Type.ANIMAL, RibbonColor.NONE,  0, "5월 열끗", Color(0.29, 0.56, 0.36)))  # 나비
	deck.append(Card.new(5, Type.RIBBON, RibbonColor.GREEN, 0, "5월 초단", Color(0.29, 0.56, 0.36)))
	deck.append(Card.new(5, Type.PI,     RibbonColor.NONE,  1, "5월 피",   Color(0.29, 0.56, 0.36)))
	deck.append(Card.new(5, Type.PI,     RibbonColor.NONE,  1, "5월 피",   Color(0.29, 0.56, 0.36)))

	# 6월 — 모란 (牡丹) | 청단
	deck.append(Card.new(6, Type.ANIMAL, RibbonColor.NONE,  0, "6월 열끗", Color(0.18, 0.37, 0.54)))  # 나비
	deck.append(Card.new(6, Type.RIBBON, RibbonColor.BLUE,  0, "6월 청단", Color(0.18, 0.37, 0.54)))
	deck.append(Card.new(6, Type.PI,     RibbonColor.NONE,  1, "6월 피",   Color(0.18, 0.37, 0.54)))
	deck.append(Card.new(6, Type.PI,     RibbonColor.NONE,  1, "6월 피",   Color(0.18, 0.37, 0.54)))

	# 7월 — 홍싸리 (萩) | 초단
	deck.append(Card.new(7, Type.ANIMAL, RibbonColor.NONE,  0, "7월 열끗", Color(0.80, 0.33, 0.20)))  # 멧돼지
	deck.append(Card.new(7, Type.RIBBON, RibbonColor.GREEN, 0, "7월 초단", Color(0.80, 0.33, 0.20)))
	deck.append(Card.new(7, Type.PI,     RibbonColor.NONE,  1, "7월 피",   Color(0.80, 0.33, 0.20)))
	deck.append(Card.new(7, Type.PI,     RibbonColor.NONE,  1, "7월 피",   Color(0.80, 0.33, 0.20)))

	# 8월 — 공산 (芒) | 없음
	deck.append(Card.new(8, Type.GWANG,  RibbonColor.NONE, 20, "8월 光",  Color(0.79, 0.66, 0.30)))  # 광: 보름달
	deck.append(Card.new(8, Type.ANIMAL, RibbonColor.NONE,  0, "8월 열끗", Color(0.79, 0.66, 0.30)))  # 기러기
	deck.append(Card.new(8, Type.PI,     RibbonColor.NONE,  1, "8월 피",   Color(0.79, 0.66, 0.30)))
	deck.append(Card.new(8, Type.PI,     RibbonColor.NONE,  1, "8월 피",   Color(0.79, 0.66, 0.30)))

	# 9월 — 국화 (菊) | 청단
	deck.append(Card.new(9, Type.ANIMAL, RibbonColor.NONE,  0, "9월 열끗", Color(0.85, 0.72, 0.25)))  # 술잔
	deck.append(Card.new(9, Type.RIBBON, RibbonColor.BLUE,  0, "9월 청단", Color(0.85, 0.72, 0.25)))
	deck.append(Card.new(9, Type.PI,     RibbonColor.NONE,  1, "9월 피",   Color(0.85, 0.72, 0.25)))
	deck.append(Card.new(9, Type.PI,     RibbonColor.NONE,  1, "9월 피",   Color(0.85, 0.72, 0.25)))

	# 10월 — 단풍 (楓) | 청단
	deck.append(Card.new(10, Type.ANIMAL, RibbonColor.NONE,  0, "10월 열끗", Color(0.72, 0.26, 0.14)))  # 사슴
	deck.append(Card.new(10, Type.RIBBON, RibbonColor.BLUE,  0, "10월 청단", Color(0.72, 0.26, 0.14)))
	deck.append(Card.new(10, Type.PI,     RibbonColor.NONE,  1, "10월 피",   Color(0.72, 0.26, 0.14)))
	deck.append(Card.new(10, Type.PI,     RibbonColor.NONE,  1, "10월 피",   Color(0.72, 0.26, 0.14)))

	# 11월 — 오동 (梧桐) | 없음 (광 2장 특수 구조)
	deck.append(Card.new(11, Type.GWANG,     RibbonColor.NONE, 20, "11월 光",  Color(0.29, 0.22, 0.16)))  # 광: 봉황
	deck.append(Card.new(11, Type.ANIMAL,    RibbonColor.NONE,  0, "11월 열끗", Color(0.29, 0.22, 0.16)))  # 제비
	deck.append(Card.new(11, Type.PI,        RibbonColor.NONE,  1, "11월 피",   Color(0.29, 0.22, 0.16)))
	deck.append(Card.new(11, Type.DOUBLE_PI, RibbonColor.NONE,  2, "11월 쌍피", Color(0.29, 0.22, 0.16)))

	# 12월 — 비 (柳) | 없음 (광 + 특수 구조)
	deck.append(Card.new(12, Type.GWANG,     RibbonColor.NONE, 20, "12월 光",  Color(0.10, 0.10, 0.18)))  # 광: 비맞는 사람
	deck.append(Card.new(12, Type.ANIMAL,    RibbonColor.NONE,  0, "12월 열끗", Color(0.10, 0.10, 0.18)))  # 제비
	deck.append(Card.new(12, Type.PI,        RibbonColor.NONE,  1, "12월 피",   Color(0.10, 0.10, 0.18)))
	deck.append(Card.new(12, Type.DOUBLE_PI, RibbonColor.NONE,  2, "12월 쌍피", Color(0.10, 0.10, 0.18)))

	return deck


## 덱을 무작위로 섞기
static func shuffle_deck(deck: Array[Card]) -> Array[Card]:
	var shuffled := deck.duplicate()
	shuffled.shuffle()
	return shuffled


## 월별 카드 조회
static func get_cards_by_month(deck: Array[Card], month: int) -> Array[Card]:
	return deck.filter(func(c: Card) -> bool: return c.month == month)


## 유형별 카드 조회
static func get_cards_by_type(deck: Array[Card], type: Type) -> Array[Card]:
	return deck.filter(func(c: Card) -> bool: return c.type == type)


## 영구 제거 목록 기반 필터링 덱 생성
## removed: [{month: int, type: int}, ...] — RunState.removed_card_specs
static func create_deck_filtered(removed: Array) -> Array[Card]:
	if removed.is_empty():
		return create_deck()
	return create_deck().filter(func(c: Card) -> bool:
		for spec: Dictionary in removed:
			if c.month == spec["month"] and c.type == spec["type"]:
				return false
		return true
	)
