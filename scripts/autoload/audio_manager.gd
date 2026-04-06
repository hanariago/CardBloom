extends Node

## 사운드 관리 오토로드
## M1: AudioStreamPlayer 노드만 배치, 실제 사운드는 M2 이후 연결

# BGM 플레이어
var _bgm_player: AudioStreamPlayer

# SFX 플레이어 풀 (동시 재생 지원)
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

# 볼륨 설정
var bgm_volume_db: float = -10.0
var sfx_volume_db: float = 0.0

# SFX 키 상수
const SFX_CARD_PLACE  := "card_place"   # 패 내려놓기 "딱"
const SFX_MATCH       := "match"        # 매칭 성공 "짝!"
const SFX_GWANG       := "gwang"        # 광 획득 종소리
const SFX_CHAIN       := "chain"        # 연쇄 매칭
const SFX_SCORE_TICK  := "score_tick"   # 점수 카운터 틱
const SFX_SCORE_BIG   := "score_big"    # 대형 점수 폭발
const SFX_GO          := "go"           # 고 선택
const SFX_STOP        := "stop"         # 스톱 선택
const SFX_GO_SUCCESS  := "go_success"   # 고 성공
const SFX_GO_FAIL     := "go_fail"      # 고 실패


func _ready() -> void:
	_setup_players()


func _setup_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "BGM"
	add_child(_bgm_player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)


## BGM 재생 (스트림 미연결 시 무음)
func play_bgm(stream: AudioStream = null) -> void:
	if stream == null:
		return
	_bgm_player.stream = stream
	_bgm_player.volume_db = bgm_volume_db
	_bgm_player.play()


## BGM 정지
func stop_bgm() -> void:
	_bgm_player.stop()


## SFX 재생 (스트림 미연결 시 무음으로 통과)
func play_sfx(key: String, stream: AudioStream = null) -> void:
	if stream == null:
		return
	var player := _get_free_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = sfx_volume_db
	player.play()


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	return _sfx_players[0]  # 모두 사용 중이면 첫 번째 재사용
