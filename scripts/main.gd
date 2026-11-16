extends Node3D

# Exploración libre móvil: primera persona, linterna y perseguidor sencillo.
var player: CharacterBody3D
var camera: Camera3D
var animatronic: Node3D
var anim_head: Node3D
var hud: Label
var threat_label: Label
var overlay: ColorRect
var flashlight: SpotLight3D
var ambience: AudioStreamPlayer
var footstep_player: AudioStreamPlayer
var stomp_player: AudioStreamPlayer
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
	env.ambient_light_color = Color(0.29, 0.24, 0.19)
	env.ambient_light_energy = 0.58
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)
	# Gran comedor abierto para recorrer, con límites sólidos y decorado ligero.
	_solid_box(Vector3(0, -0.3, 0), Vector3(30, 0.6, 26), Color(0.13, 0.105, 0.08))
	_solid_box(Vector3(0, 5.1, 0), Vector3(30, 0.5, 26), Color(0.075, 0.063, 0.055), false)
	_solid_box(Vector3(0, 2.3, -13), Vector3(30, 4.6, 0.5), Color(0.17, 0.13, 0.1))
	_solid_box(Vector3(0, 2.3, 13), Vector3(30, 4.6, 0.5), Color(0.15, 0.11, 0.09))
	_solid_box(Vector3(-15, 2.3, 0), Vector3(0.5, 4.6, 26), Color(0.14, 0.105, 0.085))
	_solid_box(Vector3(15, 2.3, 0), Vector3(0.5, 4.6, 26), Color(0.14, 0.105, 0.085))
	# Mostrador, escenario y cabinas decorativas; el comedor queda transitable.
	_solid_box(Vector3(0, 1.2, -10.2), Vector3(8, 2.4, 1.3), Color(0.25, 0.12, 0.075))
	_solid_box(Vector3(-9.5, 0.55, -9.5), Vector3(8, 1.1, 2.0), Color(0.23, 0.14, 0.09))
	_solid_box(Vector3(9.5, 0.55, -9.5), Vector3(8, 1.1, 2.0), Color(0.23, 0.14, 0.09))
	# Mesas, asientos y franjas de color con colisión baja y sencilla.
	for p in [Vector3(-8,0,-3), Vector3(8,0,-3), Vector3(-8,0,4), Vector3(8,0,4), Vector3(0,0,3)]:
		_solid_box(p + Vector3(0,0.9,0), Vector3(3.1,0.18,2.0), Color(0.38,0.19,0.105))
		for sx in [-1.0, 1.0]:
			_solid_box(p + Vector3(sx*2.0,0.48,0), Vector3(0.55,0.95,0.65), Color(0.32,0.085,0.07))
	# Luces cálidas dispersas y focos de escenario.
	for p in [Vector3(-9,3.8,-5), Vector3(0,4,-3), Vector3(9,3.8,-5), Vector3(-8,3.5,6), Vector3(8,3.5,6)]:
		var light := OmniLight3D.new()
		light.position = p
		light.light_color = Color(1.0,0.63,0.32)
		light.light_energy = 0.55
		light.omni_range = 9.0
		light.shadow_enabled = false
		add_child(light)

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
	animatronic = Node3D.new()
	animatronic.name = "Animatronic_Pursuer"
	animatronic.position = Vector3(0, 0, -8)
	add_child(animatronic)
	var brown := Color(0.30,0.17,0.085)
	var tan := Color(0.66,0.45,0.25)
	_add_sphere(animatronic, Vector3(0,1.0,0), Vector3(0.56,0.72,0.44), brown)
	_add_sphere(animatronic, Vector3(0,0.34,0), Vector3(0.43,0.53,0.32), brown)
	anim_head = Node3D.new()
	anim_head.position.y = 1.78
	animatronic.add_child(anim_head)
	_add_sphere(anim_head, Vector3.ZERO, Vector3(0.44,0.43,0.38), brown)
	_add_sphere(anim_head, Vector3(-0.38,0.34,0), Vector3(0.17,0.22,0.12), brown)
	_add_sphere(anim_head, Vector3(0.38,0.34,0), Vector3(0.17,0.22,0.12), brown)
	for x in [-0.16, 0.16]:
		var eye := _add_sphere(anim_head, Vector3(x,0.1,0.32), Vector3(0.085,0.095,0.06), Color(1.0,0.72,0.2))
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(1.0,0.56,0.12)
		glow.emission_enabled = true
		glow.emission = Color(1.0,0.31,0.035)
		glow.emission_energy_multiplier = 2.4
		eye.material_override = glow
	_add_sphere(anim_head, Vector3(0,-0.08,0.36), Vector3(0.13,0.1,0.09), Color(0.07,0.04,0.03))
	_add_sphere(anim_head, Vector3(0,-0.24,0.31), Vector3(0.3,0.17,0.14), tan)
	_add_box_child(anim_head, Vector3(0,0.55,0), Vector3(0.5,0.12,0.5), Color(0.12,0.07,0.04))
	_add_box_child(anim_head, Vector3(0,0.77,0), Vector3(0.3,0.35,0.3), Color(0.12,0.07,0.04))
	for sx in [-1.0,1.0]:
		_add_sphere(animatronic, Vector3(sx*0.55,1.0,0), Vector3(0.18,0.49,0.18), brown)
		_add_sphere(animatronic, Vector3(sx*0.28,0.25,0), Vector3(0.20,0.24,0.2), Color(0.13,0.09,0.06))
	var body_shape := CapsuleShape3D.new()
	body_shape.radius = 0.43
	body_shape.height = 2.25
	var body_collision := CollisionShape3D.new()
	body_collision.shape = body_shape
	body_collision.position.y = 1.1
	# Pursuer movement is kinematic, collision shape protects player from props.
	var body := CharacterBody3D.new()
	body.name = "PursuerBody"
	body.position = animatronic.position
	body.add_child(body_collision)
	# Keep collision body as the animated root; transfer visual children to it.
	remove_child(animatronic)
	for child in animatronic.get_children():
		animatronic.remove_child(child)
		body.add_child(child)
	animatronic.free()
	animatronic = body
	add_child(animatronic)

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
	footstep_player.stream = load("res://assets/audio/player_footsteps.mp3")
	footstep_player.volume_db = -10.0
	add_child(footstep_player)
	stomp_player = AudioStreamPlayer.new()
	stomp_player.stream = load("res://assets/audio/animatronic_stomp.mp3")
	stomp_player.volume_db = -5.0
	add_child(stomp_player)

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
			var delta := event.position - last_look_pos
			look_delta += delta
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
			footstep_player.pitch_scale = randf_range(0.94,1.06)
			footstep_player.play()
			walk_timer = 0.40 if sprinting else 0.56
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
		if anim_head: anim_head.rotation.x = sin(elapsed * 2.4) * 0.035
	stomp_timer -= delta
	if distance < 10.0 and stomp_timer <= 0.0:
		stomp_player.pitch_scale = clampf(1.15 - distance * 0.035,0.78,1.1)
		stomp_player.play()
		stomp_timer = clampf(distance * 0.16,0.55,1.4)
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
