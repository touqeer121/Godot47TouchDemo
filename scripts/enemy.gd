extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var floor_check: RayCast2D = $FloorCheck
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var touch_box: Area2D = $TouchBox

@export var max_health := 3
@export var speed := 90.0
@export var contact_damage := 1

var health := 3
var dir := 1
var dead := false
var hurt_timer := 0.0
var base_scale: Vector2
var base_color: Color
var fc_offset := 40.0
var target: Node2D

const GRAVITY := 2000.0

func _ready():
	add_to_group("enemies")
	health = max_health
	base_scale = sprite.scale
	base_color = sprite.modulate
	fc_offset = absf(floor_check.position.x)
	target = get_tree().get_first_node_in_group("player")
	touch_box.body_entered.connect(_on_touch)

func _physics_process(delta):
	if dead:
		return

	velocity.y += GRAVITY * delta

	if hurt_timer > 0.0:
		hurt_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	else:
		# Chase the player, but stop at ledges/walls instead of falling off.
		var want := dir
		if is_instance_valid(target):
			want = 1 if target.global_position.x > global_position.x else -1
		floor_check.position.x = fc_offset * want
		floor_check.force_raycast_update()
		var ledge := is_on_floor() and not floor_check.is_colliding()
		if ledge:
			velocity.x = 0.0
		else:
			dir = want
			velocity.x = dir * speed

	move_and_slide()

	sprite.scale.x = base_scale.x * (1.0 if dir > 0 else -1.0)

func take_damage(amount: int, from_pos: Vector2 = Vector2.ZERO):
	if dead:
		return
	health -= amount
	_flash()
	get_tree().call_group("player_controller", "play_sfx", "hit")
	var kb := signf(global_position.x - from_pos.x)
	if kb == 0.0:
		kb = -float(dir)
	velocity.x = kb * 280.0
	hurt_timer = 0.16
	if health <= 0:
		_die()

func _flash():
	sprite.modulate = Color(3.0, 3.0, 3.0)
	var t := create_tween()
	t.tween_property(sprite, "modulate", base_color, 0.15)

func _die():
	dead = true
	body_shape.set_deferred("disabled", true)
	touch_box.set_deferred("monitoring", false)
	get_tree().call_group("player_controller", "add_kill")
	get_tree().call_group("player_controller", "play_sfx", "kill")
	var t := create_tween()
	t.tween_property(sprite, "scale", base_scale * Vector2(1.7, 0.2), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	t.parallel().tween_property(sprite, "rotation", randf_range(-1.0, 1.0), 0.2)
	t.tween_callback(queue_free)

func _on_touch(body):
	if dead:
		return
	if body.is_in_group("player"):
		get_tree().call_group("player_controller", "damage_player", contact_damage, global_position)
