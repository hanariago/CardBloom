extends Node

## 게임 전체 상태 관리 오토로드

# 런 상태
var current_run: RunState = null

# 신호
signal round_started(round_number: int)
signal round_ended(score: int, coins_earned: int)
signal run_completed(success: bool)


class RunState:
	var round_number: int = 1          # 현재 판 번호 (1~13)
	var total_coins: int = 0           # 보유 엽전
	var ki_cards: Array = []           # 장착 기운 카드 (최대 5)
	var ascension_level: int = 0       # 어센션 단계
	var high_score: int = 0            # 이번 런 최고 점수

	func _init() -> void:
		round_number = 1
		total_coins = 3
		ki_cards = []
		ascension_level = 0
		high_score = 0


func _ready() -> void:
	pass


## 새 런 시작
func start_new_run() -> void:
	current_run = RunState.new()


## 현재 판 목표 점수 계산
## 1판: 60점 (삼광 75 or 2광+족보 조합으로 달성 가능)
## 매 판 ×1.4 상승
func get_round_target_score() -> int:
	if current_run == null:
		return 60
	var base := 60
	var multiplier := 1.4
	return int(base * pow(multiplier, current_run.round_number - 1))


## 초과 점수 → 엽전 변환
## 변환율은 플레이테스트 후 조정 예정
func convert_score_to_coins(excess_score: int) -> int:
	var conversion_rate := 0.2
	return max(0, int(excess_score * conversion_rate))


## 엽전 추가
func add_coins(amount: int) -> void:
	if current_run != null:
		current_run.total_coins += amount


## 엽전 소비 (부족하면 false 반환)
func spend_coins(amount: int) -> bool:
	if current_run == null or current_run.total_coins < amount:
		return false
	current_run.total_coins -= amount
	return true
