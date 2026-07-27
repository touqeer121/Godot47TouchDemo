extends Area2D

var velocity := Vector2.ZERO
var exploded := false

const GRAVITY := 1500.0
const FUSE := 1.1
const RADIUS := 220.0
const DAMAGE := 3

func _ready():
	body_entered.connect(_on_hit)
	get_tree().create_timer(FUSE).timeout.connect(_explode)

func _physics_process(delta):
	velocity.y += GRAVITY * delta
	global_position += velocity * delta
	rotation += 9.0 * delta

func _on_hit(_body):
	_explode()

func _explode():
	if exploded:
		return
	exploded = true
	get_tree().call_group("player_controller", "explode", global_position, RADIUS, DAMAGE)
	queue_free()
