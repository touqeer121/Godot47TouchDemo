extends Node2D

@onready var sprite=$Sprite2D
var speed:=300.0
var left:=false
var right:=false

func _process(delta):
	if left:
		sprite.position.x -= speed*delta
	if right:
		sprite.position.x += speed*delta

func _on_left_down(): left=true
func _on_left_up(): left=false
func _on_right_down(): right=true
func _on_right_up(): right=false
