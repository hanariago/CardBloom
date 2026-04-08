class_name StatusBanner
extends CanvasLayer

## 게임 상태 텍스트 배너 — 화면 상단 HUD 아래에 표시

var _label: Label
var _bg: ColorRect
var _fade_tween: Tween


func _ready() -> void:
	layer = 5  # HUD 위에

	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.05, 0.12, 0.75)
	_bg.size = Vector2(600, 44)
	_bg.position = Vector2(660, 68)
	add_child(_bg)

	_label = Label.new()
	_label.size = Vector2(600, 44)
	_label.position = Vector2(660, 68)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75))
	add_child(_label)

	# 폰트 적용 (UITheme autoload)
	UITheme.apply_pretendard(_label, 22)


## 상태 텍스트 즉시 변경
func set_text(text: String) -> void:
	_label.text = text
	_bg.visible = not text.is_empty()
	_label.visible = not text.is_empty()
	_label.modulate.a = 1.0
	_bg.modulate.a = 1.0


## 잠깐 표시 후 페이드 아웃 (고/스톱 알림 등)
func flash(text: String, duration: float = 1.2) -> void:
	set_text(text)
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_interval(duration)
	_fade_tween.tween_property(_label, "modulate:a", 0.0, 0.4)
	_fade_tween.parallel().tween_property(_bg, "modulate:a", 0.0, 0.4)
	_fade_tween.tween_callback(func() -> void:
		_label.text = ""
		_label.visible = false
		_bg.visible = false
	)
