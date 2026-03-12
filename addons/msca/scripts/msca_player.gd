class_name MSCAPlayer
extends CharacterBody2D

@onready var animationPlayer: AnimationPlayer = _resolve_animation_player()
@onready var animationTree: AnimationTree = _resolve_animation_tree()
@onready var animationState = animationTree.get("parameters/playback") if animationTree != null else null

const ACCELERATION = 10
const FRICTION = 10

@export var speed = 60
var facing_direction = Vector2.ZERO

func _ready():
	if animationPlayer == null:
		push_error("MSCAPlayer could not find an AnimationPlayer named 'AnimationPlayer'.")
		return

	if animationTree == null:
		push_error("MSCAPlayer could not find an AnimationTree named 'AnimationTree'.")
		return

	animationTree.set_animation_player(animationPlayer.get_path())
	animationTree.active = true

func travel_to_anim(animName:String, direction = null):
	if animationTree == null or animationState == null:
		return

	if direction != null: facing_direction = direction
	
	animationTree.set("parameters/"+animName+"/blend_position", facing_direction)
	animationState.travel(animName)

func _resolve_animation_player() -> AnimationPlayer:
	var by_path = get_node_or_null("SpriteLayers/AnimationPlayer") as AnimationPlayer
	if by_path != null:
		return by_path

	return find_child("AnimationPlayer", true, false) as AnimationPlayer

func _resolve_animation_tree() -> AnimationTree:
	var by_path = get_node_or_null("SpriteLayers/AnimationTree") as AnimationTree
	if by_path != null:
		return by_path

	return find_child("AnimationTree", true, false) as AnimationTree
	
