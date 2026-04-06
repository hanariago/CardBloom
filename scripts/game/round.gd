extends Node2D

## 라운드 씬 루트 — 모든 시스템 배선 및 게임 진행 제어

var _round_manager: RoundManager
var _board: Board
var _hud: HUD
var _go_stop_popup: GoStopPopup

var _current_score: int = 0
var _go_stop_state: GoStop = GoStop.new()


func _ready() -> void:
	_build_scene()
	_connect_signals()
	_start_round()


func _build_scene() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.10, 0.18)  # 밤 골목 남색
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	# 보드
	_board = Board.new()
	add_child(_board)

	# HUD (CanvasLayer)
	_hud = HUD.new()
	add_child(_hud)
	_hud.screen_shake_target = _board  # 화면 흔들림 대상

	# 고/스톱 팝업
	_go_stop_popup = GoStopPopup.new()
	add_child(_go_stop_popup)

	# 라운드 매니저
	_round_manager = RoundManager.new()
	add_child(_round_manager)


func _connect_signals() -> void:
	# RoundManager → UI
	_round_manager.dealing_complete.connect(_on_dealing_complete)
	_round_manager.turn_started.connect(_on_turn_started)
	_round_manager.hand_matched.connect(_on_hand_matched)
	_round_manager.hand_placed.connect(_on_hand_placed)
	_round_manager.mountain_matched.connect(_on_mountain_matched)
	_round_manager.mountain_placed.connect(_on_mountain_placed)
	_round_manager.cards_collected.connect(_on_cards_collected)
	_round_manager.scoring_complete.connect(_on_scoring_complete)
	_round_manager.goal_reached.connect(_on_goal_reached)
	_round_manager.go_stop_resolved.connect(_on_go_stop_resolved)
	_round_manager.go_failed.connect(_on_go_failed)
	_round_manager.round_complete.connect(_on_round_complete)

	# Board → RoundManager
	_board.hand_card_clicked.connect(_on_hand_card_selected)

	# GoStopPopup → RoundManager
	_go_stop_popup.stop_pressed.connect(_on_stop_pressed)
	_go_stop_popup.go_pressed.connect(_on_go_pressed)


func _start_round() -> void:
	var target := GameManager.get_round_target_score()
	_hud.update_target(target)
	_hud.update_coins(GameManager.current_run.total_coins if GameManager.current_run else 0)
	_round_manager.start_round(target)


# ── RoundManager 신호 핸들러 ─────────────────────────

func _on_dealing_complete(hand: Array, floor: Array, mountain_count: int) -> void:
	_board.setup_initial(hand, floor, mountain_count)
	_hud.update_score(0)


func _on_turn_started(turn_number: int, max_turns: int) -> void:
	_hud.update_turn(turn_number, max_turns)


func _on_hand_matched(result: Matching.MatchResult) -> void:
	_board.clear_selection()
	# 쪽이면 특별 효과 (추후 확장)
	if result.is_ssok:
		_hud.show_chain("쪽!")


func _on_hand_placed(_card: CardData.Card) -> void:
	_board.clear_selection()


func _on_mountain_matched(result: Matching.MatchResult, chain_count: int, multiplier: float) -> void:
	_board.animate_mountain_flip(result.hand_card, true)
	_board.update_mountain_count(_round_manager._mountain.size())

	# 연쇄 텍스트
	var label := _round_manager._chain.get_label()
	if not label.is_empty():
		_hud.show_chain(label)

	_refresh_score()


func _on_mountain_placed(card: CardData.Card) -> void:
	_board.animate_mountain_flip(card, false)
	_board.update_mountain_count(_round_manager._mountain.size())


func _on_cards_collected(_cards: Array, _is_ssok: bool, _chain_label: String) -> void:
	_board.update_collected(_round_manager._collected)
	_refresh_score()


func _on_scoring_complete(breakdown: Scoring.ScoreBreakdown, multiplier: float, final_score: int) -> void:
	_hud.update_score(final_score)
	_current_score = final_score


func _on_goal_reached(current_score: int, target_score: int) -> void:
	_current_score = current_score
	_go_stop_state = _round_manager._go_stop
	_go_stop_popup.show_popup(current_score, target_score, _go_stop_state)


func _on_go_stop_resolved(decision: GoStop.Decision, go_count: int, multiplier: float) -> void:
	_go_stop_popup.hide_popup()
	if decision == GoStop.Decision.GO:
		_hud.show_chain("고! (×%s)" % _mult_str(multiplier))


func _on_go_failed(penalty: Dictionary) -> void:
	_hud.show_chain("고 실패...")
	_hud.update_score(0)


func _on_round_complete(final_score: int, coins_earned: int) -> void:
	_hud.update_coins(GameManager.current_run.total_coins if GameManager.current_run else 0)
	# TODO: M2 — 다음 판으로 이동 또는 상점 씬 전환


# ── Board 신호 핸들러 ────────────────────────────────

func _on_hand_card_selected(card_node: CardNode) -> void:
	if _round_manager.state != RoundManager.State.PLAYER_TURN_A:
		return
	_round_manager.select_hand_card(card_node.card_data)


# ── GoStop 팝업 핸들러 ───────────────────────────────

func _on_stop_pressed() -> void:
	_round_manager.choose_stop()


func _on_go_pressed() -> void:
	_round_manager.choose_go()


# ── 헬퍼 ────────────────────────────────────────────

func _refresh_score() -> void:
	var breakdown := Scoring.calculate(_round_manager._collected)
	var mult := _round_manager._go_stop.get_score_multiplier()
	var score := int(breakdown.total_score * mult)
	_hud.update_score(score)
	_current_score = score


func _mult_str(mult: float) -> String:
	return str(int(mult)) if mult == int(mult) else "%.1f" % mult
