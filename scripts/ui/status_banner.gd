class_name StatusBanner
extends CanvasLayer

## 게임 상태 텍스트 배너 — HUD 바로 아래, 전폭 표시

var _label: Label
var _bg: ColorRect
var _fade_tween: Tween


func _ready() -> void:
	layer = 5

	_bg = ColorRect.new()
	_bg.color = Color(0.04, 0.04, 0.12, 0.88)
	_bg.size = Vector2(1920, 54)
	_bg.position = Vector2(0, 62)
	add_child(_bg)

	_label = Label.new()
	_label.size = Vector2(1920, 54)
	_label.position = Vector2(0, 62)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(0.98, 0.93, 0.72))
	UITheme.apply_pretendard(_label, 26)
	add_child(_label)

	_bg.visible = false
	_label.visible = false


func set_text(text: String) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_label.text = text
	var show := not text.is_empty()
	_bg.visible = show
	_label.visible = show
	_label.modulate.a = 1.0
	_bg.modulate.a = 1.0


func flash(text: String, duration: float = 1.5) -> void:
	set_text(text)
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_interval(duration)
	_fade_tween.tween_property(_label, "modulate:a", 0.0, 0.45)
	_fade_tween.parallel().tween_property(_bg, "modulate:a", 0.0, 0.45)
	_fade_tween.tween_callback(func() -> void:
		_label.text = ""
		_label.visible = false
		_bg.visible = false
	)
