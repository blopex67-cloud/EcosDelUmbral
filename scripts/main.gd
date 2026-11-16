extends Node3D

# Exploración libre móvil: primera persona, linterna y perseguidor sencillo.
var player: CharacterBody3D
var camera: Camera3D
var animatronic: Node3D
var anim_player: AnimationPlayer
var hud: Label
var threat_label: Label
var overlay: ColorRect
var flashlight: SpotLight3D
var ambience: AudioStreamPlayer
var footstep_player: AudioStreamPlayer
var stomp_player: AudioStreamPlayer3D
var touch_stick_id := -1
var touch_look_id := -1
var stick_vector := Vector2.ZERO
var look_delta := Vector2.ZERO
var last_look_pos := Vector2.ZERO
var walk_timer := 0.0
var stomp_timer := 0.0
var elapsed := 0.0
var caught := false
var lamp_on := true
var sprinting := false
var stick_center := Vector2.ZERO
var stick_radius := 82.0
var hud_layer: CanvasLayer
var floor_mat: StandardMaterial3D
var wall_mat: StandardMaterial3D
var wood_mat: StandardMaterial3D

func _ready() -> void:
	print("PIZZERIA_FREE_SCENE_READY")
	_build_world()
	_build_player()
	_build_animatronic()
	_build_hud()
	_setup_audio()

func _build_world() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.009, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.40, 0.37, 0.34)
	env.ambient_light_energy = 0.82
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)
	# Texturas 1K con mapas normales, comprimidas en JPG para un APK ligero.
	floor_mat = _texture_material("res://assets/textures/floor_tiles.jpg", "res://assets/textures/floor_tiles_normal.jpg", 0.92)
	wall_mat = _texture_material("res://assets/textures/wall_plaster.jpg", "res://assets/textures/wall_plaster_normal.jpg", 0.94)
	wood_mat = _texture_material("res://assets/textures/oak_veneer.jpg", "res://assets/textures/oak_veneer_normal.jpg", 0.76)
	# Gran comedor abierto para recorrer, con límites sólidos y decorado ligero.
	var floor_mesh := _solid_box(Vector3(0, -0.3, 0), Vector3(30, 0.6, 26), Color.WHITE)
	floor_mesh.material_override = floor_mat
	_solid_box(Vector3(0, 5.1, 0), Vector3(30, 0.5, 26), Color(0.075, 0.063, 0.055), false)
	for wall in [
		_solid_box(Vector3(0, 2.3, -13), Vector3(30, 4.6, 0.5), Color.WHITE),
		_solid_box(Vector3(0, 2.3, 13), Vector3(30, 4.6, 0.5), Color.WHITE),
		_solid_box(Vector3(-15, 2.3, 0), Vector3(0.5, 4.6, 26), Color.WHITE),
		_solid_box(Vector3(15, 2.3, 0), Vector3(0.5, 4.6, 26), Color.WHITE)]:
		wall.material_override = wall_mat
	# Mostrador, escenario y cabinas decorativas; el comedor queda transitable.
	var counter := _solid_box(Vector3(0, 1.2, -10.2), Vector3(8, 2.4, 1.3), Color.WHITE)
	counter.material_override = wood_mat
	_solid_box(Vector3(-9.5, 0.55, -9.5), Vector3(8, 1.1, 2.0), Color(0.23, 0.14, 0.09))
	_solid_box(Vector3(9.5, 0.55, -9.5), Vector3(8, 1.1, 2.0), Color(0.23, 0.14, 0.09))
	# Mesas, asientos y franjas de color con colisión baja y sencilla.
	for p in [Vector3(-8,0,-3), Vector3(8,0,-3), Vector3(-8,0,4), Vector3(8,0,4), Vector3(0,0,3)]:
		var tabletop := _solid_box(p + Vector3(0,0.9,0), Vector3(3.1,0.18,2.0), Color.WHITE)
		tabletop.material_override = wood_mat
		for sx in [-1.0, 1.0]:
			_solid_box(p + Vector3(sx*2.0,0.48,0), Vector3(0.55,0.95,0.65), Color(0.32,0.085,0.07))
	# Luces cálidas dispersas y focos de escenario.
	for p in [Vector3(-10,3.8,-6), Vector3(0,4,-7), Vector3(10,3.8,-6), Vector3(-10,3.5,3), Vector3(0,3.7,5), Vector3(10,3.5,3)]:
		var light := OmniLight3D.new()
		light.position = p
		light.light_color = Color(1.0,0.63,0.32)
		light.light_energy = 0.78
		light.omni_range = 10.0
		light.shadow_enabled = false
		add_child(light)
	# Neon strips with emissive material + subtle low-cost coloured light.
	_add_led_strip(Vector3(0,4.25,-12.55), Vector3(22,0.12,0.07), Color(0.05,0.88,1.0))
	_add_led_strip(Vector3(0,3.95,12.55), Vector3(18,0.10,0.06), Color(1.0,0.08,0.36))
	_add_led_strip(Vector3(-14.55,3.5,0), Vector3(0.07,0.10,18), Color(0.36,0.12,1.0))
	_add_led_strip(Vector3(14.55,3.5,0), Vector3(0.07,0.10,18), Color(0.05,0.82,0.62))
	_add_neon_light(Vector3(0,3.8,-11.7), Color(0.03,0.56,1.0), 0.7, 6.5)
	_add_neon_light(Vector3(-12.8,3.1,0), Color(0.32,0.07,1.0), 0.5, 6.0)
	_add_neon_light(Vector3(12.8,3.1,0), Color(0.03,0.7,0.45), 0.5, 6.0)

func _add_led_strip(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.2
	mesh.material_override = mat
	add_child(mesh)

func _add_neon_light(pos: Vector3, color: Color, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = false
	add_child(light)

func _texture_material(path: String, normal_path: String, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(path) as Texture2D
	mat.normal_enabled = true
	mat.normal_texture = load(normal_path) as Texture2D
	mat.normal_scale = 0.32
	mat.roughness = rough
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.uv1_scale = Vector3(6,6,1)
	return mat

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.05, 8)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.65
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.83
	player.add_child(collider)
	var pivot := Node3D.new()
	pivot.name = "LookPivot"
	pivot.position.y = 1.52
	player.add_child(pivot)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 82
	pivot.add_child(camera)
	flashlight = SpotLight3D.new()
	flashlight.position = Vector3(0, -0.08, -0.18)
	flashlight.rotation_degrees = Vector3(-4, 0, 0)
	flashlight.light_color = Color(1.0, 0.86, 0.66)
	flashlight.light_energy = 3.0
	flashlight.spot_range = 18.0
	flashlight.spot_angle = 34.0
	flashlight.shadow_enabled = false
	camera.add_child(flashlight)
	add_child(player)

func _build_animatronic() -> void:
	# Rigged animated CC0 robot model with 20 animation clips.
	animatronic = CharacterBody3D.new()
	animatronic.name = "Animatronic_Rigged_Robot"
	animatronic.position = Vector3(0,0,-8)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.68
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 0.84
	animatronic.add_child(collider)
	var packed := load("res://assets/models/animated_robot.glb") as PackedScene
	if packed:
		var model := packed.instantiate() as Node3D
		model.name = "RiggedAnimatedRobot"
		model.position.y = 0.06
		model.scale = Vector3.ONE * 1.15
		animatronic.add_child(model)
		_apply_robot_animatronic_material(model)
		anim_player = _find_animation_player(model)
		if anim_player and anim_player.has_animation("Idle-loop"):
			anim_player.play("Idle-loop")
	else:
		push_warning("Animated GLB unavailable; placeholder fallback used.")
		_add_sphere(animatronic,Vector3(0,0.9,0),Vector3(0.42,0.65,0.35),Color(0.26,0.12,0.11))
	add_child(animatronic)

func _apply_robot_animatronic_material(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var source := mesh_instance.get_active_material(surface)
			if source is StandardMaterial3D:
				var mat := (source as StandardMaterial3D).duplicate() as StandardMaterial3D
				mat.albedo_color = Color(0.76,0.44,0.40,1.0)
				mat.roughness = 0.62
				mesh_instance.set_surface_override_material(surface,mat)
	for child in node.get_children():
		_apply_robot_animatronic_material(child)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result:
			return result
	return null

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(root)
	hud = Label.new()
	hud.text = "PIZZERÍA CERRADA  •  EXPLORA Y SOBREVIVE"
	hud.anchor_left = 0.02
	hud.anchor_right = 0.68
	hud.anchor_top = 0.025
	hud.anchor_bottom = 0.11
	hud.add_theme_font_size_override("font_size", 20)
	hud.add_theme_color_override("font_color", Color(1.0,0.89,0.68))
	root.add_child(hud)
	threat_label = Label.new()
	threat_label.anchor_left = 0.70
	threat_label.anchor_right = 0.98
	threat_label.anchor_top = 0.025
	threat_label.anchor_bottom = 0.11
	threat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	threat_label.add_theme_font_size_override("font_size", 18)
	threat_label.add_theme_color_override("font_color", Color(1.0,0.38,0.28))
	root.add_child(threat_label)
	var joystick := ColorRect.new()
	joystick.name = "TouchStickVisual"
	joystick.size = Vector2(136,136)
	joystick.position = Vector2(34,-172)
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.color = Color(0.75,0.78,0.82,0.13)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stick_style := StyleBoxFlat.new()
	stick_style.bg_color = Color(0.17,0.2,0.22,0.48)
	stick_style.set_corner_radius_all(68)
	stick_style.border_color = Color(0.8,0.82,0.8,0.65)
	stick_style.set_border_width_all(2)
	var panel := Panel.new()
	panel.name = "StickBase"
	panel.position = Vector2(35,-174)
	panel.size = Vector2(132,132)
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.add_theme_stylebox_override("panel",stick_style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	var knob := Panel.new()
	knob.name = "StickKnob"
	knob.position = Vector2(73,-130)
	knob.size = Vector2(56,56)
	knob.anchor_top = 1.0
	knob.anchor_bottom = 1.0
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.75,0.78,0.8,0.72)
	knob_style.set_corner_radius_all(28)
	knob.add_theme_stylebox_override("panel",knob_style)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(knob)
	var light_button := _make_button(root,"LINTERNA",Vector2(-230,-145),Vector2(112,62))
	light_button.anchor_left = 1.0; light_button.anchor_right = 1.0
	light_button.pressed.connect(_toggle_flashlight)
	var sprint_button := _make_button(root,"CORRER",Vector2(-112,-145),Vector2(104,62))
	sprint_button.anchor_left = 1.0; sprint_button.anchor_right = 1.0
	sprint_button.button_down.connect(func(): sprinting=true)
	sprint_button.button_up.connect(func(): sprinting=false)
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.55,0.01,0.01,0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)

func _make_button(root: Control, text: String, pos: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.anchor_top = 1.0
	b.anchor_bottom = 1.0
	b.add_theme_font_size_override("font_size",17)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06,0.07,0.075,0.8)
	style.border_color = Color(0.65,0.45,0.25,0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	b.add_theme_stylebox_override("normal",style)
	b.add_theme_stylebox_override("pressed",style)
	root.add_child(b)
	return b

func _setup_audio() -> void:
	ambience = AudioStreamPlayer.new()
	ambience.stream = load("res://assets/audio/pizzeria_horror_ambience.mp3")
	ambience.volume_db = -18.0
	add_child(ambience)
	ambience.finished.connect(func(): ambience.play())
	ambience.play()
	footstep_player = AudioStreamPlayer.new()
	footstep_player.stream = load("res://assets/audio/player_step.ogg")
	footstep_player.volume_db = -13.0
	add_child(footstep_player)
	stomp_player = AudioStreamPlayer3D.new()
	stomp_player.stream = load("res://assets/audio/robot_step.ogg")
	stomp_player.volume_db = -2.0
	stomp_player.max_distance = 18.0
	stomp_player.unit_size = 7.0
	animatronic.add_child(stomp_player)

func _input(event: InputEvent) -> void:
	if caught: return
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.43 and event.position.y > get_viewport().get_visible_rect().size.y * 0.48:
				touch_stick_id = event.index
				stick_center = event.position
				stick_vector = Vector2.ZERO
			else:
				touch_look_id = event.index
				last_look_pos = event.position
		else:
			if event.index == touch_stick_id:
				touch_stick_id = -1
				stick_vector = Vector2.ZERO
			if event.index == touch_look_id:
				touch_look_id = -1
	elif event is InputEventScreenDrag:
		if event.index == touch_stick_id:
			stick_vector = ((event.position - stick_center) / stick_radius).limit_length(1.0)
		elif event.index == touch_look_id:
			var look_change: Vector2 = event.position - last_look_pos
			look_delta += look_change
			last_look_pos = event.position

func _process(delta: float) -> void:
	if caught: return
	elapsed += delta
	if absf(look_delta.x) + absf(look_delta.y) > 0.0:
		player.rotate_y(-look_delta.x * 0.0032)
		var pivot := player.get_node("LookPivot") as Node3D
		pivot.rotation.x = clampf(pivot.rotation.x - look_delta.y * 0.0032,-1.15,1.15)
		look_delta = Vector2.ZERO
	var forward := -player.global_transform.basis.z
	var right := player.global_transform.basis.x
	var move := right * stick_vector.x - forward * stick_vector.y
	if move.length() > 1.0: move = move.normalized()
	var speed := 3.4 if sprinting else 2.25
	player.velocity.x = move.x * speed
	player.velocity.z = move.z * speed
	player.velocity.y = -0.25
	player.move_and_slide()
	if move.length() > 0.15:
		walk_timer -= delta
		if walk_timer <= 0.0:
			if not footstep_player.playing:
				footstep_player.pitch_scale = randf_range(0.96,1.04)
				footstep_player.play()
			walk_timer = 0.48 if sprinting else 0.62
	# El animatrónico te rastrea directamente por el comedor y acelera con el tiempo.
	var to_player := player.global_position - animatronic.global_position
	to_player.y = 0
	var distance := to_player.length()
	var chase_speed := 1.05 + minf(elapsed / 130.0,1.0) * 0.85
	if distance > 0.05:
		var direction := to_player.normalized()
		animatronic.velocity.x = direction.x * chase_speed
		animatronic.velocity.z = direction.z * chase_speed
		animatronic.velocity.y = -0.25
		animatronic.move_and_slide()
		animatronic.look_at(Vector3(player.global_position.x,animatronic.global_position.y,player.global_position.z),Vector3.UP)
		if anim_player:
			var wanted := "Sprint-loop" if distance < 6.0 else "Run-loop"
			if anim_player.has_animation(wanted) and anim_player.current_animation != wanted:
				anim_player.play(wanted,0.18)
			anim_player.speed_scale = 1.0 + minf(elapsed/150.0,0.35)
	stomp_timer -= delta
	if distance < 12.0 and stomp_timer <= 0.0:
		if not stomp_player.playing:
			stomp_player.pitch_scale = clampf(1.05 - distance * 0.018,0.82,1.02)
			stomp_player.play()
		stomp_timer = clampf(distance * 0.35,1.8,3.4)
	if distance < 1.45:
		_caught_player()
	threat_label.text = "¡TE ESTÁ BUSCANDO!" if distance < 8.0 else "SE OYEN PASOS LEJANOS"
	hud.text = "PIZZERÍA CERRADA  •  %02d:%02d AM" % [12 + int(elapsed/60.0)%6, int(elapsed)%60]
	if overlay.color.a > 0.0:
		var c := overlay.color
		c.a = maxf(0.0,c.a - delta*0.38)
		overlay.color = c

func _toggle_flashlight() -> void:
	lamp_on = not lamp_on
	flashlight.visible = lamp_on

func _caught_player() -> void:
	caught = true
	footstep_player.stop()
	stomp_player.stop()
	ambience.stop()
	var to_player := player.global_position - animatronic.global_position
	animatronic.global_position = player.global_position - to_player.normalized() * 0.8
	animatronic.look_at(Vector3(player.global_position.x,animatronic.global_position.y,player.global_position.z),Vector3.UP)
	var c := overlay.color
	c.a = 0.72
	overlay.color = c
	hud.text = "¡TE ATRAPÓ!  •  TOCA PARA REINTENTAR"
	threat_label.text = "FIN DE LA NOCHE"
	var restart := _make_button(hud_layer.get_child(0),"REINTENTAR",Vector2(-115,-42),Vector2(230,72))
	restart.anchor_left = 0.5; restart.anchor_right = 0.5
	restart.anchor_top = 0.52; restart.anchor_bottom = 0.52
	restart.pressed.connect(func(): get_tree().reload_current_scene())

func _solid_box(pos: Vector3, size: Vector3, color: Color, collides: bool = true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _material(color)
	inst.position = pos
	add_child(inst)
	if collides:
		var body := StaticBody3D.new()
		body.position = pos
		var shape := BoxShape3D.new()
		shape.size = size
		var col := CollisionShape3D.new()
		col.shape = shape
		body.add_child(col)
		add_child(body)
	return inst

func _add_sphere(parent: Node3D, pos: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radial_segments = 14
	sphere.rings = 10
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh.mesh = sphere
	mesh.position = pos
	mesh.scale = scale_value * 2.0
	mesh.material_override = _material(color)
	parent.add_child(mesh)
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

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	return mat
