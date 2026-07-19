extends Node2D

@onready var sprite=$Sprite2D
var speed:=300.0
var left:=false
var right:=false

var velocity_y:=0.0
var is_jumping:=false
var ground_y:float
var base_scale:Vector2

const GRAVITY:=2200.0
const JUMP_FORCE:=-900.0

func _ready():
	ground_y = sprite.position.y
	base_scale = sprite.scale

func _process(delta):
	if left:
		sprite.position.x -= speed*delta
	if right:
		sprite.position.x += speed*delta

	if is_jumping:
		velocity_y += GRAVITY*delta
		sprite.position.y += velocity_y*delta
		if sprite.position.y >= ground_y:
			sprite.position.y = ground_y
			velocity_y = 0.0
			is_jumping = false
			_squash_land()

func _on_left_down(): left=true
func _on_left_up(): left=false
func _on_right_down(): right=true
func _on_right_up(): right=false

func _on_jump_down():
	if is_jumping:
		return
	is_jumping = true
	velocity_y = JUMP_FORCE
	_squash_launch()

func _squash_launch():
	var tween := create_tween()
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.7, 1.3), 0.08)
	tween.tween_property(sprite, "scale", base_scale, 0.15).set_trans(Tween.TRANS_SINE)

func _squash_land():
	var tween := create_tween()
	tween.tween_property(sprite, "scale", base_scale * Vector2(1.35, 0.65), 0.06)
	tween.tween_property(sprite, "scale", base_scale, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
