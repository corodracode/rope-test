class_name RopeVisual
extends Node

@export var player: Player
@export var segment_count: int = 5

var segments: Array[RigidBody2D]

func clear():
	segments.clear()
	for i in get_children():
		i.queue_free()

func create_segment(pos: Vector2):
	var rb: RigidBody2D = RigidBody2D.new()
	var cs: CollisionShape2D = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8
	cs.shape = circle
	add_child(rb)
	rb.add_child(cs)
	rb.mass = .1
	rb.collision_layer = 0
	rb.collision_mask = 0
	rb.global_position = pos
	segments.append(rb)

func create_pin(pos: Vector2) -> PinJoint2D:
	var pin = PinJoint2D.new()
	add_child(pin)
	pin.global_position = pos
	return pin

func create_rope(p1: Vector2, p2: Vector2, length: float):
	# static body base
	var sb: StaticBody2D = StaticBody2D.new()
	add_child(sb)
	sb.global_position = p2
	# Rigidbodies segnents
	for i in segment_count:
		var r = float(i) / segment_count
		create_segment(lerp(p1, p2, r))
	# Pin joints between segments
	for i in segment_count-1:
		var seg1: RigidBody2D = segments.get(i)
		var seg2: RigidBody2D = segments.get(i+1)
		var center = lerp(seg1.global_position, seg2.global_position, .5)
		var pin = create_pin(center)
		pin.node_a = seg1.get_path()
		pin.node_b = seg2.get_path()
	# Player pin
	var player_pin = create_pin(player.global_position)
	player_pin.node_a = player.get_path()
	player_pin.node_b = segments[0].get_path()
	# Static pin
	var static_pin = create_pin(sb.global_position)
	static_pin.node_a = sb.get_path()
	static_pin.node_b = segments[-1].get_path()
