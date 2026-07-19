extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var sprite: Sprite2D = $Player/Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var left_button: TouchScreenButton = $CanvasLayer/Left
@onready var right_button: TouchScreenButton = $CanvasLayer/Right
@onready var jump_button: TouchScreenButton = $CanvasLayer/Jump

var left:=false
var right:=false
var jumps_left:=2
var base_scale:Vector2
var scale_tween:Tween
var button_base_scale:={}
var button_base_alpha:={}
var button_tweens:={}

const BUTTON_PRESS_ALPHA:=0.55

const SPEED:=300.0
const MAX_JUMPS:=2
const GRAVITY:=2200.0
const FALL_GRAVITY_MULT:=1.7
const JUMP_FORCE:=-950.0

func _ready():
	base_scale = sprite.scale
	for b in [left_button, right_button, jump_button]:
		button_base_scale[b] = b.scale
		button_base_alpha[b] = b.modulate.a

func _physics_process(delta):
	var was_on_floor := player.is_on_floor()

	player.velocity.x = 0.0
	if left:
		player.velocity.x -= SPEED
	if right:
		player.velocity.x += SPEED

	var gravity: float = GRAVITY * (FALL_GRAVITY_MULT if player.velocity.y > 0.0 else 1.0)
	player.velocity.y += gravity * delta

	player.move_and_slide()

	if player.is_on_floor():
		jumps_left = MAX_JUMPS
		if not was_on_floor:
			_squash_land()

	camera.global_position = player.global_position

func _on_left_down(): left=true; _button_press(left_button)
func _on_left_up(): left=false; _button_release(left_button)
func _on_right_down(): right=true; _button_press(right_button)
func _on_right_up(): right=false; _button_release(right_button)
func _on_jump_up(): _button_release(jump_button)

func _on_jump_down():
	_button_press(jump_button)
	if jumps_left <= 0:
		return
	var is_double := not player.is_on_floor()
	jumps_left -= 1
	player.velocity.y = JUMP_FORCE
	if is_double:
		_squash_double_jump()
	else:
		_squash_launch()

func _button_press(b:TouchScreenButton):
	_tween_button(b, button_base_scale[b] * 0.82, BUTTON_PRESS_ALPHA, 0.06, false)

func _button_release(b:TouchScreenButton):
	_tween_button(b, button_base_scale[b], button_base_alpha[b], 0.18, true)

func _tween_button(b:TouchScreenButton, target_scale:Vector2, target_alpha:float, duration:float, bounce:bool):
	if button_tweens.has(b) and button_tweens[b].is_valid():
		button_tweens[b].kill()
	var t := create_tween()
	button_tweens[b] = t
	t.set_trans(Tween.TRANS_BACK if bounce else Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.set_parallel(true)
	t.tween_property(b, "scale", target_scale, duration)
	t.tween_property(b, "modulate:a", target_alpha, duration)

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
	sprite.rotation = 0.0
	var tween := _start_tween()
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.6, 1.45), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "rotation", TAU, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): sprite.rotation = 0.0)

func _squash_land():
	sprite.rotation = 0.0
	var tween := _start_tween()
	tween.tween_property(sprite, "scale", base_scale * Vector2(1.45, 0.6), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.85, 1.15), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", base_scale, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
