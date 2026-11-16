extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var speed := 4.0
var yaw := 0.0
var pitch := -0.12
var look_touch := -1
var move_touch := -1
var touch_origin := Vector2.ZERO
var move_axis := Vector2.ZERO

func _ready() -> void:
	_setup_world()
	_setup_player()
	_setup_ui()
	var ambience := AudioStreamPlayer.new()
	ambience.stream = load("res://assets/audio/ambience.wav")
	ambience.volume_db = -13.0
	ambience.autoplay = true
	ambience.finished.connect(func(): ambience.play())
	add_child(ambience)

func _setup_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.025, 0.05, 0.08)
	sky_mat.sky_horizon_color = Color(0.20, 0.25, 0.24)
	sky_mat.ground_bottom_color = Color(0.025, 0.035, 0.03)
	sky_mat.ground_horizon_color = Color(0.12, 0.15, 0.12)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.48, 0.52)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.9
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -28, 0)
	sun.light_color = Color(1.0, 0.78, 0.57)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 35.0
	add_child(sun)
	_static_box(Vector3(0, -0.35, 0), Vector3(90, 0.7, 90), Color(0.13, 0.18, 0.13))
	for i in range(28):
		var x := float((i * 17) % 50) - 25.0
		var z := -5.0 - float((i * 13) % 38)
		var trunk_height := 2.0 + float(i % 3) * 0.45
		_static_box(Vector3(x, trunk_height * 0.5 - 0.1, z), Vector3(0.32, trunk_height, 0.32), Color(0.22, 0.13, 0.08))
		var foliage := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.0 + float(i % 3) * 0.18
		mesh.height = mesh.radius * 1.7
		foliage.mesh = mesh
		foliage.position = Vector3(x, trunk_height + 0.55, z)
		foliage.scale = Vector3(1.0, 1.35, 1.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = [Color(0.12,0.22,0.15), Color(0.16,0.25,0.17), Color(0.19,0.24,0.13)][i % 3]
		mat.roughness = 1.0
		foliage.material_override = mat
		add_child(foliage)
	var beacon := OmniLight3D.new()
	beacon.position = Vector3(0, 2.0, -18)
	beacon.light_color = Color(1.0, 0.45, 0.18)
	beacon.light_energy = 2.0
	beacon.omni_range = 9.0
	beacon.shadow_enabled = false
	add_child(beacon)
	_static_box(Vector3(0, 1.1, -18), Vector3(0.45, 2.2, 0.45), Color(0.22, 0.12, 0.07))

func _setup_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 1.0, 4)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.7
	shape.shape = capsule
	player.add_child(shape)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0.55, 0)
	camera.current = true
	camera.fov = 75.0
	player.add_child(camera)
	add_child(player)

func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "ECOS DEL UMBRAL  •  PROTOTIPO"
	label.position = Vector2(24, 18)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.82))
	layer.add_child(label)
	var hint := Label.new()
	hint.text = "WASD / flechas: moverse  •  ratón: mirar  •  ESC: liberar cursor"
	hint.position = Vector2(24, 48)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.72, 0.78, 0.72))
	layer.add_child(hint)

func _static_box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0025
		pitch = clampf(pitch - event.relative.y * 0.002, -1.1, 0.6)
		player.rotation.y = yaw
		camera.rotation.x = pitch
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.45 and move_touch == -1:
				move_touch = event.index
				touch_origin = event.position
				move_axis = Vector2.ZERO
			else:
				look_touch = event.index
		else:
			if event.index == move_touch:
				move_touch = -1
				move_axis = Vector2.ZERO
			if event.index == look_touch:
				look_touch = -1
	if event is InputEventScreenDrag:
		if event.index == move_touch:
			move_axis = (event.position - touch_origin).limit_length(70.0) / 70.0
		elif event.index == look_touch:
			yaw -= event.relative.x * 0.004
			pitch = clampf(pitch - event.relative.y * 0.003, -1.1, 0.6)
			player.rotation.y = yaw
			camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if move_axis.length() > 0.05:
		input = Vector2(move_axis.x, -move_axis.y)
	var direction := (player.transform.basis * Vector3(input.x, 0, input.y)).normalized()
	if direction.length() > 0.01:
		player.velocity.x = direction.x * speed
		player.velocity.z = direction.z * speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, speed * delta * 5.0)
		player.velocity.z = move_toward(player.velocity.z, 0.0, speed * delta * 5.0)
	player.velocity.y -= 9.8 * delta
	player.move_and_slide()
