extends Sprite2D

var message : String = "Me-ow :3"
var location : Vector2 = Vector2(500, 200)
var direction : Vector2 = Vector2(1, 2)
var speed : int = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	print(message)
	global_position = location

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position += direction * speed * delta
