extends Node2D
## Creates procedural steam particle effects for hot drinks
## Lightweight alternative to GPUParticles2D for small, localized effects

# Steam particle data
var particles: Array[Dictionary] = []
const MAX_PARTICLES := 12
const SPAWN_RATE := 0.15  # seconds between spawns
const PARTICLE_LIFETIME := 1.5

var spawn_timer: float = 0.0
var is_active: bool = false

# Steam appearance
const STEAM_COLOR := Color(1.0, 1.0, 1.0, 0.4)
const STEAM_SIZE_MIN := 2.0
const STEAM_SIZE_MAX := 5.0
const STEAM_RISE_SPEED := 20.0
const STEAM_DRIFT_SPEED := 8.0


func _process(delta: float) -> void:
	if not is_active:
		return

	# Spawn new particles
	spawn_timer += delta
	if spawn_timer >= SPAWN_RATE and particles.size() < MAX_PARTICLES:
		spawn_timer = 0.0
		_spawn_particle()

	# Update existing particles
	var to_remove: Array[int] = []
	for i in range(particles.size()):
		var p: Dictionary = particles[i]
		p.age += delta
		p.y -= STEAM_RISE_SPEED * delta
		p.x += sin(p.age * 3.0 + p.phase) * STEAM_DRIFT_SPEED * delta
		p.size = lerpf(STEAM_SIZE_MIN, STEAM_SIZE_MAX, p.age / PARTICLE_LIFETIME)
		p.alpha = 1.0 - (p.age / PARTICLE_LIFETIME)

		if p.age >= PARTICLE_LIFETIME:
			to_remove.append(i)

	# Remove dead particles
	for i in range(to_remove.size() - 1, -1, -1):
		particles.remove_at(to_remove[i])

	queue_redraw()


func _spawn_particle() -> void:
	var particle := {
		"x": randf_range(-3.0, 3.0),
		"y": 0.0,
		"age": 0.0,
		"phase": randf() * TAU,
		"size": STEAM_SIZE_MIN,
		"alpha": 1.0
	}
	particles.append(particle)


func _draw() -> void:
	if not is_active:
		return

	for p in particles:
		var color := STEAM_COLOR
		color.a *= p.alpha
		draw_circle(Vector2(p.x, p.y), p.size, color)


func start() -> void:
	is_active = true
	spawn_timer = 0.0


func stop() -> void:
	is_active = false
	particles.clear()
	queue_redraw()
