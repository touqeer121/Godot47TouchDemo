extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var gun: Sprite2D = get_node_or_null("Gun")
@onready var floor_check: RayCast2D = $FloorCheck
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var touch_box: Area2D = $TouchBox

@export var max_health := 3
@export var speed := 90.0
@export var contact_damage := 1
@export var can_shoot := true
# "static" = holds position and fires; "patrol" = walks back and forth;
# "chase" = pursues the player; "standoff" = advance to range then hold.
@export var move_mode := "patrol"
@export var shoot_kind := "bullet"   # or "grenade"
@export var is_alarm := false         # calls in reinforcements when it sees you

var alarm_timer := 3.0
const ALARM_INTERVAL := 6.0
const E_GRENADE := preload("res://scenes/enemy_grenade.tscn")

var health := 3
var dir := 1
var dead := false
var hurt_timer := 0.0
var base_scale: Vector2
var base_color: Color
var fc_offset := 40.0
var target: Node2D
var shoot_timer := 1.0
var muzzle_len := 44.0

const GRAVITY := 2000.0
const SHOOT_RANGE := 860.0
const SHOOT_INTERVAL := 2.1
const STANDOFF_DIST := 470.0
const E_BULLET := preload("res://scenes/enemy_bullet.tscn")

func _ready():
	add_to_group("enemies")
	health = max_health
	base_scale = sprite.scale
	base_color = sprite.modulate
	fc_offset = absf(floor_check.position.x)
	target = get_tree().get_first_node_in_group("player")
	shoot_timer = randf_range(0.7, SHOOT_INTERVAL)
	if gun:
		muzzle_len = gun.texture.get_width() * absf(gun.scale.x) * 0.5 + 6.0
	touch_box.body_entered.connect(_on_touch)

func _physics_process(delta):
	if dead:
		return

	velocity.y += GRAVITY * delta

	if hurt_timer > 0.0:
		hurt_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	elif move_mode == "static":
		velocity.x = 0.0
		# Face the player so shots look aimed.
		if is_instance_valid(target):
			dir = 1 if target.global_position.x > global_position.x else -1
	elif move_mode == "standoff":
		_standoff()
	elif move_mode == "chase":
		_move_toward_player()
	else:
		_patrol()

	move_and_slide()

	sprite.scale.x = base_scale.x * (1.0 if dir > 0 else -1.0)

	# Aim the gun at the player (kept upright with flip_v when facing left).
	if gun and is_instance_valid(target):
		var ad := (target.global_position - gun.global_position).normalized()
		gun.rotation = ad.angle()
		gun.flip_v = ad.x < 0.0

	if can_shoot and is_instance_valid(target):
		shoot_timer -= delta
		if shoot_timer <= 0.0 and global_position.distance_to(target.global_position) < SHOOT_RANGE:
			shoot_timer = SHOOT_INTERVAL
			_shoot_at(target.global_position)

	if is_alarm and is_instance_valid(target):
		if global_position.distance_to(target.global_position) < SHOOT_RANGE:
			alarm_timer -= delta
			if alarm_timer <= 0.0:
				alarm_timer = ALARM_INTERVAL
				get_tree().call_group("player_controller", "spawn_reinforcement", global_position)

func _patrol():
	floor_check.position.x = fc_offset * dir
	floor_check.force_raycast_update()
	if is_on_wall() or (is_on_floor() and not floor_check.is_colliding()):
		dir = -dir
	velocity.x = dir * speed

func _move_toward_player():
	var want := dir
	if is_instance_valid(target):
		want = 1 if target.global_position.x > global_position.x else -1
	floor_check.position.x = fc_offset * want
	floor_check.force_raycast_update()
	if is_on_floor() and not floor_check.is_colliding():
		velocity.x = 0.0
	else:
		dir = want
		velocity.x = dir * speed

# Advance until within shooting distance, then hold and fire. Doesn't
# retreat if the player closes in (Contra/Broforce style), and never
# rushes to melee or walks off a ledge.
func _standoff():
	velocity.x = 0.0
	if not is_instance_valid(target):
		return
	var dx := target.global_position.x - global_position.x
	var face := 1 if dx > 0.0 else -1
	dir = face
	if absf(dx) > STANDOFF_DIST:
		floor_check.position.x = fc_offset * face
		floor_check.force_raycast_update()
		if not (is_on_floor() and not floor_check.is_colliding()):
			velocity.x = face * speed

func _shoot_at(pos: Vector2):
	var origin: Vector2 = gun.global_position if gun else global_position
	if shoot_kind == "grenade":
		var g := E_GRENADE.instantiate()
		var to := pos - origin
		g.velocity = Vector2(to.x * 1.1, -420.0)   # lob toward the player
		g.global_position = origin
		get_parent().add_child(g)
		return
	var to := (pos - origin).normalized()
	var b := E_BULLET.instantiate()
	b.velocity = to * 640.0
	b.global_position = origin + to * muzzle_len
	get_parent().add_child(b)

func take_damage(amount: int, from_pos: Vector2 = Vector2.ZERO):
	if dead:
		return
	health -= amount
	_flash()
	get_tree().call_group("player_controller", "play_sfx", "hit")
	get_tree().call_group("player_controller", "spawn_hit_number", global_position, amount)
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
	if gun:
		gun.visible = false
	get_tree().call_group("player_controller", "add_kill")
	get_tree().call_group("player_controller", "play_sfx", "kill")
	get_tree().call_group("player_controller", "spawn_debris", global_position, base_color, 8)
	get_tree().call_group("player_controller", "maybe_drop", global_position)
	# Fling the corpse rather than a tidy squash.
	var t := create_tween()
	t.tween_property(sprite, "position", sprite.position + Vector2(randf_range(-40, 40), -70), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(sprite, "scale", base_scale * Vector2(1.4, 0.4), 0.1)
	t.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)
	t.parallel().tween_property(sprite, "rotation", randf_range(-3.0, 3.0), 0.25)
	t.tween_callback(queue_free)

func _on_touch(body):
	if dead:
		return
	if body.is_in_group("player"):
		get_tree().call_group("player_controller", "damage_player", contact_damage, global_position)
