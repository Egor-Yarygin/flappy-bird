extends CharacterBody2D

const GRAVITY_FORCE : int = 1020
const MAX_SPEED : int = 585
const JUMP_VELOCITY : int = -410
var is_flying : bool = false
var is_falling : bool = false
const INITIAL_POSITION = Vector2(100, 400)

func _ready():
	initialize()

func initialize():
	is_falling = false
	is_flying = false
	position = INITIAL_POSITION
	set_rotation(0)

func _physics_process(delta):
	if is_flying or is_falling:
		velocity.y += GRAVITY_FORCE * delta
		if velocity.y > MAX_SPEED:
			velocity.y = MAX_SPEED
		if is_flying:
			set_rotation(deg_to_rad(velocity.y * 0.05))
			$AnimatedSprite2D.play()
		elif is_falling:
			set_rotation(PI / 2)
			$AnimatedSprite2D.stop()
		move_and_collide(velocity * delta)
	else:
		$AnimatedSprite2D.stop()

func jump():
	velocity.y = JUMP_VELOCITY
