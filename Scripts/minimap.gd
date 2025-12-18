extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Minimap camera has entered scene tree")
	print("Current difficulty is ", GameManager.difficulty)
	if GameManager.difficulty >= 2:
		self.get_parent().get_parent().visible = false # Replace with function body.
		print("Hard difficulty selected disabling minimap")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	self.position = get_tree().get_nodes_in_group("Player")[0].position + Vector3(0,50,0)
