extends RigidBody2D

# A crate. Acts as a solid static prop (frozen) until disturbed by a shot or a
# nearby blast, then unfreezes and tumbles with real physics. Light: nudged
# around easily once loose.

@onready var sprite: Sprite2D = $Sprite2D

var health := 3
var active := false

const DEBRIS_COLOR := Color(0.54, 0.35, 0.17)

func _ready():
	add_to_group("destructible")

# Unfreeze so the crate falls / topples / can be pushed.
func activate():
	if active:
		return
	active = true
	freeze = false
	sleeping = false

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
		activate()   # a solid hit that doesn't shatter it knocks it loose

# Shockwave from a nearby explosion: wake up and get flung away from the blast.
func apply_blast(from: Vector2, radius: float):
	activate()
	var away := (global_position - from)
	var falloff: float = clampf(1.0 - away.length() / (radius * 2.0), 0.15, 1.0)
	if away.length() < 1.0:
		away = Vector2.UP
	apply_central_impulse(away.normalized() * 520.0 * falloff)
	apply_torque_impulse(randf_range(-1.0, 1.0) * 9000.0 * falloff)
