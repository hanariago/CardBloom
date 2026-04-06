class_name ScoreDisplay
extends Node

## 점수 카운터 주스(Juice) 애니메이션
## 핵심 원칙: 숫자는 항상 "두두두두" 올라감. 최종값 즉시 표시 금지.

signal animation_finished

# 연결된 레이블
var score_label: Label = null
var screen_shake_target: Node2D = null  # 화면 흔들림 적용 대상

var _current_display: int = 0
var _tween: Tween

# 점수 규모별 연출 파라미터
const PARAMS := {
	"small":  {"duration": 0.30, "shake": 0.0, "label_scale": 1.0},   # 1~20
	"medium": {"duration": 0.50, "shake": 1.5, "label_scale": 1.2},   # 21~50
	"large":  {"duration": 0.80, "shake": 3.0, "label_scale": 1.5},   # 51~100
	"huge":   {"duration": 1.50, "shake": 6.0, "label_scale": 2.0},   # 100+
}


## 현재 표시값에서 target으로 카운트업 애니메이션
func animate_to(target: int) -> void:
	if score_label == null:
		return

	var delta := target - _current_display
	if delta <= 0:
		_current_display = target
		score_label.text = str(target)
		animation_finished.emit()
		return

	var tier := _get_tier(delta)
	var params: Dictionary = PARAMS[tier]

	if _tween:
		_tween.kill()

	_tween = score_label.create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# 숫자 카운트업 (인터폴레이션)
	var start := _current_display
	_tween.tween_method(
		func(v: float) -> void:
			score_label.text = str(int(v))
			_current_display = int(v),
		float(start),
		float(target),
		params["duration"]
	)

	# 글자 크기 펌핑
	if params["label_scale"] > 1.0:
		var scale_tween := score_label.create_tween()
		scale_tween.set_parallel(true)
		scale_tween.tween_property(score_label, "scale",
			Vector2.ONE * params["label_scale"], params["duration"] * 0.3
		).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(score_label, "scale",
			Vector2.ONE, params["duration"] * 0.7
		).set_ease(Tween.EASE_IN_OUT).set_delay(params["duration"] * 0.3)

	# 화면 흔들림
	if params["shake"] > 0.0 and screen_shake_target != null:
		_shake(params["shake"], params["duration"] * 0.5)

	# 대형 이상: 금색 글자 전환
	if tier == "large" or tier == "huge":
		_flash_gold(params["duration"])

	_tween.tween_callback(func() -> void:
		_current_display = target
		animation_finished.emit()
	)


## 즉시 값 설정 (애니메이션 없이)
func set_value(value: int) -> void:
	_current_display = value
	if score_label:
		score_label.text = str(value)


func _get_tier(delta: int) -> String:
	if delta <= 20:    return "small"
	elif delta <= 50:  return "medium"
	elif delta <= 100: return "large"
	else:              return "huge"


func _shake(intensity: float, duration: float) -> void:
	if screen_shake_target == null:
		return
	var base_pos := screen_shake_target.position
	var shake_tween := screen_shake_target.create_tween()
	var steps := int(duration / 0.05)
	for i in steps:
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		shake_tween.tween_property(screen_shake_target, "position", base_pos + offset, 0.05)
	shake_tween.tween_property(screen_shake_target, "position", base_pos, 0.05)


func _flash_gold(duration: float) -> void:
	if score_label == null:
		return
	var original_color := score_label.modulate
	var flash_tween := score_label.create_tween()
	flash_tween.tween_property(score_label, "modulate",
		Color(0.79, 0.66, 0.30), duration * 0.2
	)
	flash_tween.tween_property(score_label, "modulate",
		original_color, duration * 0.8
	)
