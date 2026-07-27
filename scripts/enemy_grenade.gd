extends Area2D

var velocity := Vector2.ZERO
var exploded := false

const GRAVITY := 1400.0
const FUSE := 1.4
const RADIUS := 200.0

func _ready():
	body_entered.connect(_on_hit)
	get_tree().create_timer(FUSE).timeout.connect(_explode)

func _physics_process(delta):
	velocity.y += GRAVITY * delta
	global_position += velocity * delta
	rotation += 8.0 * delta

func _on_hit(body):
	if body.is_in_group("player"):
		_explode()

func _explode():
	if exploded:
		return
	exploded = true
	get_tree().call_group("player_controller", "enemy_explode", global_position, RADIUS)
	queue_free()
