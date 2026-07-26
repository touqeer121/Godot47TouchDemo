extends Area2D

var velocity := Vector2.ZERO
var life := 1.2

func _ready():
	# small_bullet.png points up by default; aim its tip along travel direction.
	rotation = velocity.angle() + PI / 2.0
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(life).timeout.connect(queue_free)

func _physics_process(delta):
	global_position += velocity * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(1, global_position)
	queue_free()
