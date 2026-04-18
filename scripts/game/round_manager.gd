class_name RoundManager
extends Node

## 한 판(라운드) 진행 상태머신
## 딜링 → 턴A(손패 내리기) → 턴B(산패 뒤집기) → 정산 → 고/스톱

enum State {
	IDLE,
	DEALING,
	PLAYER_TURN_A,    # 손패 1장 선택 대기
	RESOLVING_A,      # 턴A 매칭 처리 중 (애니메이션 대기)
	PLAYER_TURN_B,    # 산패 자동 뒤집기
	RESOLVING_B,      # 턴B 매칭 처리 중
	SCORING,          # 10턴 후 점수 계산
	GO_STOP_CHOICE,   # 목표 점수 달성 → 고/스톱 선택 대기
	COMPLETE          # 판 종료
}

# ── 신호 ──────────────────────────────────────────────
signal dealing_complete(hand: Array, floor: Array, mountain_count: int)
signal turn_started(turn_number: int, max_turns: int)

## 손패 매칭 결과
signal hand_matched(result: Matching.MatchResult)       # 매칭 성공 (쪽 포함)
signal hand_placed(card: CardData.Card)                 # 매칭 없이 바닥에 놓임

## 산패 뒤집기 결과
signal mountain_matched(result: Matching.MatchResult, chain_count: int, multiplier: float)
signal mountain_placed(card: CardData.Card)             # 매칭 없이 바닥에 놓임

## 카드 수집
signal cards_collected(cards: Array, is_ssok: bool, chain_label: String)

## 정산
signal scoring_complete(breakdown: Scoring.ScoreBreakdown, go_multiplier: float, final_score: int)
signal goal_reached(current_score: int, target_score: int)

## 고/스톱
signal go_stop_resolved(decision: GoStop.Decision, go_count: int, multiplier: float)
signal go_failed(penalty: Dictionary)

signal round_complete(final_score: int, coins_earned: int)
signal flower_rain_triggered(month: int)   # 꽃비 발동 — board에서 연출 재생

# ── 상태 ──────────────────────────────────────────────
var state: State = State.IDLE

var _deck: Array[CardData.Card] = []
var _hand: Array[CardData.Card] = []         # 손패
var _floor: Array[CardData.Card] = []        # 바닥 패
var _mountain: Array[CardData.Card] = []     # 산패 더미

var _collected: Dictionary = {
	"gwang":  [],
	"ribbon": [],
	"animal": [],
	"pi":     []
}

var _turn_number: int = 0
var _base_max_turns: int = 10
var _max_turns: int = 10

var _go_stop: GoStop = GoStop.new()
var _chain: ChainBonus = ChainBonus.new()

var _target_score: int = 0
var _goal_reached_this_round: bool = false
var flower_rain_month: int = -1   # 이번 판 꽃비 발동 월 (−1이면 미발동)


# ── 공개 API ──────────────────────────────────────────

## 판 시작
func start_round(target_score: int) -> void:
	_target_score = target_score
	_reset_state()
	_deal()


## 손패에서 카드 선택 (UI에서 호출)
func select_hand_card(card: CardData.Card) -> void:
	if state != State.PLAYER_TURN_A:
		return
	if not _hand.has(card):
		return

	state = State.RESOLVING_A
	_hand.erase(card)

	var result := Matching.play_hand_card(card, _floor)
	_floor = Matching.apply_match_to_floor(result, _floor)

	if result.matched:
		_collect(result.hand_card, result.floor_cards)
		hand_matched.emit(result)
	else:
		hand_placed.emit(card)

	# 쪽이면 턴 즉시 계속, 아니면 턴B로
	_proceed_to_turn_b()


## 고/스톱 선택 (UI에서 호출)
func choose_go() -> void:
	if state != State.GO_STOP_CHOICE:
		return
	if not _go_stop.can_go():
		return

	_go_stop.choose_go()
	_max_turns = _base_max_turns + _go_stop.get_extra_turns()

	go_stop_resolved.emit(
		GoStop.Decision.GO,
		_go_stop.go_count,
		_go_stop.get_score_multiplier()
	)

	_goal_reached_this_round = false
	state = State.PLAYER_TURN_A
	turn_started.emit(_turn_number + 1, _max_turns)


func choose_stop() -> void:
	if state != State.GO_STOP_CHOICE:
		return

	_go_stop.choose_stop()
	go_stop_resolved.emit(
		GoStop.Decision.STOP,
		_go_stop.go_count,
		_go_stop.get_score_multiplier()
	)
	_finalize_round()


# ── 내부 로직 ─────────────────────────────────────────

func _reset_state() -> void:
	state = State.IDLE
	_hand.clear()
	_floor.clear()
	_mountain.clear()
	_collected = {"gwang": [], "ribbon": [], "animal": [], "pi": []}
	_turn_number = 0
	_base_max_turns = 10
	_max_turns = 10
	_goal_reached_this_round = false
	flower_rain_month = -1
	_go_stop.reset()
	_chain.reset()


func _deal() -> void:
	state = State.DEALING

	_deck = CardData.shuffle_deck(CardData.create_deck())

	# 손패 10장
	for i in 10:
		_hand.append(_deck[i])
	# 바닥 8장
	for i in 8:
		_floor.append(_deck[10 + i])
	# 나머지 산패
	for i in range(18, _deck.size()):
		_mountain.append(_deck[i])

	# 꽃비 판정 (dealing_complete 전 — 업데이트된 바닥 패 포함해서 전달)
	_roll_flower_rain()

	dealing_complete.emit(_hand.duplicate(), _floor.duplicate(), _mountain.size())

	# 꽃비 발동 시 연출 신호 + 애니메이션 대기
	if flower_rain_month != -1:
		flower_rain_triggered.emit(flower_rain_month)
		await get_tree().create_timer(2.8).timeout

	_start_turn()


## 꽃비 판정 — 17% 확률로 산패에서 랜덤 월 1장을 바닥에 추가
func _roll_flower_rain() -> void:
	if randf() > 0.17:
		return
	var available_months: Array[int] = []
	for card in _mountain:
		if card.month not in available_months:
			available_months.append(card.month)
	if available_months.is_empty():
		return
	var chosen_month: int = available_months[randi() % available_months.size()]
	for i in _mountain.size():
		if _mountain[i].month == chosen_month:
			_floor.append(_mountain[i])
			_mountain.remove_at(i)
			flower_rain_month = chosen_month
			return


func _start_turn() -> void:
	_turn_number += 1
	state = State.PLAYER_TURN_A
	turn_started.emit(_turn_number, _max_turns)


## 산패 뒤집기 직전 신호 — UI에서 "산패 뒤집는 중..." 표시용
signal mountain_flip_pending()

func _proceed_to_turn_b() -> void:
	if _mountain.is_empty():
		_end_turn()
		return

	state = State.PLAYER_TURN_B
	mountain_flip_pending.emit()
	# 0.55초 대기 → 손패 결과를 읽을 시간 + 산패 페이즈 구분
	await get_tree().create_timer(0.55).timeout
	_flip_mountain()


func _flip_mountain() -> void:
	var mountain_card := _mountain.pop_front() as CardData.Card
	var result := Matching.flip_mountain_card(mountain_card, _floor)
	_floor = Matching.apply_match_to_floor(result, _floor)

	var multiplier := _chain.record_flip(result.matched)
	var chain_count := _chain.get_count()

	if result.matched:
		_collect(mountain_card, result.floor_cards)
		mountain_matched.emit(result, chain_count, multiplier)
		# 연쇄 보너스 엽전
		var bonus_coins := _chain.get_bonus_coins()
		if bonus_coins > 0:
			GameManager.add_coins(bonus_coins)
	else:
		mountain_placed.emit(mountain_card)

	_end_turn()


func _end_turn() -> void:
	var ki_cards: Array = GameManager.current_run.ki_cards if GameManager.current_run else []
	var breakdown := Scoring.calculate_with_ki(_collected, ki_cards, flower_rain_month)
	var current_score := int(breakdown.total_score * _go_stop.get_score_multiplier())

	# 고 중에 목표 달성 못하면 실패 체크 (고 선택 후 추가 턴 소진)
	var is_extra_turn := _turn_number > _base_max_turns
	if is_extra_turn and _go_stop.go_count > 0:
		if _turn_number >= _max_turns and not _goal_reached_this_round:
			_handle_go_fail()
			return

	# 목표 점수 달성 체크
	if not _goal_reached_this_round and current_score >= _target_score:
		_goal_reached_this_round = true
		goal_reached.emit(current_score, _target_score)
		state = State.GO_STOP_CHOICE
		return

	# 10턴(+추가턴) 소진
	if _turn_number >= _max_turns or _hand.is_empty():
		_score_and_end()
		return

	_start_turn()


func _collect(played_card: CardData.Card, floor_cards: Array[CardData.Card]) -> void:
	var all_cards: Array[CardData.Card] = [played_card]
	all_cards.append_array(floor_cards)

	for card in all_cards:
		match card.type:
			CardData.Type.GWANG:
				_collected["gwang"].append(card)
			CardData.Type.RIBBON:
				_collected["ribbon"].append(card)
			CardData.Type.ANIMAL:
				_collected["animal"].append(card)
			CardData.Type.PI, CardData.Type.DOUBLE_PI:
				_collected["pi"].append(card)


func _score_and_end() -> void:
	state = State.SCORING

	var ki_cards: Array = []
	if GameManager.current_run != null:
		ki_cards = GameManager.current_run.ki_cards

	var breakdown := Scoring.calculate_with_ki(_collected, ki_cards, flower_rain_month)
	var multiplier := _go_stop.get_score_multiplier()
	var final_score := int(breakdown.total_score * multiplier)

	scoring_complete.emit(breakdown, multiplier, final_score)

	var target: int = GameManager.get_round_target_score()
	var excess: int = maxi(0, final_score - target)
	var coins: int = GameManager.convert_score_to_coins(excess)
	GameManager.add_coins(coins)

	state = State.COMPLETE
	round_complete.emit(final_score, coins)


func _finalize_round() -> void:
	_score_and_end()


func _handle_go_fail() -> void:
	var penalty := _go_stop.get_fail_penalty()
	go_failed.emit(penalty)

	# 엽전 패널티 적용
	if penalty["coins_penalty"] == -1:
		# 절반 차감
		var half := GameManager.current_run.total_coins / 2
		GameManager.spend_coins(half)

	state = State.COMPLETE
	round_complete.emit(0, 0)
