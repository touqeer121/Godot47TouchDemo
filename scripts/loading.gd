extends Control

const NEXT := "res://scenes/title.tscn"
const MIN_TIME := 1.6

@onready var bar: ProgressBar = $Bar
@onready var pct: Label = $Pct

var elapsed := 0.0
var done := false

func _ready():
	ResourceLoader.load_threaded_request(NEXT)

func _process(delta):
	if done:
		return
	elapsed += delta

	var progress := []
	ResourceLoader.load_threaded_get_status(NEXT, progress)
	var load_ratio: float = progress[0] if progress.size() > 0 else 0.0

	# Blend real load progress with a minimum display time so the bar is visible.
	var time_ratio: float = clampf(elapsed / MIN_TIME, 0.0, 1.0)
	var shown: float = min(time_ratio, 0.15 + load_ratio * 0.85) if load_ratio < 1.0 else time_ratio
	bar.value = shown * 100.0
	pct.text = "%d%%" % int(shown * 100.0)

	if elapsed >= MIN_TIME and ResourceLoader.load_threaded_get_status(NEXT) == ResourceLoader.THREAD_LOAD_LOADED:
		done = true
		bar.value = 100.0
		pct.text = "100%"
		var scene: PackedScene = ResourceLoader.load_threaded_get(NEXT)
		get_tree().change_scene_to_packed(scene)
