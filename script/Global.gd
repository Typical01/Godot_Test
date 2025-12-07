extends Node

const SLOT_SIZE = 64
const TEXTURE_SIZE = 64
var SLOT_SCALE = SLOT_SIZE / TEXTURE_SIZE
var H_SEPARATION = 0
var V_SEPARATION = 0

enum Quality {
	White = 0,
	Green,
	Blue,
	Purple,
	Gold,
	Red
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
