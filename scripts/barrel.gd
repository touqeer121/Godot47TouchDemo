extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var col: CollisionShape2D = $CollisionShape2D

var health := 3
var exploding := false

const RADIUS := 220.0
const DAMAGE := 4

func _ready():
	add_to_group("destructible")

func take_damage(amount: int, _from_pos: Vector2 = Vector2.ZERO):
	if exploding:
		return
	health -= amount
	_flash()
	if health <= 0:
		_trigger()

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
