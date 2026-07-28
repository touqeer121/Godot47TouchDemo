extends RigidBody2D

# An explosive barrel. Very heavy: sits as a solid static prop until a nearby
# blast disturbs it, then it mostly just topples sideways (it won't get shoved
# around like a crate). Shooting it detonates it and chains to its neighbours.

@onready var sprite: Sprite2D = $Sprite2D
@onready var col: CollisionShape2D = $CollisionShape2D

var health := 3
var exploding := false
var active := false

const RADIUS := 220.0
const DAMAGE := 4

func _ready():
	add_to_group("destructible")

func activate():
	if active:
		return
	active = true
	freeze = false
	sleeping = false

func take_damage(amount: int, _from_pos: Vector2 = Vector2.ZERO):
	if exploding:
		return
	health -= amount
	_flash()
	if health <= 0:
		_trigger()
	else:
		activate()

# Nudge from a nearby explosion: wake and topple. Heavy, so it barely slides.
func apply_blast(from: Vector2, radius: float):
	if exploding:
		return
	activate()
	var away := (global_position - from)
	var falloff: float = clampf(1.0 - away.length() / (radius * 2.0), 0.15, 1.0)
	if away.length() < 1.0:
		away = Vector2.UP
	apply_central_impulse(away.normalized() * 900.0 * falloff)
	apply_torque_impulse(signf(away.x) * 26000.0 * falloff)

func _trigger():
	if exploding:
		return
	exploding = true
	col.set_deferred("disabled", true)
	# Small random delay so chains cascade rather than detonating all at once.
	get_tree().create_timer(randf_range(0.03, 0.12)).timeout.connect(_boom)

func _boom():
	get_tree().call_group("player_controller", "explode", global_position, RADIUS, DAMAGE)
	queue_free()

func _flash():
	sprite.modulate = Color(3.0, 3.0, 3.0)
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)
