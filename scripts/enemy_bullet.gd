extends Area2D

var velocity := Vector2.ZERO
var life := 2.2

func _ready():
	rotation = velocity.angle() + PI / 2.0
	body_entered.connect(_on_hit)
	get_tree().create_timer(life).timeout.connect(queue_free)

func _physics_process(delta):
	global_position += velocity * delta

func _on_hit(body):
	if body.is_in_group("player"):
		get_tree().call_group("player_controller", "damage_player", 1, global_position)
	queue_free()
