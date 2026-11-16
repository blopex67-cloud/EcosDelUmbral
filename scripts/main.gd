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
var footstep_player: AudioStreamPlayer
var stomp_player: AudioStreamPlayer3D
var touch_stick_id := -1
var touch_look_id := -1
var stick_vector := Vector2.ZERO
var look_delta := Vector2.ZERO
var last_look_pos := Vector2.ZERO
var walk_timer := 0.0
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
var stick_base: Panel
var stick_knob: Panel
var stick_knob_radius := 42.0
var game_started := false
var lobby_layer: CanvasLayer
var anim_step_timer := 0.0
var flashlight_audio: AudioStreamPlayer
var horror_player: AudioStreamPlayer
var monster_growl_player: AudioStreamPlayer3D
var toy_voice_player: AudioStreamPlayer3D
var laugh_player: AudioStreamPlayer3D
var laugh_alt_player: AudioStreamPlayer3D
var ambience_player: AudioStreamPlayer
var footstep_a: AudioStreamPlayer
var footstep_b: AudioStreamPlayer
var robot_step_a: AudioStreamPlayer3D
var robot_step_b: AudioStreamPlayer3D
var voice_timer := 13.0
var horror_timer := 37.0
var player_step_flip := false

func _ready() -> void:
	print("PIZZERIA_FREE_SCENE_READY")
	_build_world()
	_build_player()
	_build_animatronic()
	_build_hud()
	_setup_audio()
	_build_lobby()

func _build_world() -> void:
	print("PIZZERIA_CORRIDORS_V2_READY")
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.009, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.56, 0.48)
	env.ambient_light_energy = 0.80
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.18
	env.glow_bloom = 0.025
	env_node.environment = env
	add_child(env_node)
	# Texturas 1K con mapas normales, comprimidas en JPG para un APK ligero.
	floor_mat = _texture_material("res://assets/textures/floor_checker.jpg", "res://assets/textures/floor_checker_normal.jpg", 0.92)
	floor_mat.uv1_scale = Vector3(18.0,18.0,1.0)
	wall_mat = _texture_material("res://assets/textures/wall_albedo.jpg", "res://assets/textures/wall_normal.jpg", 0.94)
	wall_mat.uv1_scale = Vector3(10,4,1)
	wood_mat = _texture_material("res://assets/textures/wood_albedo.jpg", "res://assets/textures/wood_normal.jpg", 0.68)
	wood_mat.uv1_scale = Vector3(3,3,1)
	# Gran comedor abierto para recorrer, con límites sólidos y decorado ligero.
	var floor_mesh := _solid_box(Vector3(-2, -0.3, -8), Vector3(160, 0.6, 60), Color.WHITE, false)
	floor_mesh.material_override = floor_mat
	_solid_box(Vector3(-2, 5.1, -8), Vector3(160, 0.5, 60), Color(0.13, 0.10, 0.075), false)
	# Openings connect the dining room to three substantial walkable corridors.
	# North opening, 6 m wide, aligned with an old tiled service tunnel.
	for segment in [
		_solid_box(Vector3(-19,2.3,-22),Vector3(10,4.6,0.5),Color.WHITE),
		_solid_box(Vector3(16,2.3,-22),Vector3(32,4.6,0.5),Color.WHITE),
		_solid_box(Vector3(-8,2.3,22),Vector3(64,4.6,0.5),Color.WHITE),
		_solid_box(Vector3(-24,2.3,-13),Vector3(0.5,4.6,18),Color.WHITE),
		_solid_box(Vector3(-24,2.3,14),Vector3(0.5,4.6,16),Color.WHITE),
		_solid_box(Vector3(24,2.3,-13),Vector3(0.5,4.6,18),Color.WHITE),
		_solid_box(Vector3(24,2.3,14),Vector3(0.5,4.6,16),Color.WHITE),
		_solid_box(Vector3(-64,2.3,0),Vector3(0.5,4.6,44),Color.WHITE),
		_solid_box(Vector3(-10,2.3,-38),Vector3(112,4.6,0.5),Color.WHITE)]:
		segment.material_override = wall_mat
	# Three connected walkable corridors branch off the dining room through visible doorways.
	# Main west hall: first section opens directly from the dining room, then continues to an old service wing.
	for segment in [
		_solid_box(Vector3(-32,2.2,-2),Vector3(16,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(-32,2.2,6),Vector3(16,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(-52,2.2,-2),Vector3(24,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(-52,2.2,6),Vector3(24,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(-64,2.2,2),Vector3(0.42,4.4,8),Color.WHITE),
		# northern branch connects through a 6m doorway in the west hall wall.
		_solid_box(Vector3(-52,2.2,-22),Vector3(24,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(-52,2.2,-2),Vector3(8.8,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(-42.6,2.2,-2),Vector3(2.8,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(-64,2.2,-12),Vector3(0.42,4.4,20),Color.WHITE)]:
		segment.material_override = wall_mat
	# New east service corridor opens from the dining room; a second side doorway returns to the hall.
	for segment in [
		_solid_box(Vector3(36,2.2,-4),Vector3(24,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(36,2.2,4),Vector3(24,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(48,2.2,-3),Vector3(0.42,4.4,2.0),Color.WHITE),
		_solid_box(Vector3(48,2.2,3),Vector3(0.42,4.4,2.0),Color.WHITE)]:
		segment.material_override = wall_mat
	# East wing continues through the service door into a connected three-way corridor loop.
	for segment in [
		_solid_box(Vector3(60,2.2,-4),Vector3(24,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(60,2.2,4),Vector3(24,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(72,2.2,0),Vector3(0.42,4.4,8),Color.WHITE),
		_solid_box(Vector3(60,2.2,-14),Vector3(24,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(60,2.2,14),Vector3(24,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(48,2.2,-9),Vector3(0.42,4.4,10),Color.WHITE),
		_solid_box(Vector3(48,2.2,9),Vector3(0.42,4.4,10),Color.WHITE),
		_solid_box(Vector3(60,2.2,-10),Vector3(12,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(60,2.2,10),Vector3(12,4.4,0.42),Color.WHITE),
		_solid_box(Vector3(66,2.2,-6.5),Vector3(0.42,4.4,7),Color.WHITE),
		_solid_box(Vector3(66,2.2,6.5),Vector3(0.42,4.4,7),Color.WHITE)]:
		segment.material_override = wall_mat
	# Warm ceiling ribs, rounded pipes and alcove doors give the additional corridor a distinct look.
	for x in [27.0,33.0,39.0,45.0]:
		_add_box_child(self,Vector3(x,4.25,0),Vector3(0.18,0.20,7.5),Color(0.24,0.20,0.17))
		_add_led_strip(Vector3(x,4.05,0),Vector3(0.9,0.07,0.16),Color(0.85,0.49,0.28))
	_add_pipe_run(Vector3(36,3.72,-3.2),Vector3(22,0.14,0.14),Color(0.31,0.34,0.34))
	_add_pipe_run(Vector3(36,3.72,3.2),Vector3(22,0.14,0.14),Color(0.31,0.34,0.34))
	for x in [30.0,42.0]:
		_add_box_child(self,Vector3(x,1.75,3.68),Vector3(1.55,2.45,0.08),Color(0.16,0.13,0.11))
		_add_box_child(self,Vector3(x,1.75,3.62),Vector3(1.28,2.17,0.06),Color(0.37,0.27,0.20))
	# PBR pipework, framed doors and worn wall panels make the extended wing less blocky.
	var pipe_metal := _material(Color(0.27,0.30,0.31))
	pipe_metal.metallic = 0.68
	pipe_metal.roughness = 0.34
	var trim_wood := _material(Color(0.20,0.105,0.062))
	trim_wood.roughness = 0.58
	for x in [51.0,57.0,63.0,69.0]:
		_add_pipe_run(Vector3(x,3.85,0),Vector3(7.2,0.15,0.15),Color(0.29,0.33,0.34))
		_add_box_child(self,Vector3(x,4.22,0),Vector3(0.20,0.18,7.4),Color(0.20,0.105,0.062))
		_add_led_strip(Vector3(x,4.02,0),Vector3(1.1,0.055,0.16),Color(0.82,0.58,0.37))
	for z in [-8.0,8.0]:
		for x in [54.0,62.0,70.0]:
			_add_box_child(self,Vector3(x,1.62,z),Vector3(1.45,2.9,0.12),Color(0.20,0.105,0.062))
			_add_box_child(self,Vector3(x,1.62,z-signf(z)*0.08),Vector3(1.20,2.64,0.06),Color(0.27,0.30,0.31))
			_add_box_child(self,Vector3(x+0.39,1.55,z-signf(z)*0.12),Vector3(0.05,0.18,0.05),Color(0.78,0.56,0.25))
	for x in [52.0,60.0,68.0]:
		var practical := OmniLight3D.new()
		practical.position = Vector3(x,3.75,0)
		practical.light_color = Color(0.80,0.72,0.57) if int(x) % 2 == 0 else Color(0.55,0.68,0.73)
		practical.light_energy = 0.58
		practical.omni_range = 8.0
		practical.shadow_enabled = false
		add_child(practical)
	# Ceiling ribs, visible warm fixtures and wall-base wear break up long straight sightlines.
	for x in [-60.0,-54.0,-48.0,-42.0,-36.0,-30.0]:
		_add_box_child(self,Vector3(x,4.25,2),Vector3(0.18,0.20,7.4),Color(0.24,0.20,0.17))
		_add_led_strip(Vector3(x,4.05,2),Vector3(0.9,0.07,0.16),Color(0.88,0.55,0.34))
	for z in [-8.0,-14.0,-20.0]:
		_add_box_child(self,Vector3(-52,4.25,z),Vector3(23.5,0.20,0.18),Color(0.24,0.20,0.17))
		_add_led_strip(Vector3(-52,4.04,z),Vector3(1.0,0.07,0.18),Color(0.80,0.51,0.30))
	# A recessed utility alcove and service doors provide recognizable landmarks along the route.
	for x in [-60.0,-52.0,-44.0]:
		_add_box_child(self,Vector3(x,1.8,5.70),Vector3(1.45,2.5,0.08),Color(0.16,0.13,0.11))
		_add_box_child(self,Vector3(x,1.8,5.64),Vector3(1.18,2.22,0.06),Color(0.37,0.27,0.20))
		_add_box_child(self,Vector3(x+0.42,1.8,5.57),Vector3(0.05,0.16,0.06),Color(0.82,0.60,0.22))
	# Rounded overhead pipes and floor cable channels add shape variation and a less blocky silhouette.
	_add_pipe_run(Vector3(-52,3.76,-0.8),Vector3(24,0.14,0.14),Color(0.31,0.34,0.34))
	_add_pipe_run(Vector3(-52,3.54,-0.8),Vector3(24,0.08,0.08),Color(0.20,0.24,0.25))
	_add_pipe_run(Vector3(-52,3.76,4.8),Vector3(24,0.14,0.14),Color(0.31,0.34,0.34))
	_add_pipe_run(Vector3(-52,3.54,4.8),Vector3(24,0.08,0.08),Color(0.20,0.24,0.25))
	for x in [-60.0,-52.0,-44.0]:
		_add_box_child(self,Vector3(x,0.08,2),Vector3(0.15,0.16,7.2),Color(0.30,0.25,0.20))
	# Mostrador, escenario y cabinas decorativas; el comedor queda transitable.
	var counter := _solid_box(Vector3(0, 1.2, -10.2), Vector3(8, 2.4, 1.3), Color.WHITE, true, 2)
	counter.material_override = wood_mat
	_solid_box(Vector3(-9.5, 0.55, -9.5), Vector3(8, 1.1, 2.0), Color(0.23, 0.14, 0.09))
	_solid_box(Vector3(9.5, 0.55, -9.5), Vector3(8, 1.1, 2.0), Color(0.23, 0.14, 0.09))
	# Mesas, asientos y franjas de color con colisión baja y sencilla.
	for p in [Vector3(-16,0,-3), Vector3(-8,0,-3), Vector3(0,0,-3), Vector3(8,0,-3), Vector3(16,0,-3), Vector3(-16,0,6), Vector3(-8,0,6), Vector3(0,0,6), Vector3(8,0,6), Vector3(16,0,6)]:
		var tabletop := _solid_box(p + Vector3(0,0.9,0), Vector3(3.1,0.18,2.0), Color(0.72,0.70,0.63), false)
		tabletop.material_override = _material(Color(0.74,0.72,0.66))
		# Tablecloth has soft folds and shaded edges similar to the supplied reference.
		_solid_box(p + Vector3(0,0.99,0),Vector3(3.0,0.08,1.96),Color(0.79,0.77,0.69),false)
		_solid_box(p + Vector3(0,0.73,0),Vector3(2.94,0.42,1.90),Color(0.68,0.66,0.59),false)
		for dx in [-1.40,1.40]:
			_solid_box(p+Vector3(dx,0.55,0),Vector3(0.055,0.72,1.92),Color(0.78,0.76,0.69),false)
		for lx in [-1.28,1.28]:
			for lz in [-0.78,0.78]:
				_add_cylinder(p+Vector3(lx,0.42,lz),0.075,0.84,Color(0.24,0.21,0.18),12)
		for sx in [-1.0, 1.0]:
			var chair_pos: Vector3 = p + Vector3(sx*1.45,0.48,0)
			_add_cylinder(chair_pos+Vector3(0,0.08,0),0.34,0.16,Color(0.27,0.055,0.05),20)
			_add_sphere(self,chair_pos+Vector3(0,0.67,0.28),Vector3(0.29,0.34,0.09),Color(0.32,0.07,0.06))
			for lx in [-0.23,0.23]:
				for lz in [-0.23,0.23]:
					_add_cylinder(chair_pos+Vector3(lx,-0.24,lz),0.035,0.48,Color(0.22,0.19,0.16),10)
	# Escenario, cocina, almacén y pasillo de servicio; todos los accesos son recorribles.
	var stage := _solid_box(Vector3(0,0.35,-18.5),Vector3(18,0.7,5.2),Color(0.13,0.08,0.065),true,2)
	stage.material_override = wood_mat
	for x in [-7.0,-3.5,0.0,3.5,7.0]:
		_solid_box(Vector3(x,2.9,-20.7),Vector3(0.22,4.0,0.18),Color(0.28,0.08,0.075),false)
	# Cocina trasera con aperturas laterales.
	_solid_box(Vector3(-15.5,2.1,-12.5),Vector3(17,4.2,0.42),Color(0.28,0.24,0.20))
	_solid_box(Vector3(15.5,2.1,-12.5),Vector3(17,4.2,0.42),Color(0.28,0.24,0.20))
	for x in [-20.0,-14.0,14.0,20.0]:
		var prep := _solid_box(Vector3(x,1,-17),Vector3(4.2,1.8,1.2),Color(0.34,0.37,0.39),true,2)
		_solid_box(Vector3(x,2.05,-17),Vector3(4.25,0.12,1.25),Color(0.58,0.58,0.53),false)
		_solid_box(Vector3(x,2.2,-20),Vector3(3.2,0.16,0.45),Color(0.30,0.32,0.33),true,2)
	# Pasillo de servicio y cuartos laterales con paso desde el comedor.
	_solid_box(Vector3(18.2,2.1,-3.0),Vector3(0.4,4.2,10),Color(0.32,0.27,0.24))
	_solid_box(Vector3(18.2,2.1,13.0),Vector3(0.4,4.2,5),Color(0.32,0.27,0.24))
	_solid_box(Vector3(21,2.1,-8),Vector3(5.6,4.2,0.4),Color(0.32,0.27,0.24))
	_solid_box(Vector3(21,2.1,4),Vector3(5.6,4.2,0.4),Color(0.32,0.27,0.24))
	_solid_box(Vector3(21,2.1,-1.5),Vector3(0.4,4.2,8.5),Color(0.32,0.27,0.24))
	for z in [-8.0,-3.0,2.0,7.0]:
		_solid_box(Vector3(-21.3,1,z),Vector3(1.3,2,1.5),Color(0.10,0.13,0.18),true,2)
		_add_led_strip(Vector3(-21.3,1.62,z-0.76),Vector3(0.9,0.35,0.05),Color(0.05,0.7,1.0))
	_add_led_strip(Vector3(0,4.25,-21.55),Vector3(14,0.16,0.08),Color(1.0,0.12,0.08))
	_add_led_strip(Vector3(0,4.1,-12.15),Vector3(12,0.12,0.08),Color(0.04,0.72,1.0))
	# Repeated ceiling panels and beams define depth across the much larger room.
	for z in [-16.0,-9.0,-2.0,5.0,12.0,19.0]:
		_add_box_child(self,Vector3(0,4.78,z),Vector3(42,0.12,0.32),Color(0.22,0.18,0.14))
	# Colored wall banners and booth dividers enrich the dining area with few mesh calls.
	for x in [-18.0,-12.0,12.0,18.0]:
		_add_box_child(self,Vector3(x,1.55,-12.1),Vector3(2.2,1.1,0.09),Color(0.40,0.075,0.06))
		_add_led_strip(Vector3(x,2.15,-12.03),Vector3(1.75,0.035,0.03),Color(1.0,0.30,0.07))
	# Contrasting dado rails and colored booth panels make the dining room read as a place.
	_add_led_strip(Vector3(0,1.05,21.65),Vector3(32,0.08,0.06),Color(0.95,0.27,0.08))
	_add_led_strip(Vector3(-23.65,1.05,0),Vector3(0.06,0.08,32),Color(0.95,0.27,0.08))
	_add_led_strip(Vector3(23.65,1.05,0),Vector3(0.06,0.08,32),Color(0.95,0.27,0.08))
	for x in [-17.0,-8.5,0.0,8.5,17.0]:
		# Bright framed menu posters on walls, no extra lights/shadows.
		_add_box_child(self,Vector3(x,2.65,21.68),Vector3(2.3,1.5,0.06),Color(0.31,0.10,0.055))
		_add_box_child(self,Vector3(x,2.65,21.60),Vector3(2.0,1.22,0.06),Color(0.87,0.69,0.42))
	# Distinct kitchen fixtures: oven fronts and cooler doors.
	for x in [-20.0,-14.0,14.0,20.0]:
		_add_box_child(self,Vector3(x,0.88,-17.63),Vector3(1.25,0.78,0.04),Color(0.10,0.12,0.14))
		_add_led_strip(Vector3(x,1.42,-17.61),Vector3(1.0,0.035,0.03),Color(1.0,0.22,0.07))
	# Iconic two-tone checker trim inspired by the supplied restaurant reference.
	_add_checker_band(Vector3(0,2.75,21.68),Vector3(45.4,0.36,0.065),28,true)
	_add_checker_band(Vector3(-23.68,2.75,0),Vector3(0.065,0.36,40.0),25,false)
	# Party balloons with thin cords at the room corners, low polygon count.
	_add_balloon_cluster(Vector3(-20.5,0,-18.5))
	_add_balloon_cluster(Vector3(20.5,0,-18.5))
	_add_balloon_cluster(Vector3(-20.5,0,18.5))
	_add_balloon_cluster(Vector3(20.5,0,18.5))
	# Luces cálidas dispersas y focos de escenario.
	for p in [Vector3(-16,3.8,-6),Vector3(0,3.8,-6),Vector3(16,3.8,-6),Vector3(-16,3.8,8),Vector3(0,3.8,8),Vector3(16,3.8,8),Vector3(0,3.5,-17)]:
		var light := OmniLight3D.new()
		light.position = p
		light.light_color = Color(1.0,0.63,0.32)
		light.light_energy = 0.68
		light.omni_range = 14.0
		light.shadow_enabled = false
		add_child(light)
	# Neon strips with emissive material + subtle low-cost coloured light.
	_add_led_strip(Vector3(0,4.25,-12.55), Vector3(40,0.12,0.07), Color(0.05,0.88,1.0))
	_add_led_strip(Vector3(0,3.95,12.55), Vector3(36,0.10,0.06), Color(1.0,0.08,0.36))
	_add_led_strip(Vector3(-23.55,3.5,0), Vector3(0.07,0.10,40), Color(0.36,0.12,1.0))
	_add_led_strip(Vector3(23.55,3.5,0), Vector3(0.07,0.10,40), Color(0.05,0.82,0.62))

func _add_checker_band(center: Vector3, size: Vector3, count: int, horizontal: bool) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(size.x/float(count),size.y,size.z) if horizontal else Vector3(size.x,size.y,size.z/float(count))
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = box
	multi.instance_count = count
	for i in range(count):
		var offset := -size.x*0.5+(float(i)+0.5)*(size.x/float(count)) if horizontal else -size.z*0.5+(float(i)+0.5)*(size.z/float(count))
		var pos := center+Vector3(offset,0,0) if horizontal else center+Vector3(0,0,offset)
		multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,pos))
		multi.set_instance_color(i,Color(0.12,0.12,0.13) if i%2==0 else Color(0.73,0.70,0.63))
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = multi
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.82
	inst.material_override = mat
	add_child(inst)

func _add_balloon_cluster(origin: Vector3) -> void:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 20
	sphere.rings = 12
	sphere.radius = 0.34
	sphere.height = 0.78
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = sphere
	multi.instance_count = 4
	var colors := [Color(0.76,0.035,0.045),Color(0.86,0.65,0.035),Color(0.02,0.32,0.42),Color(0.52,0.035,0.16)]
	for i in range(4):
		var pos := origin+Vector3(float(i%2)*0.48-0.24,3.0+float(i%3)*0.38,-0.22+float(i/2)*0.38)
		multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,pos))
		multi.set_instance_color(i,colors[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = multi
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.28
	mat.metallic = 0.04
	inst.material_override = mat
	add_child(inst)

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
	mat.normal_scale = 0.22
	mat.roughness = rough
	var rough_name := path.get_file().replace("_albedo.jpg","_roughness.jpg")
	var rough_path := path.get_base_dir().path_join(rough_name)
	if ResourceLoader.exists(rough_path):
		mat.roughness_texture = load(rough_path) as Texture2D
		mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.uv1_scale = Vector3(6,6,1)
	return mat

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.collision_mask = 3
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
	camera.fov = 88
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
	# The Mimic DLC GLB, 32.7k triangles. Source forward axis is corrected below.
	animatronic = CharacterBody3D.new()
	animatronic.name = "The_Mimic_DLC"
	animatronic.collision_mask = 1
	animatronic.position = Vector3(0,0,-10)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.52
	shape.height = 2.55
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 1.28
	animatronic.add_child(collider)
	var packed := load("res://assets/models/the_mimic_dlc.glb") as PackedScene
	if packed:
		var model := packed.instantiate() as Node3D
		model.name = "TheMimicDLC_32kTriangles"
		model.position.y = 0.06
		model.scale = Vector3.ONE * 0.90
		model.rotation.y = PI
		animatronic.add_child(model)
		_apply_smooth_mimic_shader(model)
		anim_player = _find_animation_player(model)
		if anim_player:
			var idle_clip := _find_animation_name(anim_player,"Idle")
			if idle_clip != "": anim_player.play(idle_clip)
	else:
		push_warning("The Mimic GLB unavailable; placeholder fallback used.")
		_add_sphere(animatronic,Vector3(0,0.9,0),Vector3(0.42,0.65,0.35),Color(0.26,0.12,0.11))
	add_child(animatronic)

func _apply_smooth_mimic_shader(node: Node) -> void:
	# Retains the model's own texture while using a roughness-tuned smooth PBR shader.
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var source := mesh_instance.get_active_material(surface) as StandardMaterial3D
			if source:
				if source.albedo_texture != null:
					var shader_material := ShaderMaterial.new()
					shader_material.shader = load("res://assets/shaders/mimic_smooth.gdshader") as Shader
					shader_material.set_shader_parameter("albedo_tex",source.albedo_texture)
					shader_material.set_shader_parameter("base_tint",source.albedo_color)
					shader_material.set_shader_parameter("roughness_value",0.42)
					shader_material.set_shader_parameter("metallic_value",0.24)
					shader_material.set_shader_parameter("normal_tex",source.normal_texture)
					shader_material.set_shader_parameter("has_normal_tex",source.normal_enabled and source.normal_texture != null)
					mesh_instance.set_surface_override_material(surface,shader_material)
				else:
					var smooth_mat := source.duplicate() as StandardMaterial3D
					smooth_mat.roughness = 0.42
					smooth_mat.metallic = 0.24
					mesh_instance.set_surface_override_material(surface,smooth_mat)
	for child in node.get_children(): _apply_smooth_mimic_shader(child)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result:
			return result
	return null

func _find_animation_name(player_node: AnimationPlayer, fragment: String) -> String:
	for clip in player_node.get_animation_list():
		if clip.contains(fragment): return clip
	return ""

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 2
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
	hud.add_theme_font_size_override("font_size", 23)
	hud.add_theme_color_override("font_color", Color(1.0,0.89,0.68))
	root.add_child(hud)
	threat_label = Label.new()
	threat_label.anchor_left = 0.70
	threat_label.anchor_right = 0.98
	threat_label.anchor_top = 0.025
	threat_label.anchor_bottom = 0.11
	threat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	threat_label.add_theme_font_size_override("font_size", 21)
	threat_label.add_theme_color_override("font_color", Color(1.0,0.38,0.28))
	root.add_child(threat_label)
	stick_radius = 104.0
	stick_base = Panel.new()
	stick_base.name = "JoystickBase"
	stick_base.size = Vector2(208,208)
	stick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.04,0.055,0.07,0.42)
	base_style.set_corner_radius_all(96)
	base_style.border_color = Color(0.82,0.86,0.9,0.82)
	base_style.set_border_width_all(3)
	base_style.shadow_color = Color(0,0,0,0.4)
	base_style.shadow_size = 8
	stick_base.add_theme_stylebox_override("panel",base_style)
	root.add_child(stick_base)
	stick_knob = Panel.new()
	stick_knob.name = "JoystickKnob"
	stick_knob.size = Vector2(84,84)
	stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.83,0.87,0.9,0.9)
	knob_style.set_corner_radius_all(42)
	knob_style.border_color = Color(1,1,1,0.85)
	knob_style.set_border_width_all(2)
	stick_knob.add_theme_stylebox_override("panel",knob_style)
	root.add_child(stick_knob)
	var initial_size := get_viewport().get_visible_rect().size
	stick_center = Vector2(156,initial_size.y - 156)
	_update_stick_visual()
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
	ambience_player = AudioStreamPlayer.new()
	ambience_player.stream = load("res://assets/audio/pizzeria_horror_ambience.mp3")
	ambience_player.volume_db = -19.0
	add_child(ambience_player)
	ambience_player.finished.connect(func():
		if game_started: ambience_player.play()
	)
	footstep_a = AudioStreamPlayer.new()
	footstep_a.stream = load("res://assets/audio/player_step.ogg")
	footstep_a.volume_db = -13.0
	add_child(footstep_a)
	footstep_b = AudioStreamPlayer.new()
	footstep_b.stream = load("res://assets/audio/player_step.ogg")
	footstep_b.volume_db = -13.0
	add_child(footstep_b)
	footstep_player = footstep_a
	robot_step_a = _make_robot_step_player(-1.0)
	robot_step_b = _make_robot_step_player(-1.0)
	stomp_player = robot_step_a
	flashlight_audio = AudioStreamPlayer.new()
	flashlight_audio.stream = load("res://assets/audio/flashlight_click.mp3")
	flashlight_audio.volume_db = -4.0
	add_child(flashlight_audio)
	horror_player = AudioStreamPlayer.new()
	horror_player.stream = load("res://assets/audio/horror_sting.mp3")
	horror_player.volume_db = -15.0
	add_child(horror_player)
	monster_growl_player = AudioStreamPlayer3D.new()
	monster_growl_player.stream = load("res://assets/audio/monster_growl.mp3")
	monster_growl_player.volume_db = -11.0
	monster_growl_player.max_distance = 24.0
	monster_growl_player.unit_size = 6.0
	animatronic.add_child(monster_growl_player)
	toy_voice_player = AudioStreamPlayer3D.new()
	toy_voice_player.stream = load("res://assets/audio/toy_hello.mp3")
	toy_voice_player.volume_db = -8.0
	toy_voice_player.max_distance = 32.0
	toy_voice_player.unit_size = 8.0
	animatronic.add_child(toy_voice_player)
	laugh_player = AudioStreamPlayer3D.new()
	laugh_player.stream = load("res://assets/audio/toy_giggle.mp3")
	laugh_player.volume_db = -10.0
	laugh_player.max_distance = 26.0
	laugh_player.unit_size = 6.0
	animatronic.add_child(laugh_player)
	laugh_alt_player = AudioStreamPlayer3D.new()
	laugh_alt_player.stream = load("res://assets/audio/creepy_laugh.mp3")
	laugh_alt_player.volume_db = -10.0
	laugh_alt_player.max_distance = 26.0
	laugh_alt_player.unit_size = 6.0
	animatronic.add_child(laugh_alt_player)

func _make_robot_step_player(vol: float) -> AudioStreamPlayer3D:
	var player_node := AudioStreamPlayer3D.new()
	player_node.stream = load("res://assets/audio/robot_step.ogg")
	player_node.volume_db = vol
	player_node.max_distance = 24.0
	player_node.unit_size = 6.0
	animatronic.add_child(player_node)
	return player_node

func _build_lobby() -> void:
	# Keep the main camera selected but stop the whole play world until START.
	player.get_node("LookPivot").rotation.x = -0.08
	player.rotation.y = 0.0
	lobby_layer = CanvasLayer.new()
	lobby_layer.layer = 10
	add_child(lobby_layer)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.012,0.016,0.022,0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	lobby_layer.add_child(shade)
	var title := Label.new()
	title.text = "NOCHE EN LA PIZZERÍA"
	title.anchor_left = 0.15; title.anchor_right = 0.85
	title.anchor_top = 0.16; title.anchor_bottom = 0.31
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",42)
	title.add_theme_color_override("font_color",Color(0.97,0.80,0.52))
	lobby_layer.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "PASEA POR LA PIZZERÍA • SOBREVIVE A THE MIMIC"
	subtitle.anchor_left = 0.12; subtitle.anchor_right = 0.88
	subtitle.anchor_top = 0.32; subtitle.anchor_bottom = 0.42
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size",19)
	subtitle.add_theme_color_override("font_color",Color(0.80,0.79,0.74))
	lobby_layer.add_child(subtitle)
	var start_button := _make_button(shade,"ENTRAR A LA PIZZERÍA",Vector2(0,0),Vector2(360,76))
	start_button.anchor_left = 0.5; start_button.anchor_right = 0.5
	start_button.anchor_top = 0.58; start_button.anchor_bottom = 0.58
	start_button.position = Vector2(-180,0)
	start_button.add_theme_font_size_override("font_size",23)
	start_button.pressed.connect(_start_game)
	var credit := Label.new()
	credit.text = "THE MIMIC • FAN GAME GRATUITO • MODO MÓVIL"
	credit.anchor_left = 0.12; credit.anchor_right = 0.88
	credit.anchor_top = 0.84; credit.anchor_bottom = 0.94
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	credit.add_theme_font_size_override("font_size",15)
	credit.add_theme_color_override("font_color",Color(0.58,0.59,0.62))
	lobby_layer.add_child(credit)
	hud_layer.visible = false

func _start_game() -> void:
	if game_started: return
	game_started = true
	hud_layer.visible = true
	lobby_layer.queue_free()
	ambience_player.play()
	horror_player.play()
	voice_timer = 22.0

func _input(event: InputEvent) -> void:
	if not game_started or caught: return
	if event is InputEventScreenTouch:
		if event.pressed:
			var viewport_size := get_viewport().get_visible_rect().size
			var left_control_zone: bool = event.position.x < viewport_size.x * 0.50 and event.position.y > viewport_size.y * 0.40
			if left_control_zone:
				# Solo el primer dedo de la zona izquierda captura el joystick.
				# Un segundo dedo allí no roba el stick ni bloquea el movimiento.
				if touch_stick_id == -1:
					touch_stick_id = event.index
					stick_center = event.position
					stick_vector = Vector2.ZERO
					_update_stick_visual()
			else:
				# El dedo derecho puede girar la cámara mientras el stick sigue pulsado.
				var bottom_right_buttons: bool = event.position.x > viewport_size.x * 0.70 and event.position.y > viewport_size.y * 0.78
				if touch_look_id == -1 and not bottom_right_buttons:
					touch_look_id = event.index
					last_look_pos = event.position
		else:
			if event.index == touch_stick_id:
				touch_stick_id = -1
				stick_vector = Vector2.ZERO
				var vp := get_viewport().get_visible_rect().size
				stick_center = Vector2(156,vp.y-156)
				_update_stick_visual()
			if event.index == touch_look_id:
				touch_look_id = -1
	elif event is InputEventScreenDrag:
		if event.index == touch_stick_id:
			stick_vector = ((event.position - stick_center) / stick_radius).limit_length(1.0)
			_update_stick_visual()
		elif event.index == touch_look_id:
			var look_change: Vector2 = event.position - last_look_pos
			look_delta += look_change
			last_look_pos = event.position

func _update_stick_visual() -> void:
	if not is_instance_valid(stick_base) or not is_instance_valid(stick_knob): return
	stick_base.position = stick_center - Vector2(104,104)
	stick_knob.position = stick_center - Vector2(stick_knob_radius,stick_knob_radius) + stick_vector * 58.0

func _process(delta: float) -> void:
	if not game_started or caught: return
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
			player_step_flip = not player_step_flip
			footstep_player = footstep_b if player_step_flip else footstep_a
			if not footstep_player.playing:
				footstep_player.pitch_scale = randf_range(0.96,1.04)
				footstep_player.play()
			walk_timer = (0.40 if sprinting else 0.57) / (1.0 + minf(elapsed / 150.0,0.35))
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
			var wanted := _find_animation_name(anim_player,"RunA")
			var cycle_length := 0.62
			if distance > 8.0:
				wanted = _find_animation_name(anim_player,"Walk_SK")
				cycle_length = 1.29
			if wanted != "" and anim_player.current_animation != wanted:
				anim_player.play(wanted,0.18)
				anim_step_timer = 0.0
			anim_player.speed_scale = 1.0 + minf(elapsed/150.0,0.35)
			anim_step_timer -= delta
			if anim_step_timer <= 0.0 and distance < 24.0 and animatronic.velocity.length() > 0.35:
				# Two alternating channels align the stomp rhythm to the imported clip.
				var animation_interval := (cycle_length * 0.5) / maxf(anim_player.speed_scale,0.1)
				stomp_player = robot_step_b if stomp_player == robot_step_a else robot_step_a
				if not stomp_player.playing:
					stomp_player.pitch_scale = clampf(1.0-distance*0.004,0.82,1.04)
					stomp_player.volume_db = clampf(-19.0+((24.0-distance)/24.0)*17.0,-19.0,-2.0)
					stomp_player.play()
				anim_step_timer = animation_interval
	# Long-gap sting keeps the ambience tense without constant loud sounds.
	horror_timer -= delta
	if horror_timer <= 0.0 and not horror_player.playing:
		horror_player.pitch_scale = randf_range(0.88,1.04)
		horror_player.play()
		horror_timer = randf_range(46.0,70.0)
	# Spatial toy voice / laugh cues at a slow randomized cadence, never overlap each other.
	voice_timer -= delta
	if voice_timer <= 0.0 and distance < 28.0 and not toy_voice_player.playing and not laugh_player.playing and not laugh_alt_player.playing and not monster_growl_player.playing:
		var cue := randf()
		if cue < 0.34:
			toy_voice_player.pitch_scale = randf_range(0.88,1.06)
			toy_voice_player.play()
		elif cue < 0.63:
			laugh_player.play()
		elif cue < 0.84:
			laugh_alt_player.play()
		else:
			monster_growl_player.play()
		voice_timer = randf_range(20.0,32.0)
	if distance < 1.7:
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
	if game_started and flashlight_audio and not flashlight_audio.playing: flashlight_audio.play()

func _caught_player() -> void:
	caught = true
	footstep_a.stop()
	footstep_b.stop()
	robot_step_a.stop()
	robot_step_b.stop()
	toy_voice_player.stop()
	laugh_player.stop()
	laugh_alt_player.stop()
	monster_growl_player.stop()
	ambience_player.stop()
	flashlight_audio.stop()
	horror_player.stop()
	horror_player.play()
	var to_player := player.global_position - animatronic.global_position
	if to_player.length_squared() < 0.001: to_player = -player.global_transform.basis.z
	animatronic.global_position = player.global_position - to_player.normalized() * 0.85
	animatronic.look_at(Vector3(player.global_position.x,animatronic.global_position.y,player.global_position.z),Vector3.UP)
	if anim_player:
		var scare := _find_animation_name(anim_player,"JumpscareFrontA")
		if scare != "": anim_player.play(scare,0.08)
	var c := overlay.color
	c.a = 0.72
	overlay.color = c
	hud.text = "¡TE ATRAPÓ!  •  TOCA PARA REINTENTAR"
	threat_label.text = "FIN DE LA NOCHE"
	var restart := _make_button(hud_layer.get_child(0),"REINTENTAR",Vector2(-115,-42),Vector2(230,72))
	restart.anchor_left = 0.5; restart.anchor_right = 0.5
	restart.anchor_top = 0.52; restart.anchor_bottom = 0.52
	restart.pressed.connect(func(): get_tree().reload_current_scene())

func _add_cylinder(pos: Vector3, radius: float, height: float, color: Color, segments: int = 16) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = maxi(segments, 24)
	cylinder.rings = 2
	mesh.mesh = cylinder
	mesh.position = pos
	mesh.material_override = _material(color)
	add_child(mesh)

func _add_pipe_run(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var pipe := CylinderMesh.new()
	pipe.top_radius = size.y * 0.5
	pipe.bottom_radius = size.y * 0.5
	pipe.height = size.x
	pipe.radial_segments = 32
	pipe.rings = 2
	mesh.mesh = pipe
	mesh.position = pos
	mesh.rotation.z = PI * 0.5
	mesh.material_override = _material(color)
	add_child(mesh)

func _solid_box(pos: Vector3, size: Vector3, color: Color, collides: bool = true, collision_layer: int = 1) -> MeshInstance3D:
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
		body.collision_layer = collision_layer
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
	sphere.radial_segments = 24
	sphere.rings = 16
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
