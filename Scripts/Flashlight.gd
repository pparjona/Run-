extends SpotLight3D

var maxEnergy = 3.0
var on = false
@onready var flashlight: SpotLight3D = $"."
@onready var flash_light_click: AudioStreamPlayer3D = $FlashLightClick



func _ready() -> void:
	flashlight.light_energy = 0.0

func _process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("Flashlight"):
		if on:
			flashlight.light_energy = 0 
			flash_light_click.play()
			on = false
		else:
			flashlight.light_energy = maxEnergy
			flash_light_click.play()
			on = true
