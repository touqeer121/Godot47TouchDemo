extends GPUParticles2D

# One-shot particle burst that emits on spawn and frees itself when done.
func _ready():
	emitting = true
	get_tree().create_timer(lifetime + 0.5).timeout.connect(queue_free)
