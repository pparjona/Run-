extends Node3D

@export var bullet_scene: PackedScene
@export var shoot_cooldown := 0.2   # tiempo entre disparos
@export var muzzle: Node3D          # referencia al nodo Muzzle

var can_shoot := true
var anim_player: AnimationPlayer

func _ready():
	anim_player = $AnimationPlayer


func try_shoot():
	if not can_shoot:
		return

	can_shoot = false
	_shoot_bullet()
	anim_player.play("shoot")
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


func _shoot_bullet():
	if bullet_scene == null or muzzle == null:
		return
	
	var b = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = muzzle.global_position
	b.global_transform = muzzle.global_transform
