extends Area2D

var velocity := Vector2.ZERO
var exploded := false

const GRAVITY := 1500.0
const FUSE := 1.1
const GLOW := preload("res://light_glow.svg")

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

	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var fx := Sprite2D.new()
	fx.texture = GLOW
	fx.material = mat
	fx.modulate = Color(1.0, 0.7, 0.3, 1.0)
	fx.scale = Vector2(0.3, 0.3)
	fx.global_position = global_position
	get_parent().add_child(fx)

	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", Vector2(3.2, 3.2), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(fx, "modulate:a", 0.0, 0.28)
	tw.tween_callback(fx.queue_free)

	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(global_position) < 200.0:
			e.take_damage(3, global_position)

	get_tree().call_group("shakeable", "add_shake", 14.0)
	get_tree().call_group("player_controller", "play_sfx", "explode")
	queue_free()
