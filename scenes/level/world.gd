extends Node2D

const TERRAIN_COLLISION_LAYER := 1
const DEFAULT_MAP_TILE_SIZE := Vector2i(32, 32)
const DEFAULT_MAP_DIMENSIONS := Vector2i(80, 60)
const PROP_Y_SORT_LAYERS := ["Decoration", "Obstacles"]

@export var map_dimensions_tiles := DEFAULT_MAP_DIMENSIONS
@export var boundary_thickness := 96.0
@onready var _map_boundaries: Node2D = $MapBoundaries

func _ready() -> void:
	call_deferred("_rebuild_world_collisions")

func _rebuild_world_collisions() -> void:
	_clear_generated_children(_map_boundaries)
	_apply_prop_layer_sorting()

	var tile_size := _resolve_tile_size()
	_build_map_boundaries(tile_size)

func _resolve_tile_size() -> Vector2i:
	for child in get_children():
		if child is TileMapLayer:
			var tile_map := child as TileMapLayer
			if tile_map.tile_set != null:
				return tile_map.tile_set.tile_size
	return DEFAULT_MAP_TILE_SIZE

func _build_map_boundaries(tile_size: Vector2i) -> void:
	if _map_boundaries == null:
		return

	var map_pixel_size := Vector2(
		float(map_dimensions_tiles.x * tile_size.x),
		float(map_dimensions_tiles.y * tile_size.y)
	)
	var thickness := maxf(boundary_thickness, float(tile_size.x))
	var body := _create_static_body("MapBoundaryBody")
	_map_boundaries.add_child(body)

	_add_rectangle_shape(
		body,
		"NorthBoundary",
		Vector2(map_pixel_size.x + (thickness * 2.0), thickness),
		Vector2(map_pixel_size.x * 0.5, -thickness * 0.5)
	)
	_add_rectangle_shape(
		body,
		"SouthBoundary",
		Vector2(map_pixel_size.x + (thickness * 2.0), thickness),
		Vector2(map_pixel_size.x * 0.5, map_pixel_size.y + (thickness * 0.5))
	)
	_add_rectangle_shape(
		body,
		"WestBoundary",
		Vector2(thickness, map_pixel_size.y),
		Vector2(-thickness * 0.5, map_pixel_size.y * 0.5)
	)
	_add_rectangle_shape(
		body,
		"EastBoundary",
		Vector2(thickness, map_pixel_size.y),
		Vector2(map_pixel_size.x + (thickness * 0.5), map_pixel_size.y * 0.5)
	)

func _create_static_body(body_name: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.collision_layer = TERRAIN_COLLISION_LAYER
	body.collision_mask = 0
	return body

func _apply_prop_layer_sorting() -> void:
	for child in get_children():
		if child is not TileMapLayer:
			continue

		var tile_map := child as TileMapLayer
		if PROP_Y_SORT_LAYERS.has(tile_map.name):
			tile_map.y_sort_enabled = true

func _add_rectangle_shape(body: StaticBody2D, shape_name: String, shape_size: Vector2, center: Vector2) -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = shape_size

	var collision_shape := CollisionShape2D.new()
	collision_shape.name = shape_name
	collision_shape.shape = rectangle
	collision_shape.position = center
	body.add_child(collision_shape)

func _clear_generated_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.queue_free()
