extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var sprite: Sprite2D = $Player/Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var rain_drops: GPUParticles2D = $RainDrops
@onready var gun: Node2D = $Player/Gun
@onready var gun_sprite: Sprite2D = $Player/Gun/GunSprite
@onready var muzzle: Marker2D = $Player/Gun/GunSprite/Muzzle
@onready var muzzle_flash: Sprite2D = $Player/Gun/GunSprite/Muzzle/MuzzleFlash
@onready var left_button: TouchScreenButton = $CanvasLayer/Left
@onready var right_button: TouchScreenButton = $CanvasLayer/Right
@onready var jump_button: TouchScreenButton = $CanvasLayer/Jump
@onready var melee_button: TouchScreenButton = $CanvasLayer/Melee
@onready var weapon_button: TouchScreenButton = $CanvasLayer/WeaponSwitch
@onready var weapon_icon: Sprite2D = $CanvasLayer/WeaponSwitch/Icon
@onready var left_icon: Sprite2D = $CanvasLayer/Left/Icon
@onready var right_icon: Sprite2D = $CanvasLayer/Right/Icon
@onready var jump_icon: Sprite2D = $CanvasLayer/Jump/Icon
@onready var melee_icon: Sprite2D = $CanvasLayer/Melee/Icon
@onready var aim_stick: Node2D = $CanvasLayer/AimStick
@onready var aim_knob: Sprite2D = $CanvasLayer/AimStick/Knob

const BULLET := preload("res://scenes/bullet.tscn")
const GRENADE := preload("res://scenes/grenade.tscn")
const ENEMY := preload("res://scenes/enemy.tscn")
const ENEMY_BIG := preload("res://scenes/enemy_big.tscn")
const ENEMY_GUNNER := preload("res://scenes/enemy_gunner.tscn")
const BARREL := preload("res://scenes/barrel.tscn")
const BLOCK := preload("res://scenes/block.tscn")
const GLOW := preload("res://light_glow.svg")
const RING := preload("res://ring.svg")
const FX_DEBRIS := preload("res://scenes/fx_debris.tscn")
const FX_DUST := preload("res://scenes/fx_dust.tscn")
const FX_SPARKS := preload("res://scenes/fx_sparks.tscn")

const BLOCK_SIZE := 46.0
const MELEE_REACH := 165.0
const MELEE_COOLDOWN := 0.32
const TERRAIN_CHUNK := preload("res://scripts/terrain_chunk.gd")

# Floating platforms as world rects [x_left, y_top, width, height]; each is
# split into destructible chunks so the level can be blown apart.
const PLATFORM_RECTS := [
	[971.5, 560.0, 337.0, 62.4], [1339.5, 452.0, 337.0, 62.4],
	[1675.5, 576.0, 337.0, 62.4], [1979.5, 356.0, 337.0, 62.4],
	[2323.5, 460.0, 337.0, 62.4], [2659.5, 576.0, 337.0, 62.4],
	[3005.5, 696.0, 880.0, 62.4], [4020.0, 600.0, 320.0, 62.0],
	[4480.0, 500.0, 280.0, 62.0], [4900.0, 590.0, 360.0, 62.0],
	[5400.0, 470.0, 320.0, 62.0], [4300.0, 380.0, 300.0, 62.0],
	[5850.0, 620.0, 550.0, 62.0],
]

const TEX_PISTOL := preload("res://assets/weapons/pistol.png")
const TEX_SMG := preload("res://assets/weapons/pistol3.png")
const TEX_SHOTGUN := preload("res://assets/weapons/shotgun.png")
const TEX_SMALL := preload("res://assets/weapons/small_bullet.png")
const TEX_MEDIUM := preload("res://assets/weapons/medium_bullet.png")
const TEX_GRENADE := preload("res://assets/weapons/grenade.png")

# Per-weapon tuning. muzzle is the barrel-hole offset in gun-sprite-local
# pixels (pre-scale); sprite_x is where the gun sprite sits from the hand pivot.
var weapons := [
	{"name": "Pistol", "gun_tex": TEX_PISTOL, "gun_scale": 0.93, "sprite_x": 26.0, "muzzle": Vector2(47, -9), "sfx": "pistol",
		"fire_rate": 0.16, "pellets": 1, "spread": 0.0, "bullet_tex": TEX_SMALL, "bullet_scale": 1.35, "bullet_speed": 1500.0, "recoil": 7.0, "shake": 3.0, "is_grenade": false},
	{"name": "SMG", "gun_tex": TEX_SMG, "gun_scale": 0.9, "sprite_x": 32.0, "muzzle": Vector2(98, -8), "sfx": "smg",
		"fire_rate": 0.07, "pellets": 1, "spread": 0.06, "bullet_tex": TEX_SMALL, "bullet_scale": 1.65, "bullet_speed": 1750.0, "recoil": 4.0, "shake": 2.0, "is_grenade": false},
	{"name": "Shotgun", "gun_tex": TEX_SHOTGUN, "gun_scale": 0.54, "sprite_x": 44.0, "muzzle": Vector2(196, -6), "sfx": "shotgun",
		"fire_rate": 0.55, "pellets": 6, "spread": 0.32, "bullet_tex": TEX_MEDIUM, "bullet_scale": 1.0, "bullet_speed": 1400.0, "recoil": 16.0, "shake": 9.0, "is_grenade": false},
	{"name": "Grenade", "gun_tex": TEX_GRENADE, "gun_scale": 1.0, "sprite_x": 14.0, "muzzle": Vector2(18, -4), "sfx": "throw",
		"fire_rate": 0.7, "pellets": 1, "spread": 0.0, "bullet_tex": TEX_SMALL, "bullet_scale": 1.0, "bullet_speed": 1050.0, "recoil": 12.0, "shake": 6.0, "is_grenade": true},
]
var weapon_index := 0
var cur_gun_scale := 0.93
var base_sprite_x := 26.0
var recoil_tween: Tween
var flash_tween: Tween
var shake := 0.0

var left:=false
var right:=false
var facing:=1
var is_rolling:=false
var jumps_left:=2
var base_scale:Vector2
var scale_tween:Tween
var icon_base_scale:={}
var icon_base_alpha:={}
var icon_tweens:={}
var bg_y:=0.0

var aim_touch_index:=-1
var aim_vector:=Vector2.ZERO
var aim_dir:=Vector2.RIGHT
var fire_timer:=0.0

var health:=5
var kills:=0
var invuln:=0.0
var knockback_timer:=0.0
var start_pos:=Vector2.ZERO
var health_pips:=[]
var kill_label:Label
var wave_label:Label
var best_label:Label

var wave:=0
var enemies_alive:=0
var spawning:=false
var best_wave:=0
var best_kills:=0
var sfx:={}
var melee_timer:=0.0

const SAVE_PATH := "user://save.cfg"
# Fixed enemy placements across the level, each with a behaviour.
# "static" = turret (orange); "standoff" = ranged walker (purple) that
# approaches to shooting distance then holds, never rushing to melee.
var FIXED_SPAWNS := [
	{"pos": Vector2(150, 470), "mode": "standoff"},
	{"pos": Vector2(520, 470), "mode": "static"},
	{"pos": Vector2(850, 470), "mode": "standoff"},
	{"pos": Vector2(1140, 500), "mode": "static"},
	{"pos": Vector2(1850, 460), "mode": "standoff"},
	{"pos": Vector2(2260, 430), "mode": "static"},
	{"pos": Vector2(3300, 560), "mode": "standoff"},
	{"pos": Vector2(3600, 560), "mode": "static"},
	{"pos": Vector2(4180, 500), "mode": "static"},
	{"pos": Vector2(4620, 400), "mode": "standoff"},
	{"pos": Vector2(5080, 490), "mode": "static"},
	{"pos": Vector2(5560, 370), "mode": "standoff"},
	{"pos": Vector2(6100, 520), "mode": "static"},
]
var spawn_i := 0

const MAX_HEALTH:=5
const KNOCKBACK:=400.0
const INVULN_TIME:=1.1
const CIRCLE := preload("res://button.svg")
const HEART := preload("res://heart.svg")
const STAR := preload("res://star.svg")

const COL_HEALTH := Color(0.96, 0.36, 0.44)
const COL_HEALTH_EMPTY := Color(0.28, 0.28, 0.36, 0.7)
const COL_GOLD := Color(0.98, 0.75, 0.35)
const COL_MINT := Color(0.34, 0.85, 0.80)
const COL_TEXT := Color(0.95, 0.96, 1.0)
const COL_PANEL := Color(0.09, 0.10, 0.18, 0.72)

const BG_Y_LERP_SPEED:=1.0
const RAIN_Y_OFFSET:=-480.0

const AIM_RADIUS:=120.0
const AIM_DEADZONE:=0.3

const SPEED:=750.0
const MAX_JUMPS:=2
const GRAVITY:=2200.0
const FALL_GRAVITY_MULT:=1.7
const JUMP_FORCE:=-1235.0
const TILT_ANGLE:=0.21
const TILT_LERP_SPEED:=10.0
const BUTTON_PRESS_ALPHA:=0.55
const EDGE_MARGIN_X:=123.2
const EDGE_MARGIN_Y:=116.8

func _ready():
	base_scale = sprite.scale
	for icon in [left_icon, right_icon, jump_icon, melee_icon]:
		icon_base_scale[icon] = icon.scale
		icon_base_alpha[icon] = icon.modulate.a

	var vp_size := get_viewport().get_visible_rect().size
	left_button.position = Vector2(EDGE_MARGIN_X, vp_size.y - EDGE_MARGIN_Y)
	right_button.position = Vector2(EDGE_MARGIN_X + 170.0, vp_size.y - EDGE_MARGIN_Y)
	jump_button.position = Vector2(vp_size.x - EDGE_MARGIN_X, vp_size.y - EDGE_MARGIN_Y)
	melee_button.position = Vector2(vp_size.x - EDGE_MARGIN_X - 168.0, vp_size.y - EDGE_MARGIN_Y)
	aim_stick.position = Vector2(vp_size.x - 190.0, vp_size.y - 360.0)
	weapon_button.position = Vector2(vp_size.x - 80.0, 90.0)

	add_to_group("shakeable")
	add_to_group("player_controller")
	player.add_to_group("player")
	_apply_weapon(0)

	start_pos = player.global_position
	_load_best()
	_build_hud()
	_build_audio()
	_build_platforms()
	_build_terrain()
	_start_run()

# Generate the floating platforms as rows of destructible chunks.
func _build_platforms():
	var color := Color(0.98, 0.75, 0.35)
	for r in PLATFORM_RECTS:
		var x0: float = r[0]
		var y0: float = r[1]
		var w: float = r[2]
		var h: float = r[3]
		var cols: int = maxi(1, int(round(w / 32.0)))
		var rows: int = maxi(1, int(round(h / 32.0)))
		var cw: float = w / float(cols)
		var ch: float = h / float(rows)
		for c in cols:
			for rr in rows:
				var center := Vector2(x0 + cw * (float(c) + 0.5), y0 + ch * (float(rr) + 0.5))
				_make_chunk(center, cw, ch, color)

func _make_chunk(center: Vector2, w: float, h: float, color: Color):
	var body := StaticBody2D.new()
	body.set_script(TERRAIN_CHUNK)
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	body.z_index = -1
	add_child(body)

	var hw := w * 0.5
	var hh := h * 0.5
	var quad := PackedVector2Array([Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])

	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = quad
	body.add_child(poly)

	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	# Overlap neighbours slightly so the player doesn't snag on cell seams.
	shape.size = Vector2(w + 3.0, h + 1.0)
	cs.shape = shape
	body.add_child(cs)

	bg_y = camera.global_position.y

# Destructible cover: crate walls and explosive barrels on solid surfaces.
func _build_terrain():
	_build_wall(Vector2(360, 617), 2, 3)
	_build_wall(Vector2(760, 617), 2, 2)
	_build_wall(Vector2(3300, 673), 2, 2)
	_build_wall(Vector2(3620, 673), 2, 3)
	for p in [Vector2(600, 600), Vector2(660, 600), Vector2(880, 600),
			Vector2(3200, 656), Vector2(3720, 656), Vector2(3760, 656)]:
		var b := BARREL.instantiate()
		b.global_position = p
		add_child(b)

func _build_wall(bottom_left: Vector2, cols: int, rows: int):
	for cx in cols:
		for cy in rows:
			var bl := BLOCK.instantiate()
			bl.global_position = bottom_left + Vector2(cx * BLOCK_SIZE, -cy * BLOCK_SIZE)
			add_child(bl)

# Central explosion used by grenades and barrels: FX, area damage to enemies,
# destructibles, and the player, plus shake and sound.
func explode(pos: Vector2, radius: float, damage: int):
	_explosion_fx(pos)
	add_shake(13.0)
	play_sfx("explode")
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(pos) < radius:
			e.take_damage(damage, pos)
	var carved := false
	for d in get_tree().get_nodes_in_group("destructible"):
		if not is_instance_valid(d) or d.global_position.distance_to(pos) >= radius:
			continue
		if d.is_in_group("terrain"):
			d.queue_free()   # cleared silently; central debris burst covers it
			carved = true
		else:
			d.take_damage(999, pos)   # barrels chain, crates shatter
	# A few chunky terrain-debris bursts across the crater (not one per cell).
	if carved:
		for i in 4:
			var off := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * radius * 0.5
			_burst(FX_DEBRIS, pos + off, Color(0.98, 0.75, 0.35))
	if player.global_position.distance_to(pos) < radius * 0.72:
		damage_player(1, pos)

func _add_glow(pos: Vector2, color: Color, from: float, to: float, dur: float):
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var fx := Sprite2D.new()
	fx.texture = GLOW
	fx.material = mat
	fx.modulate = color
	fx.scale = Vector2(from, from)
	fx.global_position = pos
	add_child(fx)
	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", Vector2(to, to), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(fx, "modulate:a", 0.0, dur)
	tw.tween_callback(fx.queue_free)

func _shockwave(pos: Vector2, to: float):
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var r := Sprite2D.new()
	r.texture = RING
	r.material = mat
	r.modulate = Color(1.0, 0.9, 0.6, 0.9)
	r.scale = Vector2(0.2, 0.2)
	r.global_position = pos
	add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "scale", Vector2(to, to), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(r, "modulate:a", 0.0, 0.32)
	tw.tween_callback(r.queue_free)

func _burst(scene: PackedScene, pos: Vector2, color := Color.WHITE):
	var b := scene.instantiate()
	b.global_position = pos
	if color != Color.WHITE:
		b.modulate = color
	add_child(b)

func _explosion_fx(pos: Vector2):
	_add_glow(pos, Color(1.0, 0.95, 0.7, 1.0), 0.25, 2.2, 0.16)   # white-hot core
	_add_glow(pos, Color(1.0, 0.55, 0.2, 0.9), 0.4, 4.0, 0.34)    # orange fireball
	_shockwave(pos, 3.6)
	_burst(FX_SPARKS, pos)
	_burst(FX_DUST, pos)

func spawn_debris(pos: Vector2, color: Color, _count: int):
	_burst(FX_DEBRIS, pos, color)
	_burst(FX_DUST, pos)

func _build_audio():
	for nm in ["pistol", "smg", "shotgun", "throw", "hit", "kill", "explode", "jump", "hurt", "switch"]:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://audio/%s.wav" % nm)
		p.volume_db = -6.0
		add_child(p)
		sfx[nm] = p
	var rain_player := AudioStreamPlayer.new()
	var rs = load("res://audio/rain.wav")
	if rs is AudioStreamWAV:
		rs.loop_mode = AudioStreamWAV.LOOP_FORWARD
		rs.loop_end = rs.data.size() / 2
	rain_player.stream = rs
	rain_player.volume_db = -13.0
	add_child(rain_player)
	rain_player.play()

func play_sfx(snd: String):
	if sfx.has(snd):
		sfx[snd].play()

func _load_best():
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_wave = cfg.get_value("score", "best_wave", 0)
		best_kills = cfg.get_value("score", "best_kills", 0)

func _save_best():
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best_wave", best_wave)
	cfg.set_value("score", "best_kills", best_kills)
	cfg.save(SAVE_PATH)

func _check_best():
	var changed := false
	if wave > best_wave:
		best_wave = wave
		changed = true
	if kills > best_kills:
		best_kills = kills
		changed = true
	if changed:
		_save_best()
		if best_label:
			best_label.text = "BEST  W%d  K%d" % [best_wave, best_kills]

func _start_run():
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	enemies_alive = 0
	wave = 0
	kills = 0
	if kill_label:
		kill_label.text = "0"
	_next_wave()

func _next_wave():
	wave += 1
	spawning = true
	spawn_i = 0
	if wave_label:
		wave_label.text = "WAVE %d" % wave
	var count: int = min(3 + wave, FIXED_SPAWNS.size())
	for i in count:
		get_tree().create_timer(i * 0.3).timeout.connect(_spawn_one)
	get_tree().create_timer(count * 0.28 + 0.15).timeout.connect(func():
		spawning = false
		if enemies_alive <= 0:
			get_tree().create_timer(1.5).timeout.connect(_next_wave)
	)

func _spawn_one():
	# Spawn at fixed placements; static spots become orange turrets, patrol
	# spots become purple walkers. A few become big green tanks in later waves.
	var entry = FIXED_SPAWNS[spawn_i % FIXED_SPAWNS.size()]
	spawn_i += 1
	var scene := ENEMY_GUNNER if entry.mode == "static" else ENEMY
	if wave >= 3 and randf() < 0.18:
		scene = ENEMY_BIG
	var e: CharacterBody2D = scene.instantiate()
	e.move_mode = entry.mode
	e.can_shoot = true
	e.max_health = e.max_health + int(wave / 2)
	e.global_position = entry.pos
	add_child(e)
	enemies_alive += 1

func _build_hud():
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	var hpanel := Panel.new()
	hpanel.position = Vector2(30, 26)
	hpanel.size = Vector2(MAX_HEALTH * 46 + 34, 62)
	hpanel.add_theme_stylebox_override("panel", _panel_style(COL_HEALTH))
	layer.add_child(hpanel)

	for i in MAX_HEALTH:
		var pip := Sprite2D.new()
		pip.texture = HEART
		pip.scale = Vector2(0.4, 0.4)
		pip.position = Vector2(64 + i * 46, 57)
		layer.add_child(pip)
		health_pips.append(pip)

	var kpanel := Panel.new()
	kpanel.position = Vector2(30, 100)
	kpanel.size = Vector2(140, 58)
	kpanel.add_theme_stylebox_override("panel", _panel_style(COL_GOLD))
	layer.add_child(kpanel)

	var kstar := Sprite2D.new()
	kstar.texture = STAR
	kstar.scale = Vector2(0.34, 0.34)
	kstar.modulate = COL_GOLD
	kstar.position = Vector2(62, 129)
	layer.add_child(kstar)

	kill_label = Label.new()
	kill_label.text = "0"
	kill_label.position = Vector2(90, 108)
	_style_label(kill_label, 34, COL_TEXT)
	layer.add_child(kill_label)

	var vp := get_viewport().get_visible_rect().size

	wave_label = Label.new()
	wave_label.text = "WAVE 1"
	wave_label.size = Vector2(vp.x, 54)
	wave_label.position = Vector2(0, 20)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(wave_label, 46, COL_MINT)
	layer.add_child(wave_label)

	best_label = Label.new()
	best_label.text = "BEST  W%d  K%d" % [best_wave, best_kills]
	best_label.size = Vector2(vp.x, 30)
	best_label.position = Vector2(0, 74)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(best_label, 22, Color(0.82, 0.84, 0.95))
	layer.add_child(best_label)

	_update_health_hud()

func _style_label(l: Label, size: int, col: Color):
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", maxi(5, size / 5))
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.09, 0.95))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 4)

func _panel_style(border_col: Color = Color(1, 1, 1, 0.12)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = COL_PANEL
	s.set_corner_radius_all(18)
	s.border_color = Color(border_col.r, border_col.g, border_col.b, 0.55)
	s.set_border_width_all(3)
	s.shadow_color = Color(0, 0, 0, 0.38)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	return s

func _update_health_hud():
	for i in health_pips.size():
		health_pips[i].modulate = COL_HEALTH if i < health else COL_HEALTH_EMPTY

func damage_player(amount: int, from_pos: Vector2):
	if invuln > 0.0 or health <= 0:
		return
	health -= amount
	_update_health_hud()
	invuln = INVULN_TIME
	knockback_timer = 0.25
	var kb := signf(player.global_position.x - from_pos.x)
	if kb == 0.0:
		kb = -float(facing)
	player.velocity.x = kb * KNOCKBACK
	player.velocity.y = -320.0
	add_shake(9.0)
	play_sfx("hurt")
	if health <= 0:
		_respawn()

func add_kill():
	kills += 1
	enemies_alive -= 1
	if kill_label:
		kill_label.text = str(kills)
	add_shake(3.0)
	_check_best()
	if enemies_alive <= 0 and not spawning:
		get_tree().create_timer(2.0).timeout.connect(_next_wave)

func _respawn():
	health = MAX_HEALTH
	_update_health_hud()
	player.velocity = Vector2.ZERO
	player.global_position = start_pos
	invuln = INVULN_TIME
	_start_run()

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if aim_touch_index == -1 and event.position.distance_to(aim_stick.position) <= AIM_RADIUS * 1.3:
				aim_touch_index = event.index
				_update_aim(event.position)
		elif event.index == aim_touch_index:
			_release_aim()
	elif event is InputEventScreenDrag and event.index == aim_touch_index:
		_update_aim(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		# Keyboard controls for desktop testing.
		match event.keycode:
			KEY_SPACE, KEY_W, KEY_UP:
				_on_jump_down()
			KEY_F, KEY_SHIFT:
				_on_melee_down()
			KEY_Q, KEY_TAB:
				_on_weapon_switch()

func _update_aim(pos: Vector2):
	var offset := pos - aim_stick.position
	if offset.length() > AIM_RADIUS:
		offset = offset.normalized() * AIM_RADIUS
	aim_knob.position = offset
	aim_vector = offset / AIM_RADIUS

func _release_aim():
	aim_touch_index = -1
	aim_vector = Vector2.ZERO
	aim_knob.position = Vector2.ZERO

func _apply_weapon(i: int):
	weapon_index = i
	var w = weapons[i]
	cur_gun_scale = w.gun_scale
	base_sprite_x = w.sprite_x
	if recoil_tween and recoil_tween.is_valid():
		recoil_tween.kill()
	gun_sprite.texture = w.gun_tex
	gun_sprite.position = Vector2(w.sprite_x, 0.0)
	gun_sprite.scale = Vector2(w.gun_scale, w.gun_scale)
	muzzle.position = w.muzzle
	var icon_tex = w.get("icon_tex", w.gun_tex)
	weapon_icon.texture = icon_tex
	weapon_icon.scale = Vector2.ONE * (72.0 / float(icon_tex.get_width()))

func _on_weapon_switch():
	_apply_weapon((weapon_index + 1) % weapons.size())
	play_sfx("switch")
	var t := create_tween()
	t.tween_property(weapon_icon, "scale", weapon_icon.scale * 1.25, 0.06)
	t.tween_property(weapon_icon, "scale", weapon_icon.scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_shooting(delta):
	var aiming := aim_vector.length() > AIM_DEADZONE
	if aiming:
		aim_dir = aim_vector.normalized()

	var dir := aim_dir if aiming else Vector2(float(facing), 0.0)
	gun.rotation = dir.angle()
	# Mirror with a negative Y scale (moves child nodes too) so the muzzle
	# marker stays glued to the barrel hole when aiming left.
	gun_sprite.scale = Vector2(cur_gun_scale, cur_gun_scale if dir.x >= 0.0 else -cur_gun_scale)

	if aiming:
		fire_timer -= delta
		if fire_timer <= 0.0:
			fire_timer = weapons[weapon_index].fire_rate
			_fire()
	else:
		fire_timer = 0.0

func _fire():
	var w = weapons[weapon_index]
	if w.is_grenade:
		var g := GRENADE.instantiate()
		g.velocity = aim_dir * w.bullet_speed + Vector2(0.0, -320.0)
		g.global_position = muzzle.global_position
		add_child(g)
	else:
		for i in w.pellets:
			var a := aim_dir.angle() + randf_range(-w.spread, w.spread)
			_spawn_bullet(Vector2.from_angle(a), w)
	_muzzle_flash()
	_recoil(w.recoil)
	add_shake(w.shake)
	play_sfx(w.sfx)

func _spawn_bullet(dir: Vector2, w):
	var b := BULLET.instantiate()
	b.velocity = dir * w.bullet_speed
	b.global_position = muzzle.global_position
	var spr: Sprite2D = b.get_node("Sprite2D")
	spr.texture = w.bullet_tex
	spr.scale = Vector2(w.bullet_scale, w.bullet_scale)
	add_child(b)

func _muzzle_flash():
	muzzle_flash.show()
	muzzle_flash.modulate = Color(1.0, 0.85, 0.5, 1.0)
	muzzle_flash.rotation = randf() * TAU
	muzzle_flash.scale = Vector2(0.18, 0.18)
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	flash_tween = create_tween()
	flash_tween.tween_property(muzzle_flash, "scale", Vector2(0.36, 0.36), 0.04)
	flash_tween.tween_property(muzzle_flash, "modulate:a", 0.0, 0.06)
	flash_tween.tween_callback(muzzle_flash.hide)

func _recoil(amount: float):
	if recoil_tween and recoil_tween.is_valid():
		recoil_tween.kill()
	gun_sprite.position.x = base_sprite_x - amount
	recoil_tween = create_tween()
	recoil_tween.tween_property(gun_sprite, "position:x", base_sprite_x, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func add_shake(amount: float):
	shake = maxf(shake, amount)

func _physics_process(delta):
	var was_on_floor := player.is_on_floor()

	if knockback_timer > 0.0:
		knockback_timer -= delta
		player.velocity.x = move_toward(player.velocity.x, 0.0, 1400.0 * delta)
	else:
		# Touch buttons OR keyboard (A/D, arrows) for desktop testing.
		var mleft := left or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
		var mright := right or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
		player.velocity.x = 0.0
		if mleft:
			player.velocity.x -= SPEED
			facing = -1
		if mright:
			player.velocity.x += SPEED
			facing = 1

	# Desktop: aim toward the mouse and fire while holding left mouse button.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var to := get_global_mouse_position() - player.global_position
		if to.length() > 4.0:
			aim_vector = to.normalized()
	elif aim_touch_index == -1:
		aim_vector = Vector2.ZERO

	if invuln > 0.0:
		invuln -= delta
		sprite.visible = int(invuln * 12.0) % 2 == 0
		if invuln <= 0.0:
			sprite.visible = true

	var gravity: float = GRAVITY * (FALL_GRAVITY_MULT if player.velocity.y > 0.0 else 1.0)
	player.velocity.y += gravity * delta

	player.move_and_slide()

	if player.is_on_floor():
		jumps_left = MAX_JUMPS
		if not was_on_floor:
			_squash_land()
			add_shake(4.0)

	if not is_rolling:
		var target_tilt: float = 0.0
		if player.velocity.x < -1.0:
			target_tilt = -TILT_ANGLE
		elif player.velocity.x > 1.0:
			target_tilt = TILT_ANGLE
		sprite.rotation = lerp_angle(sprite.rotation, target_tilt, TILT_LERP_SPEED * delta)

	camera.global_position = player.global_position

	# Rain pans horizontally with the camera but only slowly drifts
	# vertically, so a quick jump doesn't make it visibly bob.
	bg_y = lerp(bg_y, camera.global_position.y, BG_Y_LERP_SPEED * delta)
	rain_drops.position = Vector2(camera.global_position.x, bg_y + RAIN_Y_OFFSET)

	_update_shooting(delta)

	if melee_timer > 0.0:
		melee_timer -= delta

	if shake > 0.15:
		shake = lerpf(shake, 0.0, 14.0 * delta)
		camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	elif camera.offset != Vector2.ZERO:
		shake = 0.0
		camera.offset = Vector2.ZERO

func _on_left_down(): left=true; _icon_press(left_icon)
func _on_left_up(): left=false; _icon_release(left_icon)
func _on_right_down(): right=true; _icon_press(right_icon)
func _on_right_up(): right=false; _icon_release(right_icon)
func _on_jump_up(): _icon_release(jump_icon)
func _on_melee_up(): _icon_release(melee_icon)

func _on_melee_down():
	_icon_press(melee_icon)
	if melee_timer > 0.0:
		return
	melee_timer = MELEE_COOLDOWN
	var aiming := aim_vector.length() > AIM_DEADZONE
	var d := aim_dir if aiming else Vector2(float(facing), 0.0)
	var center := player.global_position + d * 90.0

	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(center) < MELEE_REACH:
			e.take_damage(5, player.global_position)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if is_instance_valid(b) and b.global_position.distance_to(center) < MELEE_REACH:
			b.queue_free()
	for dd in get_tree().get_nodes_in_group("destructible"):
		if is_instance_valid(dd) and dd.global_position.distance_to(center) < MELEE_REACH:
			dd.take_damage(2, player.global_position)

	_slash_fx(center, d)
	add_shake(2.5)
	play_sfx("throw")

func _slash_fx(center: Vector2, d: Vector2):
	var s := Sprite2D.new()
	s.texture = GLOW
	s.modulate = Color(1, 1, 1, 0.9)
	s.global_position = center
	s.rotation = d.angle()
	s.scale = Vector2(0.85, 0.4)
	add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2(1.5, 0.14), 0.12)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.14)
	tw.tween_callback(s.queue_free)

func _on_jump_down():
	_icon_press(jump_icon)
	if jumps_left <= 0:
		return
	var is_double := not player.is_on_floor()
	jumps_left -= 1
	player.velocity.y = JUMP_FORCE
	play_sfx("jump")
	if is_double:
		_squash_double_jump()
	else:
		_squash_launch()

func _icon_press(icon:Sprite2D):
	_tween_icon(icon, icon_base_scale[icon] * 0.82, BUTTON_PRESS_ALPHA, 0.06, false)

func _icon_release(icon:Sprite2D):
	_tween_icon(icon, icon_base_scale[icon], icon_base_alpha[icon], 0.18, true)

func _tween_icon(icon:Sprite2D, target_scale:Vector2, target_alpha:float, duration:float, bounce:bool):
	if icon_tweens.has(icon) and icon_tweens[icon].is_valid():
		icon_tweens[icon].kill()
	var t := create_tween()
	icon_tweens[icon] = t
	t.set_trans(Tween.TRANS_BACK if bounce else Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.set_parallel(true)
	t.tween_property(icon, "scale", target_scale, duration)
	t.tween_property(icon, "modulate:a", target_alpha, duration)

func _start_tween() -> Tween:
	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
	scale_tween = create_tween()
	return scale_tween

func _squash_launch():
	var tween := _start_tween()
	tween.tween_property(sprite, "scale", base_scale * Vector2(1.3, 0.7), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.85, 1.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.9, 1.1), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", base_scale, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _squash_double_jump():
	is_rolling = true
	sprite.rotation = 0.0
	var tween := _start_tween()
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.6, 1.45), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "rotation", TAU * facing, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		sprite.rotation = 0.0
		is_rolling = false
	)

func _squash_land():
	sprite.rotation = 0.0
	var tween := _start_tween()
	tween.tween_property(sprite, "scale", base_scale * Vector2(1.25, 0.8), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.85, 1.15), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", base_scale, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
