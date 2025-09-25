class_name Terrain
extends Polygon2D

@export_flags_2d_physics var collision_layer: int = 1
@export_flags_2d_physics var collision_mask: int = 1

func _ready() -> void:
	var sb = StaticBody2D.new()
	var cp = CollisionPolygon2D.new()
	add_child(sb)
	sb.add_child(cp)
	cp.polygon = polygon
	sb.collision_layer = collision_layer
	sb.collision_mask = collision_mask
