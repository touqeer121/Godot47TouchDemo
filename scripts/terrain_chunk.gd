extends StaticBody2D

# A destructible piece of platform. Bullets chip it, explosions blow it away,
# melee gouges it. Set by the builder before it enters the tree.
var health := 4
var debris_color := Color(0.98, 0.75, 0.35)

func _ready():
	add_to_group("destructible")
	add_to_group("terrain")

func take_damage(amount: int, _from_pos: Vector2 = Vector2.ZERO):
	health -= amount
	if health <= 0:
		get_tree().call_group("player_controller", "spawn_debris", global_position, debris_color, 5)
		queue_free()
