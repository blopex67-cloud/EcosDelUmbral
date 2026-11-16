extends Node3D

# Mobile-first FNAF-style fan-game prototype. No desktop input is required.
var left_door_closed := false
var right_door_closed := false
var left_light_on := false
var right_light_on := false
var cameras_open := false
var game_over := false
var night_time := 0.0
var threat_level := 0.0
var left_door: MeshInstance3D
var right_door: MeshInstance3D
var left_light: OmniLight3D
var right_light: OmniLight3D
var freddy: Node3D
var freddy_head: Node3D
var player_camera: Camera3D
var hud: Label
var screen_overlay: ColorRect
var flash_timer := 0.0

func _ready() -> void:
	_build_pizzeria()
	_build_freddy_placeholder()
	_build_mobile_hud()
	var ambience := AudioStreamPlayer.new()
	ambience.stream = load("res://assets/audio/ambience.wav")
	ambience.volume_db = -16.0
	ambience.autoplay = true
	ambience.finished.connect(func(): ambience.play())
	add_child(ambience)

func _build_pizzeria() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.006, 0.008, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.19, 0.16)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)

	var ceiling := _box(Vector3(0, 3.5, -1), Vector3(12, 0.35, 12), Color(0.09, 0.075, 0.065))
	ceiling.name = "Ceiling"
	_box(Vector3(0, -0.2, -1), Vector3(12, 0.4, 12), Color(0.14, 0.12, 0.095))
	_box(Vector3(0, 1.7, -7), Vector3(12, 3.8, 0.35), Color(0.16, 0.13, 0.105))
	_box(Vector3(-5.85, 1.7, -1), Vector3(0.3, 3.8, 12), Color(0.13, 0.105, 0.09))
	_box(Vector3(5.85, 1.7, -1), Vector3(0.3, 3.8, 12), Color(0.13, 0.105, 0.09))
	# Door frames and narrow dark corridors, set to either side of the office.
	for side in [-1.0, 1.0]:
		var x := side * 4.7
		_box(Vector3(x, 1.75, -5.45), Vector3(1.9, 3.5, 0.28), Color(0.07, 0.065, 0.06))
		_box(Vector3(x, 0.08, -4.0), Vector3(2.2, 0.16, 5.2), Color(0.08, 0.075, 0.065))
		_box(Vector3(x, 0.1, -6.7), Vector3(2.2, 0.2, 0.2), Color(0.34, 0.24, 0.12))
	left_door = _box(Vector3(-4.7, 3.25, -5.25), Vector3(1.65, 0.08, 0.12), Color(0.48, 0.38, 0.24))
	left_door.name = "LeftSecurityDoor"
	right_door = _box(Vector3(4.7, 3.25, -5.25), Vector3(1.65, 0.08, 0.12), Color(0.48, 0.38, 0.24))
	right_door.name = "RightSecurityDoor"
	# Desk, old monitor, fan and wall decorations.
	_box(Vector3(0, 0.85, 1.1), Vector3(4.5, 0.25, 1.5), Color(0.16, 0.095, 0.055))
	_box(Vector3(0, 1.35, 1.25), Vector3(1.6, 0.85, 0.18), Color(0.06, 0.075, 0.07))
	var monitor := _box(Vector3(0, 1.38, 1.14), Vector3(1.38, 0.62, 0.045), Color(0.12, 0.23, 0.18))
	monitor.name = "MonitorGlow"
	_box(Vector3(-4.1, 2.55, -6.77), Vector3(1.5, 0.8, 0.08), Color(0.34, 0.14, 0.12))
	_box(Vector3(4.1, 2.55, -6.77), Vector3(1.5, 0.8, 0.08), Color(0.2, 0.28, 0.16))
	var ceiling_light := OmniLight3D.new()
	ceiling_light.position = Vector3(0, 3.0, -0.2)
	ceiling_light.light_color = Color(1.0, 0.72, 0.46)
	ceiling_light.light_energy = 0.6
	ceiling_light.omni_range = 8.0
	ceiling_light.shadow_enabled = false
	add_child(ceiling_light)
	left_light = _make_corridor_light(Vector3(-4.7, 2.35, -4.6))
	right_light = _make_corridor_light(Vector3(4.7, 2.35, -4.6))
	player_camera = Camera3D.new()
	player_camera.position = Vector3(0, 1.75, 4.2)
	player_camera.rotation_degrees = Vector3(-5, 0, 0)
	player_camera.current = true
	player_camera.fov = 82
	add_child(player_camera)

func _make_corridor_light(pos: Vector3) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = Color(1.0, 0.78, 0.48)
	light.light_energy = 0.0
	light.omni_range = 5.0
	light.shadow_enabled = false
	add_child(light)
	return light

func _build_freddy_placeholder() -> void:
	# Lightweight original primitive rig, used until we can add the credited downloaded asset.
	freddy = Node3D.new()
	freddy.name = "Freddy_placeholder_not_final_asset"
	freddy.position = Vector3(4.7, 0.0, -11.5)
	freddy.scale = Vector3.ONE * 0.82
	add_child(freddy)
	var brown := Color(0.28, 0.16, 0.085)
	var tan := Color(0.62, 0.43, 0.24)
	_add_sphere(freddy, Vector3(0, 1.05, 0), Vector3(0.55, 0.72, 0.42), brown)
	_add_sphere(freddy, Vector3(0, 0.35, 0), Vector3(0.43, 0.55, 0.32), brown)
	freddy_head = Node3D.new()
	freddy_head.name = "Head"
	freddy_head.position = Vector3(0, 1.8, 0)
	freddy.add_child(freddy_head)
	_add_sphere(freddy_head, Vector3.ZERO, Vector3(0.44, 0.43, 0.38), brown)
	_add_sphere(freddy_head, Vector3(-0.38, 0.34, 0), Vector3(0.17, 0.22, 0.12), brown)
	_add_sphere(freddy_head, Vector3(0.38, 0.34, 0), Vector3(0.17, 0.22, 0.12), brown)
	_add_sphere(freddy_head, Vector3(-0.16, 0.1, 0.32), Vector3(0.09, 0.1, 0.06), Color(0.95, 0.82, 0.36))
	_add_sphere(freddy_head, Vector3(0.16, 0.1, 0.32), Vector3(0.09, 0.1, 0.06), Color(0.95, 0.82, 0.36))
	_add_sphere(freddy_head, Vector3(0, -0.08, 0.36), Vector3(0.13, 0.1, 0.09), Color(0.09, 0.055, 0.04))
	_add_sphere(freddy_head, Vector3(0, -0.24, 0.31), Vector3(0.3, 0.17, 0.14), tan)
	_add_box_child(freddy_head, Vector3(0, 0.55, 0), Vector3(0.5, 0.12, 0.5), Color(0.12, 0.07, 0.04))
	_add_box_child(freddy_head, Vector3(0, 0.77, 0), Vector3(0.3, 0.35, 0.3), Color(0.12, 0.07, 0.04))
	_add_box_child(freddy_head, Vector3(0, -0.38, 0.29), Vector3(0.12, 0.2, 0.1), Color(0.7, 0.08, 0.08))
	freddy_head.position.y = 1.8
	freddy_head.set_meta("base_y", 1.8)
	for sx in [-1.0, 1.0]:
		_add_sphere(freddy, Vector3(sx * 0.55, 1.05, 0), Vector3(0.17, 0.49, 0.18), brown)
		_add_sphere(freddy, Vector3(sx * 0.28, 0.28, 0), Vector3(0.19, 0.25, 0.2), Color(0.16, 0.11, 0.075))

func _build_mobile_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)
	hud = Label.new()
	hud.text = "12:00 AM  •  NOCHE 1  •  ENERGÍA 100%"
	hud.anchor_left = 0.28
	hud.anchor_right = 0.72
	hud.anchor_top = 0.02
	hud.anchor_bottom = 0.11
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud.add_theme_font_size_override("font_size", 22)
	hud.add_theme_color_override("font_color", Color(0.93, 0.88, 0.72))
	root.add_child(hud)
	var buttons := HBoxContainer.new()
	buttons.anchor_left = 0.035
	buttons.anchor_right = 0.965
	buttons.anchor_top = 0.82
	buttons.anchor_bottom = 0.97
	buttons.add_theme_constant_override("separation", 10)
	root.add_child(buttons)
	_add_button(buttons, "◀ LUZ", _toggle_left_light)
	_add_button(buttons, "◀ PUERTA", _toggle_left_door)
	_add_button(buttons, "CÁMARAS", _toggle_cameras)
	_add_button(buttons, "PUERTA ▶", _toggle_right_door)
	_add_button(buttons, "LUZ ▶", _toggle_right_light)
	screen_overlay = ColorRect.new()
	screen_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_overlay.color = Color(0.45, 0.0, 0.0, 0.0)
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(screen_overlay)
	var note := Label.new()
	note.text = "SUPERVISA LOS PASILLOS. CIERRA LAS PUERTAS CUANDO SE ACERQUE."
	note.anchor_left = 0.18
	note.anchor_right = 0.82
	note.anchor_top = 0.72
	note.anchor_bottom = 0.8
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 15)
	note.add_theme_color_override("font_color", Color(0.82, 0.79, 0.68))
	root.add_child(note)

func _add_button(container: HBoxContainer, text: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", Color(0.95, 0.91, 0.8))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.085, 0.09, 0.92)
	style.border_color = Color(0.46, 0.34, 0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", style)
	b.add_theme_stylebox_override("pressed", style)
	b.pressed.connect(callback)
	container.add_child(b)

func _box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = _material(color)
	add_child(mesh)
	return mesh

func _add_box_child(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	return mesh

func _add_sphere(parent: Node3D, pos: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radial_segments = 12
	sphere.rings = 8
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh.mesh = sphere
	mesh.position = pos
	mesh.scale = scale_value * 2.0
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	return mesh

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	return mat

func _toggle_left_door() -> void:
	left_door_closed = not left_door_closed
	left_door.position.y = 1.65 if left_door_closed else 3.25

func _toggle_right_door() -> void:
	right_door_closed = not right_door_closed
	right_door.position.y = 1.65 if right_door_closed else 3.25

func _toggle_left_light() -> void:
	left_light_on = not left_light_on
	left_light.light_energy = 2.0 if left_light_on else 0.0

func _toggle_right_light() -> void:
	right_light_on = not right_light_on
	right_light.light_energy = 2.0 if right_light_on else 0.0

func _toggle_cameras() -> void:
	cameras_open = not cameras_open
	if cameras_open:
		player_camera.position = Vector3(0, 2.6, 2.8)
		player_camera.rotation_degrees = Vector3(-24, 0, 0)
		hud.text = "CÁMARAS  •  COMEDOR / ESCENARIO / PASILLOS"
	else:
		player_camera.position = Vector3(0, 1.75, 4.2)
		player_camera.rotation_degrees = Vector3(-5, 0, 0)

func _process(delta: float) -> void:
	if game_over:
		return
	night_time += delta
	threat_level = minf(threat_level + delta / 85.0, 1.0)
	var approach := 11.5 - threat_level * 7.0
	freddy.position.z = approach
	if left_light_on and threat_level > 0.35:
		freddy.position.x = -4.7
	elif right_light_on and threat_level > 0.65:
		freddy.position.x = 4.7
	else:
		freddy.position.x = 4.7 if int(night_time / 12.0) % 2 == 0 else -4.7
	if freddy_head:
		freddy_head.rotation.y = sin(night_time * 1.3) * 0.22
	freddy.rotation.y = sin(night_time * 0.45) * 0.07
	var at_left_door := freddy.position.x < 0 and freddy.position.z > -5.8
	var at_right_door := freddy.position.x > 0 and freddy.position.z > -5.8
	if (at_left_door and not left_door_closed) or (at_right_door and not right_door_closed):
		if threat_level > 0.82:
			_start_jumpscare()
	if flash_timer > 0:
		flash_timer -= delta
		screen_overlay.color.a = maxf(0.0, flash_timer * 0.8)
	var hour := int(night_time / 45.0) % 6
	var energy := maxi(0, 100 - int(night_time * 0.18) - (15 if left_door_closed else 0) - (15 if right_door_closed else 0) - (8 if left_light_on or right_light_on else 0))
	if not cameras_open:
		hud.text = "%02d:00 AM  •  NOCHE 1  •  ENERGÍA %d%%" % [12 + hour, energy]

func _start_jumpscare() -> void:
	game_over = true
	freddy.position = player_camera.global_position + (-player_camera.global_transform.basis.z * 1.1)
	freddy.scale = Vector3.ONE * 1.8
	freddy.rotation.y = player_camera.rotation.y
	flash_timer = 1.4
	hud.text = "¡TE ATRAPÓ!  •  TOCA REINICIAR LA NOCHE"
	var restart := Button.new()
	restart.text = "REINTENTAR"
	restart.anchor_left = 0.38
	restart.anchor_right = 0.62
	restart.anchor_top = 0.43
	restart.anchor_bottom = 0.6
	restart.add_theme_font_size_override("font_size", 24)
	restart.pressed.connect(func(): get_tree().reload_current_scene())
	get_child(get_child_count() - 1).add_child(restart)
