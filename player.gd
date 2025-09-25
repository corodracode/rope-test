class_name Player
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var max_speed: float = 300
@export var accel: float = 5
@export var accel_curve: Curve
@export var friction: float = 4
@export_group("Rope", "rope_")
@export var rope_stiffnes: float = 1500
@export var rope_friction: float = 2000

var hang_point: Vector2
var hang_lenght: float
var is_hanging: bool
var tracking: PackedVector2Array

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var release_timer: Timer = $ReleaseTimer
@onready var rope_visual: RopeVisual = $RopeVisual
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer: Timer = $JumpBuffer

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Debug jump to position
		if event.button_index == 2 and event.pressed:
			global_position = get_global_mouse_position()
		if event.button_index == 1:
			# Release
			if is_hanging and not event.pressed:
				velocity *= 1.1
				release_timer.start()
				rope_visual.clear()
			var can_hang: bool = ray_cast_2d.is_colliding()
			is_hanging = event.pressed and can_hang
			# Hang
			if is_hanging:
				hang_point = ray_cast_2d.get_collision_point()
				hang_lenght = ray_cast_2d.global_position.distance_to(hang_point)
				hang_lenght = max(60, hang_lenght)
				rope_visual.create_rope(global_position, hang_point, hang_lenght)
			queue_redraw()

func _draw() -> void:
	# draw tracking
	if tracking:
		draw_polyline(global_transform.affine_inverse()*tracking, Color(0.352, 0.807, 0.867, 1.0), 2)
	# drawing hanging point
	if is_hanging:
		draw_circle(to_local(hang_point), 8, Color(1.0, 0.0, 0.0, 1.0))
	# drawing rope
	var line: Array[Vector2]
	if rope_visual.segments: for seg in rope_visual.segments:
		line.append(to_local(seg.global_position))
	line.append(to_local(hang_point))
	if line:
		draw_polyline(line, Color(0.496, 0.496, 0.496, 1.0), 3)

func _physics_process(delta: float) -> void:
	# reset coyote timer
	if is_on_floor():
		coyote_timer.start()
	# rotate raycast to mouse
	ray_cast_2d.rotation = get_local_mouse_position().angle()
	# Add the gravity.
	if velocity.y < 0 or is_hanging:
		velocity += get_gravity() * delta
	else:
		velocity += get_gravity() * delta * 2
	
	# start jump buffer
	if Input.is_action_just_pressed("up"):
		jump_buffer.start()
	# Handle jump
	if (not jump_buffer.is_stopped()) and (not coyote_timer.is_stopped() or not release_timer.is_stopped()):
		velocity.y = JUMP_VELOCITY
		jump_buffer.stop()
		coyote_timer.stop()
	if Input.is_action_just_released("up") and velocity.y < 0:
		velocity.y = 0
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	var norm_speed = abs(velocity.x) / max_speed
	if is_on_floor():
		# Accel when on floor
		velocity.x += accel * max_speed * direction * delta * accel_curve.sample(norm_speed)
		velocity.x -= friction * max_speed * delta * norm_speed * sign(velocity.x)
	else:
		# Accel less when on air
		velocity.x += accel * max_speed * direction * delta * accel_curve.sample(norm_speed) * .5
	update_hanging(delta)
	update_tracking()
	queue_redraw()
	move_and_slide()

func update_hanging(delta):
	if not is_hanging: return
	var hang_local: Vector2 = to_local(hang_point)
	ray_cast_2d.rotation = hang_local.angle()
	var length_ratio = max(0, hang_local.length() - hang_lenght)
	# Stiffness force of rope
	velocity += length_ratio * rope_stiffnes * hang_local.normalized() * delta * .9
	# Damping of the rope
	velocity -= rope_friction * sign(velocity.dot(hang_local)) * hang_local.normalized() * delta * sign(length_ratio)

func update_tracking():
	tracking.reverse()
	tracking.append(global_position)
	tracking.reverse()
	if tracking.size() > 100:
		tracking.resize(100)
