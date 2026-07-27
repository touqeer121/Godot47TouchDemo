extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D

var health := 3

const DEBRIS_COLOR := Color(0.54, 0.35, 0.17)

func _ready():
	add_to_group("destructible")

func take_damage(amount: int, _from_pos: Vector2 = Vector2.ZERO):
	health -= amount
	if health <= 0:
		get_tree().call_group("player_controller", "spawn_debris", global_position, DEBRIS_COLOR, 6)
		get_tree().call_group("player_controller", "play_sfx", "hit")
		queue_free()
	else:
		sprite.modulate = Color(2.4, 2.4, 2.4)
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)
