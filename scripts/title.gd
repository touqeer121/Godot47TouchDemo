extends Node2D

const COL_CORAL := Color(1.0, 0.30, 0.38)
const COL_MINT := Color(0.34, 0.85, 0.80)
const COL_GOLD := Color(0.98, 0.75, 0.35)
const COL_TEXT := Color(0.92, 0.94, 1.0)

var title_group: Node2D
var prompt: Label
var started := false

func _ready():
	var vp := get_viewport().get_visible_rect().size

	title_group = Node2D.new()
	title_group.position = Vector2(vp.x / 2.0, vp.y * 0.40)
	add_child(title_group)

	# Labels are 900px wide with centered text; position is the box's top-left,
	# so subtract half the width from the intended center x.
	var killer := _make_label("KILLER", 132, COL_CORAL)
	killer.position = Vector2(-450, -150)
	title_group.add_child(killer)

	var godot := _make_label("GODOT", 132, COL_MINT)
	godot.position = Vector2(-450, -10)
	title_group.add_child(godot)

	var tagline := _make_label("survive the swarm", 30, COL_GOLD)
	tagline.position = Vector2(vp.x / 2.0 - 450.0, vp.y * 0.40 + 150.0)
	add_child(tagline)

	prompt = _make_label("TAP  TO  START", 40, COL_TEXT)
	prompt.position = Vector2(vp.x / 2.0 - 450.0, vp.y * 0.82)
	add_child(prompt)

	# Gentle idle pulse on the title.
	var t := create_tween().set_loops()
	t.tween_property(title_group, "scale", Vector2(1.05, 1.05), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(title_group, "scale", Vector2(1.0, 1.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Blinking prompt.
	var b := create_tween().set_loops()
	b.tween_property(prompt, "modulate:a", 0.25, 0.6).set_trans(Tween.TRANS_SINE)
	b.tween_property(prompt, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

	# Entrance drop.
	title_group.modulate.a = 0.0
	var e := create_tween()
	e.tween_property(title_group, "modulate:a", 1.0, 0.6)
	e.parallel().tween_property(title_group, "position:y", vp.y * 0.40, 0.6).from(vp.y * 0.40 - 80.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _make_label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", maxi(6, size / 5))
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.09, 0.95))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("shadow_offset_x", 4)
	l.add_theme_constant_override("shadow_offset_y", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(900, size + 20)
	return l

func _unhandled_input(event):
	if started:
		return
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		started = true
		var t := create_tween()
		t.tween_property($".", "modulate:a", 0.0, 0.35)
		t.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
