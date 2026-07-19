extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var sprite: Sprite2D = $Player/Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var stars: Sprite2D = $Stars
@onready var rain: GPUParticles2D = $Rain
@onready var left_button: TouchScreenButton = $CanvasLayer/Left
@onready var right_button: TouchScreenButton = $CanvasLayer/Right
@onready var jump_button: TouchScreenButton = $CanvasLayer/Jump
@onready var left_icon: Sprite2D = $CanvasLayer/Left/Icon
@onready var right_icon: Sprite2D = $CanvasLayer/Right/Icon
@onready var jump_icon: Sprite2D = $CanvasLayer/Jump/Icon

var left:=false
var right:=false
var facing:=1
var is_rolling:=false
var jumps_left:=2
var base_scale:Vector2
var scale_tween:Tween
var icon_base_scale:={}
var icon_base_alpha:={}
var icon_tweens:={}
var rain_active:=false
var rain_timer:=0.0
var next_rain_change:=10.0
var bg_y:=0.0

const BG_Y_LERP_SPEED:=1.0
const RAIN_Y_OFFSET:=-480.0

const SPEED:=650.0
const MAX_JUMPS:=2
const GRAVITY:=2200.0
const FALL_GRAVITY_MULT:=1.7
const JUMP_FORCE:=-1235.0
const TILT_ANGLE:=0.21
const TILT_LERP_SPEED:=10.0
const BUTTON_PRESS_ALPHA:=0.55
const EDGE_MARGIN_X:=123.2
const EDGE_MARGIN_Y:=116.8

func _ready():
	base_scale = sprite.scale
	for icon in [left_icon, right_icon, jump_icon]:
		icon_base_scale[icon] = icon.scale
		icon_base_alpha[icon] = icon.modulate.a

	var vp_size := get_viewport().get_visible_rect().size
	left_button.position = Vector2(EDGE_MARGIN_X, vp_size.y - EDGE_MARGIN_Y)
	right_button.position = Vector2(EDGE_MARGIN_X + 170.0, vp_size.y - EDGE_MARGIN_Y)
	jump_button.position = Vector2(vp_size.x - EDGE_MARGIN_X, vp_size.y - EDGE_MARGIN_Y)

	next_rain_change = randf_range(10.0, 20.0)
	bg_y = camera.global_position.y

func _physics_process(delta):
	var was_on_floor := player.is_on_floor()

	player.velocity.x = 0.0
	if left:
		player.velocity.x -= SPEED
		facing = -1
	if right:
		player.velocity.x += SPEED
		facing = 1

	var gravity: float = GRAVITY * (FALL_GRAVITY_MULT if player.velocity.y > 0.0 else 1.0)
	player.velocity.y += gravity * delta

	player.move_and_slide()

	if player.is_on_floor():
		jumps_left = MAX_JUMPS
		if not was_on_floor:
			_squash_land()

	if not is_rolling:
		var target_tilt: float = 0.0
		if left:
			target_tilt = -TILT_ANGLE
		elif right:
			target_tilt = TILT_ANGLE
		sprite.rotation = lerp_angle(sprite.rotation, target_tilt, TILT_LERP_SPEED * delta)

	camera.global_position = player.global_position

	# Background elements pan horizontally with the camera but only slowly
	# drift vertically, so a quick jump doesn't make the sky visibly bob.
	bg_y = lerp(bg_y, camera.global_position.y, BG_Y_LERP_SPEED * delta)
	stars.position = Vector2(camera.global_position.x, bg_y)
	rain.position = Vector2(camera.global_position.x, bg_y + RAIN_Y_OFFSET)

	rain_timer += delta
	if rain_timer >= next_rain_change:
		rain_timer = 0.0
		rain_active = not rain_active
		rain.emitting = rain_active
		next_rain_change = randf_range(5.0, 9.0) if rain_active else randf_range(12.0, 25.0)

func _on_left_down(): left=true; _icon_press(left_icon)
func _on_left_up(): left=false; _icon_release(left_icon)
func _on_right_down(): right=true; _icon_press(right_icon)
func _on_right_up(): right=false; _icon_release(right_icon)
func _on_jump_up(): _icon_release(jump_icon)

func _on_jump_down():
	_icon_press(jump_icon)
	if jumps_left <= 0:
		return
	var is_double := not player.is_on_floor()
	jumps_left -= 1
	player.velocity.y = JUMP_FORCE
	if is_double:
		_squash_double_jump()
	else:
		_squash_launch()

func _icon_press(icon:Sprite2D):
	_tween_icon(icon, icon_base_scale[icon] * 0.82, BUTTON_PRESS_ALPHA, 0.06, false)

func _icon_release(icon:Sprite2D):
	_tween_icon(icon, icon_base_scale[icon], icon_base_alpha[icon], 0.18, true)

func _tween_icon(icon:Sprite2D, target_scale:Vector2, target_alpha:float, duration:float, bounce:bool):
	if icon_tweens.has(icon) and icon_tweens[icon].is_valid():
		icon_tweens[icon].kill()
	var t := create_tween()
	icon_tweens[icon] = t
	t.set_trans(Tween.TRANS_BACK if bounce else Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.set_parallel(true)
	t.tween_property(icon, "scale", target_scale, duration)
	t.tween_property(icon, "modulate:a", target_alpha, duration)

func _start_tween() -> Tween:
	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
	scale_tween = create_tween()
	return scale_tween

func _squash_launch():
	var tween := _start_tween()
	tween.tween_property(sprite, "scale", base_scale * Vector2(1.3, 0.7), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.65, 1.4), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.9, 1.1), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", base_scale, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _squash_double_jump():
	is_rolling = true
	sprite.rotation = 0.0
	var tween := _start_tween()
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.6, 1.45), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "rotation", TAU * facing, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		sprite.rotation = 0.0
		is_rolling = false
	)

func _squash_land():
	sprite.rotation = 0.0
	var tween := _start_tween()
	tween.tween_property(sprite, "scale", base_scale * Vector2(1.45, 0.6), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.85, 1.15), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", base_scale, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
