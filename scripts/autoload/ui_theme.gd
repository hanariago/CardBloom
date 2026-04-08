extends Node

## 폰트 캐시 Autoload — 모든 노드가 UITheme.font_* 로 접근

var font_pretendard: FontFile
var font_serif: FontFile
var font_serif_bold: FontFile


func _ready() -> void:
	font_pretendard  = load("res://assets/fonts/PretendardVariable.ttf")
	font_serif       = load("res://assets/fonts/SourceHanSerifKR-Regular.otf")
	font_serif_bold  = load("res://assets/fonts/SourceHanSerifKR-Bold.otf")


## Label에 Pretendard 폰트 + 크기 적용
func apply_pretendard(label: Label, size: int) -> void:
	label.add_theme_font_override("font", font_pretendard)
	label.add_theme_font_size_override("font_size", size)


## Label에 본명조 폰트 + 크기 적용
func apply_serif(label: Label, size: int, bold: bool = false) -> void:
	var f := font_serif_bold if bold else font_serif
	label.add_theme_font_override("font", f)
	label.add_theme_font_size_override("font_size", size)
