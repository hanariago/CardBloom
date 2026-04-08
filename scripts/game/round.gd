extends Node2D

## 라운드 씬 루트 — 모든 시스템 배선 및 게임 진행 제어

var _round_manager: RoundManager
var _board: Board
var _hud: HUD
var _status: StatusBanner
var _go_stop_popup: GoStopPopup

var _current_score: int = 0
var _last_played_node: CardNode = null


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

	_go_stop_popup = GoStopPopup.new()
	add_child(_go_stop_popup)

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

	_go_stop_popup.stop_pressed.connect(func() -> void: _round_manager.choose_stop())
	_go_stop_popup.go_pressed.connect(func() -> void: _round_manager.choose_go())


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
	_status.set_text("손패에서 패를 선택하세요")


func _on_turn_started(turn_number: int, max_turns: int) -> void:
	_hud.update_turn(turn_number, max_turns)
	_status.set_text("손패에서 패를 선택하세요")


func _on_hand_matched(result: Matching.MatchResult) -> void:
	_board.clear_highlights()
	_remove_played_node()
	_board.refresh_floor(_round_manager._floor)
	_board.update_collected(_round_manager._collected)
	if result.is_ssok:
		_hud.show_chain("쪽!")
	_show_score_delta()
	_refresh_score()


func _on_hand_placed(_card: CardData.Card) -> void:
	_board.clear_highlights()
	_remove_played_node()
	_board.refresh_floor(_round_manager._floor)


func _on_mountain_matched(result: Matching.MatchResult, _chain_count: int, _multiplier: float) -> void:
	_board.animate_mountain_flip(result.hand_card, true)
	_board.refresh_floor(_round_manager._floor)
	_board.update_mountain_count(_round_manager._mountain.size())
	_board.update_collected(_round_manager._collected)

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
	_status.set_text("목표 달성! 고 또는 스톱을 선택하세요")
	_go_stop_popup.show_popup(current_score, target_score, _round_manager._go_stop)


func _on_go_stop_resolved(decision: GoStop.Decision, _go_count: int, multiplier: float) -> void:
	_go_stop_popup.hide_popup()
	if decision == GoStop.Decision.GO:
		_hud.show_chain("고! (×%s)" % _mult_str(multiplier))
		_status.set_text("손패에서 패를 선택하세요")


func _on_go_failed(_penalty: Dictionary) -> void:
	_hud.show_chain("고 실패...")
	_status.flash("고 실패! 패널티가 적용됩니다", 2.0)
	_hud.update_score(0)


func _on_round_complete(final_score: int, coins_earned: int) -> void:
	_hud.update_coins(GameManager.current_run.total_coins)
	if GameManager.current_run.round_number < 13:
		_go_to_shop(final_score)


# ── Board 신호 핸들러 ────────────────────────────────────

func _on_hand_card_selected(card_node: CardNode) -> void:
	if _round_manager.state != RoundManager.State.PLAYER_TURN_A:
		_board.clear_selection()
		return
	_last_played_node = card_node
	# 해당 월 바닥 카드 하이라이트
	_board.highlight_matching_floor(card_node.card_data.month)
	_round_manager.select_hand_card(card_node.card_data)


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


## 점수 변화 팝업 (매칭 직후 델타 표시)
func _show_score_delta() -> void:
	var ki_cards: Array = GameManager.current_run.ki_cards
	var breakdown := Scoring.calculate_with_ki(_round_manager._collected, ki_cards)
	var mult := _round_manager._go_stop.get_score_multiplier()
	var new_score := int(breakdown.total_score * mult)
	var delta := new_score - _current_score
	if delta > 0:
		# 화면 중앙 바닥 영역 근처에 스폰
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
