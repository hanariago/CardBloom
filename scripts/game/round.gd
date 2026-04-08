extends Node2D

## 라운드 씬 루트 — 모든 시스템 배선 및 게임 진행 제어

var _round_manager: RoundManager
var _board: Board
var _hud: HUD
var _status: StatusBanner
var _combo_tracker: ComboTracker
var _tutorial: TutorialHint
var _go_stop_popup: GoStopPopup

var _current_score: int = 0
var _last_played_node: CardNode = null
var _is_first_round: bool = true


func _ready() -> void:
	if GameManager.current_run == null:
		GameManager.start_new_run()

	_build_scene()
	_connect_signals()
	_start_round()


func _build_scene() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12)
	bg.size = Vector2(1920, 1080)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_board = Board.new()
	add_child(_board)

	_hud = HUD.new()
	add_child(_hud)
	_hud.screen_shake_target = _board

	_status = StatusBanner.new()
	add_child(_status)

	_combo_tracker = ComboTracker.new()
	add_child(_combo_tracker)

	_go_stop_popup = GoStopPopup.new()
	add_child(_go_stop_popup)

	_tutorial = TutorialHint.new()
	add_child(_tutorial)

	_round_manager = RoundManager.new()
	add_child(_round_manager)


func _connect_signals() -> void:
	_round_manager.dealing_complete.connect(_on_dealing_complete)
	_round_manager.turn_started.connect(_on_turn_started)
	_round_manager.hand_matched.connect(_on_hand_matched)
	_round_manager.hand_placed.connect(_on_hand_placed)
	_round_manager.mountain_matched.connect(_on_mountain_matched)
	_round_manager.mountain_placed.connect(_on_mountain_placed)
	_round_manager.scoring_complete.connect(_on_scoring_complete)
	_round_manager.goal_reached.connect(_on_goal_reached)
	_round_manager.go_stop_resolved.connect(_on_go_stop_resolved)
	_round_manager.go_failed.connect(_on_go_failed)
	_round_manager.round_complete.connect(_on_round_complete)

	_board.hand_card_clicked.connect(_on_hand_card_selected)
	_board.hand_card_preview.connect(_on_hand_preview)
	_board.hand_card_preview_ended.connect(_on_hand_preview_ended)

	_go_stop_popup.stop_pressed.connect(func() -> void: _round_manager.choose_stop())
	_go_stop_popup.go_pressed.connect(func() -> void: _round_manager.choose_go())

	_tutorial.closed.connect(_on_tutorial_closed)


func _start_round() -> void:
	var target := GameManager.get_round_target_score()
	_hud.update_target(target)
	_hud.update_coins(GameManager.current_run.total_coins)
	_hud.update_ki_slots(GameManager.current_run.ki_cards)
	_round_manager.start_round(target)


# ── RoundManager 신호 핸들러 ─────────────────────────

func _on_dealing_complete(hand: Array, floor: Array, mountain_count: int) -> void:
	_board.setup_initial(hand, floor, mountain_count)
	_hud.update_score(0)
	_current_score = 0
	_combo_tracker.update(_round_manager._collected)

	# 첫 판이면 튜토리얼 표시 (RoundManager가 카드 배분 후 대기)
	if _is_first_round:
		_tutorial.show_tutorial()
		_status.set_text("")
	else:
		_status.set_text("손패에서 패를 선택하세요")


func _on_tutorial_closed() -> void:
	_is_first_round = false
	_status.set_text("손패에서 패를 선택하세요")


func _on_turn_started(turn_number: int, max_turns: int) -> void:
	_hud.update_turn(turn_number, max_turns)
	if not _tutorial.visible:
		_status.set_text("손패에서 패를 선택하세요")


func _on_hand_matched(result: Matching.MatchResult) -> void:
	# 수집 직전 글로우
	if _last_played_node != null and is_instance_valid(_last_played_node):
		_last_played_node.flash_glow()

	_board.clear_highlights()
	_remove_played_node()
	_board.refresh_floor(_round_manager._floor)
	_board.update_collected(_round_manager._collected)
	_combo_tracker.update(_round_manager._collected)
	if result.is_ssok:
		_hud.show_chain("쪽!")
	_show_match_result(result.hand_card, result.floor_cards)
	_show_score_delta()
	_refresh_score()


func _on_hand_placed(card: CardData.Card) -> void:
	_board.clear_highlights()
	_remove_played_node()
	_board.refresh_floor(_round_manager._floor)
	_status.flash("%d월 %s → 바닥에 내려놓았습니다" % [card.month, _card_type_name(card)], 1.2)


func _on_mountain_matched(result: Matching.MatchResult, _chain_count: int, _multiplier: float) -> void:
	_board.animate_mountain_flip(result.hand_card, true)
	_board.refresh_floor(_round_manager._floor)
	_board.update_mountain_count(_round_manager._mountain.size())
	_board.update_collected(_round_manager._collected)
	_combo_tracker.update(_round_manager._collected)

	var label := _round_manager._chain.get_label()
	if not label.is_empty():
		_hud.show_chain(label)
	_show_score_delta()
	_refresh_score()


func _on_mountain_placed(card: CardData.Card) -> void:
	_board.animate_mountain_flip(card, false)
	_board.update_mountain_count(_round_manager._mountain.size())


func _on_scoring_complete(_breakdown: Scoring.ScoreBreakdown, _multiplier: float, final_score: int) -> void:
	_hud.update_score(final_score)
	_current_score = final_score


func _on_goal_reached(current_score: int, target_score: int) -> void:
	_current_score = current_score
	# 점수 내역 한 줄 요약
	var ki_cards: Array = GameManager.current_run.ki_cards
	var breakdown := Scoring.calculate_with_ki(_round_manager._collected, ki_cards)
	var why := _score_breakdown_short(breakdown)
	_status.set_text("목표 %d점 달성! (%s)  →  고 또는 스톱 선택" % [target_score, why])
	_go_stop_popup.show_popup(current_score, target_score, _round_manager._go_stop)


## 점수 내역 짧은 한 줄 요약 ("광20 + 삼광15 + 홍단10 = 45점")
func _score_breakdown_short(bd: Scoring.ScoreBreakdown) -> String:
	var parts: Array[String] = []
	if bd.base_score > 0:
		parts.append("기본%d" % bd.base_score)
	for combo in bd.combos:
		if combo.points > 0:
			parts.append("%s+%d" % [combo.name, combo.points])
	return " + ".join(parts) + " = %d점" % bd.total_score


func _on_go_stop_resolved(decision: GoStop.Decision, _go_count: int, multiplier: float) -> void:
	_go_stop_popup.hide_popup()
	if decision == GoStop.Decision.GO:
		_hud.show_chain("고! (×%s)" % _mult_str(multiplier))
		_status.set_text("손패에서 패를 선택하세요")


func _on_go_failed(_penalty: Dictionary) -> void:
	_hud.show_chain("고 실패...")
	_status.flash("고 실패! 패널티가 적용됩니다", 2.0)
	_hud.update_score(0)


func _on_round_complete(final_score: int, _coins_earned: int) -> void:
	_hud.update_coins(GameManager.current_run.total_coins)
	if GameManager.current_run.round_number < 13:
		_go_to_shop(final_score)


# ── Board 신호 핸들러 ────────────────────────────────────

func _on_hand_card_selected(card_node: CardNode) -> void:
	if _round_manager.state != RoundManager.State.PLAYER_TURN_A:
		_board.clear_selection()
		return
	_last_played_node = card_node
	_board.highlight_matching_floor(card_node.card_data.month)
	_round_manager.select_hand_card(card_node.card_data)


## 호버 예측: "이 카드를 내면 어떻게 되는지" 즉시 표시
func _on_hand_preview(card: CardData.Card, match_count: int) -> void:
	if _round_manager.state != RoundManager.State.PLAYER_TURN_A:
		return
	var type_name := _card_type_name(card)
	if match_count > 0:
		_status.set_text("✔ %d월 %s → 바닥에 같은 월 %d장! 클릭하면 수집" % [card.month, type_name, match_count])
	else:
		_status.set_text("↙ %d월 %s → 바닥에 같은 월 없음, 바닥에 내려놓기" % [card.month, type_name])


func _on_hand_preview_ended() -> void:
	if _round_manager.state == RoundManager.State.PLAYER_TURN_A and not _tutorial.visible:
		_status.set_text("손패에서 패를 선택하세요")


# ── 헬퍼 ────────────────────────────────────────────

func _remove_played_node() -> void:
	if _last_played_node != null:
		_board.remove_from_hand(_last_played_node)
		_last_played_node = null


func _refresh_score() -> void:
	var ki_cards: Array = GameManager.current_run.ki_cards
	var breakdown := Scoring.calculate_with_ki(_round_manager._collected, ki_cards)
	var mult := _round_manager._go_stop.get_score_multiplier()
	_hud.update_score(int(breakdown.total_score * mult))


## 매칭 결과 배너 — 수집 내용 + 족보 힌트
func _show_match_result(played: CardData.Card, floor_cards: Array) -> void:
	var parts: Array[String] = []
	parts.append("%d월 %s" % [played.month, _card_type_name(played)])
	for fc in floor_cards:
		parts.append("%d월 %s" % [fc.month, _card_type_name(fc)])

	var combo_hint := _get_nearest_combo_hint()
	var text := " + ".join(parts) + " 수집!"
	if not combo_hint.is_empty():
		text += "  (%s)" % combo_hint
	_status.flash(text, 1.6)


## 가장 가까운 족보 완성 힌트 (1~2장 남은 것)
func _get_nearest_combo_hint() -> String:
	var collected := _round_manager._collected
	var gwang: Array  = collected.get("gwang", [])
	var ribbon: Array = collected.get("ribbon", [])
	var animal: Array = collected.get("animal", [])
	var pi_arr: Array = collected.get("pi", [])

	var gwang_count := gwang.size()
	# 삼광까지
	if gwang_count == 2:
		return "광 1장 더 → 삼광!"
	if gwang_count == 4:
		return "광 1장 더 → 오광!"

	# 고도리
	var animal_months: Array = animal.map(func(c) -> int: return c.month)
	var godori_have := 0
	for m in [2, 4, 8]:
		if m in animal_months:
			godori_have += 1
	if godori_have == 2:
		return "고도리 1장 더! (2·4·8월 열끗)"

	# 홍단
	var ribbon_months: Array = ribbon.map(func(c) -> int: return c.month)
	var hongdan_have := 0
	for m in [1, 2, 3]:
		if m in ribbon_months:
			hongdan_have += 1
	if hongdan_have == 2:
		return "홍단 1장 더! (1·2·3월 띠)"

	var cheongdan_have := 0
	for m in [6, 9, 10]:
		if m in ribbon_months:
			cheongdan_have += 1
	if cheongdan_have == 2:
		return "청단 1장 더! (6·9·10월 띠)"

	# 피 10점 근접
	var pi_points := 0
	for c in pi_arr:
		pi_points += 2 if c.type == CardData.Type.DOUBLE_PI else 1
	if pi_points >= 8:
		return "피 %d점 → 10점 달성 근접!" % pi_points

	return ""


func _card_type_name(card: CardData.Card) -> String:
	match card.type:
		CardData.Type.GWANG:     return "광"
		CardData.Type.RIBBON:
			match card.ribbon_color:
				CardData.RibbonColor.RED:   return "홍단띠"
				CardData.RibbonColor.BLUE:  return "청단띠"
				CardData.RibbonColor.GREEN: return "초단띠"
				_:                          return "띠"
		CardData.Type.ANIMAL:    return "열끗"
		CardData.Type.PI:        return "피"
		CardData.Type.DOUBLE_PI: return "쌍피"
	return ""


## 점수 변화 팝업
func _show_score_delta() -> void:
	var ki_cards: Array = GameManager.current_run.ki_cards
	var breakdown := Scoring.calculate_with_ki(_round_manager._collected, ki_cards)
	var mult := _round_manager._go_stop.get_score_multiplier()
	var new_score := int(breakdown.total_score * mult)
	var delta := new_score - _current_score
	if delta > 0:
		ScorePopup.spawn(_board, Vector2(790, Board.FLOOR_Y - 60), delta)
	_current_score = new_score


func _go_to_shop(round_score: int) -> void:
	var shop := Shop.new()
	shop.round_score = round_score
	shop.shop_closed.connect(_on_shop_closed)
	add_child(shop)


func _on_shop_closed() -> void:
	GameManager.current_run.round_number += 1
	_hud.update_ki_slots(GameManager.current_run.ki_cards)
	_board.clear_selection()
	_start_round()


func _mult_str(mult: float) -> String:
	return str(int(mult)) if mult == int(mult) else "%.1f" % mult
