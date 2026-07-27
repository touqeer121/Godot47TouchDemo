extends Area2D

@export var kind := "health"

const HEART := preload("res://heart.svg")
const CIRCLE := preload("res://button.svg")

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: Sprite2D = $Glow

func _ready():
	add_to_group("pickups")
	body_entered.connect(_on_body)
	if kind == "health":
		sprite.texture = HEART
		sprite.modulate = Color(0.45, 1.0, 0.55)
		sprite.scale = Vector2(0.5, 0.5)
		glow.modulate = Color(0.4, 1.0, 0.5, 0.35)
	else:
		sprite.texture = CIRCLE
		sprite.modulate = Color(1.0, 0.62, 0.2)
		sprite.scale = Vector2(0.5, 0.5)
		glow.modulate = Color(1.0, 0.6, 0.2, 0.4)
	var t := create_tween().set_loops()
	t.tween_property(sprite, "position:y", -9.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(sprite, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body(body):
	if body.is_in_group("player"):
		get_tree().call_group("player_controller", "collect_pickup", kind, global_position)
		queue_free()
