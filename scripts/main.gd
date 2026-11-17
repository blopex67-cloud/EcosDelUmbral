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
var led_material_cache: Dictionary = {}
var led_instance_data: Dictionary = {}
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
var ai_route_points: Array[Vector3] = []
var ai_route_index := 0
var ai_repath_timer := 0.0
var ai_stuck_timer := 0.0
var ai_steer_sign := 1.0
var hud_top_panel: Panel
var hud_center_label: Label
var camera_filter_enabled := true
var camera_filter_overlay: ColorRect
var camera_filter_button: Button
const CCTV_FILTER_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
void fragment() {
 vec2 uv = SCREEN_UV;
 float rgb_shift = SCREEN_PIXEL_SIZE.x * 1.7;
 vec3 sampled;
 sampled.r = texture(screen_texture, uv + vec2(rgb_shift, 0.0)).r;
 sampled.g = texture(screen_texture, uv).g;
 sampled.b = texture(screen_texture, uv - vec2(rgb_shift, 0.0)).b;
 float gray = dot(sampled, vec3(0.299, 0.587, 0.114));
 vec3 monochrome = vec3(gray * 0.78, gray * 0.92, gray * 0.84);
 float scan = 0.92 + 0.08 * sin(uv.y * 720.0 * 3.14159);
 float noise = fract(sin(dot(floor(uv * vec2(420.0, 260.0)) + vec2(TIME * 31.0), vec2(12.9898,78.233))) * 43758.5453);
 float grain = (noise - 0.5) * 0.055;
 float vignette = smoothstep(1.1, 0.22, length((uv - 0.5) * vec2(1.0,0.88)));
 float interference = step(0.998, fract(TIME * 0.17)) * step(0.88, noise) * 0.12;
 vec3 cctv = (monochrome * scan + grain + interference) * (0.64 + 0.36 * vignette);
 COLOR = vec4(mix(sampled, cctv, 0.92), 1.0);
}
"""

func _ready() -> void:
	print("PIZZERIA_FREE_SCENE_READY")
	_build_world()
	_build_player()
	_build_animatronic()
	_build_hud()
	_setup_audio()
	_validate_loaded_audio()
	_build_lobby()

func _build_world() -> void:
	print("PIZZERIA_CORRIDORS_V2_READY")
	print("PIZZERIA_FNAF_STYLE_LAYOUT_READY")
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.006,0.008,0.009)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.46,0.43,0.37)
	env.ambient_light_energy = 0.54
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.24
	env.glow_bloom = 0.035
	env_node.environment = env
	add_child(env_node)
	floor_mat = _texture_material("res://assets/textures/floor_checker.jpg","res://assets/textures/floor_checker_normal.jpg",0.91)
	floor_mat.uv1_scale = Vector3(18.0,18.0,1.0)
	wall_mat = _texture_material("res://assets/textures/wall_albedo.jpg","res://assets/textures/wall_normal.jpg",0.88)
	wall_mat.uv1_scale = Vector3(24.0,8.0,1.0)
	wood_mat = _texture_material("res://assets/textures/wood_albedo.jpg","res://assets/textures/wood_normal.jpg",0.68)
	wood_mat.uv1_scale = Vector3(8.0,8.0,1.0)
	# One continuous enclosed footprint: 56 x 56 m; consistent floor/ceiling removes black gaps.
	var floor := _solid_box(Vector3(0,-0.30,2),Vector3(56,0.60,56),Color.WHITE,true)
	floor.material_override = floor_mat
	var ceiling := _solid_box(Vector3(0,5.28,2),Vector3(56,0.38,56),Color(0.12,0.105,0.09),false)
	ceiling.material_override = _material(Color(0.12,0.105,0.09))
	# The dining room is central. Stage/back hall is north; security office is south.
	# Solid outer envelope and continuous walls are split only at real, aligned doorways.
	var wall_y := 2.48
	var wall_h := 4.96
	var wall_t := 0.42
	var wall_segments: Array[Array] = [
		# west and east perimeter walls, full length
		[Vector3(-27.79,wall_y,2),Vector3(wall_t,wall_h,55.6)],[Vector3(27.79,wall_y,2),Vector3(wall_t,wall_h,55.6)],
		# north wall with aligned passage into backstage at x=-4..4
		[Vector3(-16,wall_y,-25.79),Vector3(23.6,wall_h,wall_t)],[Vector3(16,wall_y,-25.79),Vector3(23.6,wall_h,wall_t)],
		# south perimeter
		[Vector3(0,wall_y,29.79),Vector3(55.6,wall_h,wall_t)],
		# dining room west partition with one door into west hall
		[Vector3(-20,wall_y,-9.0),Vector3(wall_t,wall_h,10.0)],[Vector3(-20,wall_y,7.5),Vector3(wall_t,wall_h,9.0)],
		# dining room east partition with matching east-hall door
		[Vector3(20,wall_y,-9.0),Vector3(wall_t,wall_h,10.0)],[Vector3(20,wall_y,7.5),Vector3(wall_t,wall_h,9.0)],
		# north dining wall: opening to the back corridor, centered on the stage
		[Vector3(-12.25,wall_y,-14),Vector3(15.5,wall_h,wall_t)],[Vector3(12.25,wall_y,-14),Vector3(15.5,wall_h,wall_t)],
		# south dining wall: central access to security corridor
		[Vector3(-11.5,wall_y,12),Vector3(17.0,wall_h,wall_t)],[Vector3(11.5,wall_y,12),Vector3(17.0,wall_h,wall_t)],
		# back corridor side walls (x -6..6), from stage to north service room
		[Vector3(-6,wall_y,-20),Vector3(wall_t,wall_h,12.0)],[Vector3(6,wall_y,-20),Vector3(wall_t,wall_h,12.0)],
		# stage/back corridor end walls: doorway at north, stage-side opening at south
		[Vector3(-8.0,wall_y,-14),Vector3(4.0,wall_h,wall_t)],[Vector3(8.0,wall_y,-14),Vector3(4.0,wall_h,wall_t)],
		# west/east side hallway caps at the back: doors feed the back corridor loop
		[Vector3(-26.40,wall_y,-14),Vector3(2.8,wall_h,wall_t)],[Vector3(-21.60,wall_y,-14),Vector3(2.8,wall_h,wall_t)],
		[Vector3(26.40,wall_y,-14),Vector3(2.8,wall_h,wall_t)],[Vector3(21.60,wall_y,-14),Vector3(2.8,wall_h,wall_t)],
		# security office walls; entrance centered from dining through its short hall
		[Vector3(-12,wall_y,24),Vector3(wall_t,wall_h,11.6)],[Vector3(12,wall_y,24),Vector3(wall_t,wall_h,11.6)],
		[Vector3(-8.0,wall_y,18),Vector3(8.0,wall_h,wall_t)],[Vector3(8.0,wall_y,18),Vector3(8.0,wall_h,wall_t)],
		# side-office access openings connect to a 4 m cross-corridor on each wing
		[Vector3(-16,wall_y,20),Vector3(8.0,wall_h,wall_t)],[Vector3(-16,wall_y,28),Vector3(8.0,wall_h,wall_t)],
		[Vector3(16,wall_y,20),Vector3(8.0,wall_h,wall_t)],[Vector3(16,wall_y,28),Vector3(8.0,wall_h,wall_t)],
		# central security corridor side walls; it opens at both ends
		[Vector3(-4,wall_y,15),Vector3(wall_t,wall_h,6.0)],[Vector3(4,wall_y,15),Vector3(wall_t,wall_h,6.0)],
		# service alcove walls inside the back room, each door 2.5 m wide
		[Vector3(-15,wall_y,-21),Vector3(18.0,wall_h,wall_t)],[Vector3(15,wall_y,-21),Vector3(18.0,wall_h,wall_t)]
	]
	for entry in wall_segments:
		var segment := _solid_box(entry[0],entry[1],Color.WHITE,true)
		segment.material_override = wall_mat
	# Polished matching baseboards/cap rails follow each real wall segment and keep all doorways open.
	var skirting_mat := _material(Color(0.13,0.105,0.083))
	var caprail_mat := _material(Color(0.19,0.15,0.12))
	for entry in wall_segments:
		var wpos: Vector3 = entry[0]
		var wsz: Vector3 = entry[1]
		var rail_size := Vector3(wsz.x+0.06,0.16,wsz.z+0.06)
		for rail_y in [0.12,4.82]:
			var rail := _add_box_child(self,Vector3(wpos.x,rail_y,wpos.z),rail_size,Color.WHITE)
			if rail_y < 1.0: rail.material_override = skirting_mat
			else: rail.material_override = caprail_mat
	# Stage deck, aligned curtain wall, kitchen windows and prep counter.
	var stage := _solid_box(Vector3(0,0.38,-11.0),Vector3(17.5,0.76,4.8),Color.WHITE,true,2)
	stage.material_override = wood_mat
	for x in [-8.5,-6.8,6.8,8.5]:
		var curtain := _solid_box(Vector3(x,2.65,-13.45),Vector3(1.35,3.7,0.18),Color(0.24,0.018,0.03),false)
		curtain.material_override = _material(Color(0.25,0.018,0.028))
	var backstage_counter := _solid_box(Vector3(0,0.9,-19.0),Vector3(8.0,1.8,1.0),Color(0.38,0.39,0.38),true,2)
	backstage_counter.material_override = _material(Color(0.28,0.30,0.30))
	# Original dining room props and two shared low-poly furniture meshes.
	_solid_box(Vector3(0,0.55,-8.3),Vector3(8.0,1.1,1.0),Color(0.23,0.14,0.09),true)
	_solid_box(Vector3(-9.5,0.55,-8.3),Vector3(6.0,1.1,1.0),Color(0.23,0.14,0.09),true)
	_solid_box(Vector3(9.5,0.55,-8.3),Vector3(6.0,1.1,1.0),Color(0.23,0.14,0.09),true)
	_build_dining_furniture()
	_build_original_party_props()
	_build_original_stage_set()
	# Security office desk and cabinet; wall-supported labels distinguish spaces.
	var desk := _solid_box(Vector3(0,0.62,23.2),Vector3(5.8,1.24,1.1),Color(0.16,0.14,0.12),true,2)
	_add_box_child(self,Vector3(0,1.28,23.2),Vector3(5.9,0.10,1.18),Color(0.28,0.25,0.21))
	_add_box_child(self,Vector3(-6.3,1.35,26.8),Vector3(1.2,2.7,0.7),Color(0.13,0.16,0.17))
	_add_box_child(self,Vector3(6.3,1.35,26.8),Vector3(1.2,2.7,0.7),Color(0.13,0.16,0.17))
	# Practical lights spaced to make walls readable; no real-time shadows on Android.
	for lp in [Vector3(-15,4.55,-3),Vector3(0,4.55,-3),Vector3(15,4.55,-3),Vector3(-15,4.55,8),Vector3(15,4.55,8),Vector3(0,4.55,15),Vector3(0,4.55,23),Vector3(-24,4.55,3),Vector3(24,4.55,3),Vector3(-24,4.55,17),Vector3(24,4.55,17),Vector3(0,4.55,-19)]:
		var light := OmniLight3D.new()
		light.position = lp
		light.light_color = Color(0.77,0.64,0.47)
		light.light_energy = 0.48
		light.omni_range = 8.5
		light.shadow_enabled = false
		add_child(light)
	# Built-in LEDs trace the office edges, dining-room trim and stage; filter is independent.
	for x in [-20.0,-12.0,0.0,12.0,20.0]:
		_add_led_strip(Vector3(x,3.65,-13.72),Vector3(3.4,0.045,0.06),Color(0.88,0.045,0.055))
		_add_led_strip(Vector3(x,0.95,11.70),Vector3(4.0,0.055,0.045),Color(0.02,0.60,0.78))
	for z in [-10.0,0.0,8.0,15.0,23.0]:
		_add_led_strip(Vector3(-19.72,1.08,z),Vector3(0.055,0.055,5.0),Color(0.90,0.08,0.06))
		_add_led_strip(Vector3(19.72,1.08,z),Vector3(0.055,0.055,5.0),Color(0.02,0.62,0.80))
	_add_led_strip(Vector3(-11.72,0.98,24),Vector3(0.06,0.045,8.0),Color(0.95,0.18,0.03))
	_add_led_strip(Vector3(11.72,0.98,24),Vector3(0.06,0.045,8.0),Color(0.95,0.18,0.03))
	_add_led_strip(Vector3(0,1.02,18.30),Vector3(7.5,0.05,0.06),Color(0.95,0.12,0.035))
	_add_led_strip(Vector3(0,1.02,29.52),Vector3(24.0,0.05,0.06),Color(0.96,0.11,0.035))
	_flush_led_strips()
	print("ENCLOSED_FNAF_INSPIRED_MAP_READY dining=1 stage=1 back_hall=1 security_office=1 connected_halls=2")

func _build_original_stage_set() -> void:
	# Layered velvet-like curtains and custom backstage sign, no franchise branding.
	for x in [-8.5,-6.8,6.8,8.5]:
		var panel := _solid_box(Vector3(x,2.7,-13.95),Vector3(1.45,3.6,0.20),Color(0.37,0.025,0.045),false)
		panel.material_override = _material(Color(0.30,0.015,0.025))
	for x in [-8.8,8.8]:
		_add_box_child(self,Vector3(x,3.0,-13.8),Vector3(0.3,4.2,0.45),Color(0.68,0.44,0.18))
	_add_box_child(self,Vector3(0,4.3,-13.8),Vector3(17.2,0.26,0.35),Color(0.55,0.34,0.14))
	_add_box_child(self,Vector3(0,4.0,-13.72),Vector3(5.8,0.72,0.12),Color(0.11,0.12,0.12))
	# Lettering is original generic text, not a FNAF logo or protected artwork.
	var sign := Label3D.new()
	sign.text = "PARTY STAGE"
	sign.font_size = 42
	sign.pixel_size = 0.012
	sign.modulate = Color(0.91,0.72,0.42)
	sign.position = Vector3(0,4.0,-13.62)
	sign.rotation.y = PI
	add_child(sign)

func _build_dining_furniture() -> void:
	# Flat-shaded, untextured CC0-style furniture meshes: low triangle count and one draw per type via MultiMesh.
	var table_mesh := _make_box_furniture_mesh("table")
	var chair_mesh := _make_box_furniture_mesh("chair")
	if table_mesh == null or chair_mesh == null:
		push_error("LOWPOLY_FURNITURE_MESH_BUILD_FAILED")
		return
	var table_positions: Array[Vector3] = [
		Vector3(-16,0,-3), Vector3(-8,0,-3), Vector3(0,0,-3), Vector3(8,0,-3), Vector3(16,0,-3),
		Vector3(-16,0,6), Vector3(-8,0,6), Vector3(0,0,6), Vector3(8,0,6), Vector3(16,0,6)]
	var tables := MultiMesh.new()
	tables.transform_format = MultiMesh.TRANSFORM_3D
	tables.mesh = table_mesh
	tables.instance_count = table_positions.size()
	for i in range(table_positions.size()):
		var p: Vector3 = table_positions[i]
		tables.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
		_add_static_box_collision(p + Vector3(0,0.43,0), Vector3(2.18,0.86,1.25), "LowPolyTableCollider_%02d" % i)
	var table_instance := MultiMeshInstance3D.new()
	table_instance.name = "LowPolyCC0DiningTables"
	table_instance.multimesh = tables
	add_child(table_instance)
	var chair_transforms: Array[Transform3D] = []
	for i in range(table_positions.size()):
		var p: Vector3 = table_positions[i]
		for side in [-1.0,1.0]:
			var chair_pos := p + Vector3(side*0.80,0,0.90)
			chair_transforms.append(Transform3D(Basis(Vector3.UP, PI), chair_pos))
			_add_static_box_collision(chair_pos + Vector3(0,0.46,0), Vector3(0.50,0.92,0.54), "LowPolyChairCollider_%02d_%s" % [i,"L" if side < 0.0 else "R"])
	var chairs := MultiMesh.new()
	chairs.transform_format = MultiMesh.TRANSFORM_3D
	chairs.mesh = chair_mesh
	chairs.instance_count = chair_transforms.size()
	for i in range(chair_transforms.size()): chairs.set_instance_transform(i, chair_transforms[i])
	var chair_instance := MultiMeshInstance3D.new()
	chair_instance.name = "LowPolyCC0DiningChairs"
	chair_instance.multimesh = chairs
	add_child(chair_instance)
	print("LOWPOLY_FURNITURE_READY tables=%d chairs=%d table_triangles=72 chair_triangles=72 draw_calls=2" % [table_positions.size(),chair_transforms.size()])

func _make_box_furniture_mesh(kind: String) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if kind == "table":
		_add_colored_box(surface,Vector3(0,0.78,0),Vector3(2.24,0.12,1.28),Color(0.56,0.32,0.17))
		_add_colored_box(surface,Vector3(0,0.69,0),Vector3(2.05,0.08,1.12),Color(0.30,0.13,0.075))
		_add_colored_box(surface,Vector3(-0.98,0.38,-0.49),Vector3(0.10,0.76,0.10),Color(0.23,0.15,0.11))
		_add_colored_box(surface,Vector3(0.98,0.38,-0.49),Vector3(0.10,0.76,0.10),Color(0.23,0.15,0.11))
		_add_colored_box(surface,Vector3(-0.98,0.38,0.49),Vector3(0.10,0.76,0.10),Color(0.23,0.15,0.11))
		_add_colored_box(surface,Vector3(0.98,0.38,0.49),Vector3(0.10,0.76,0.10),Color(0.23,0.15,0.11))
	else:
		_add_colored_box(surface,Vector3(0,0.48,0),Vector3(0.56,0.12,0.54),Color(0.58,0.13,0.09))
		_add_colored_box(surface,Vector3(0,0.83,0.22),Vector3(0.56,0.62,0.10),Color(0.49,0.085,0.065))
		for x in [-0.21,0.21]:
			for z in [-0.20,0.20]:
				_add_colored_box(surface,Vector3(x,0.23,z),Vector3(0.075,0.46,0.075),Color(0.22,0.16,0.12))
	surface.generate_normals()
	var mesh := surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.84
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0,material)
	return mesh

func _add_colored_box(surface: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var h := size * 0.5
	var faces := [
		[Vector3.RIGHT,Vector3(h.x,-h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3(h.x,h.y,h.z),Vector3(h.x,-h.y,h.z)],
		[Vector3.LEFT,Vector3(-h.x,-h.y,h.z),Vector3(-h.x,h.y,h.z),Vector3(-h.x,h.y,-h.z),Vector3(-h.x,-h.y,-h.z)],
		[Vector3.UP,Vector3(-h.x,h.y,-h.z),Vector3(-h.x,h.y,h.z),Vector3(h.x,h.y,h.z),Vector3(h.x,h.y,-h.z)],
		[Vector3.DOWN,Vector3(-h.x,-h.y,h.z),Vector3(-h.x,-h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,-h.y,h.z)],
		[Vector3.BACK,Vector3(h.x,-h.y,h.z),Vector3(h.x,h.y,h.z),Vector3(-h.x,h.y,h.z),Vector3(-h.x,-h.y,h.z)],
		[Vector3.FORWARD,Vector3(-h.x,-h.y,-h.z),Vector3(-h.x,h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3(h.x,-h.y,-h.z)]]
	for face in faces:
		var normal: Vector3 = face[0]
		var a: Vector3 = face[1] + center
		var b: Vector3 = face[2] + center
		var c: Vector3 = face[3] + center
		var d: Vector3 = face[4] + center
		for vertex in [a,b,c,a,c,d]:
			surface.set_color(color)
			surface.add_vertex(vertex)

func _add_static_box_collision(pos: Vector3, size: Vector3, node_name: String) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func _build_original_party_props() -> void:
	# Original generic party decorations — no FNAF character shapes, logos or copied art.
	var banner_colors := [Color(0.63,0.035,0.055), Color(0.90,0.59,0.18), Color(0.045,0.25,0.31), Color(0.60,0.55,0.44)]
	for i in range(8):
		var x := -16.0 + float(i) * 4.6
		var y := 3.55 + (0.34 if i % 2 == 0 else 0.0)
		_add_party_triangle(Vector3(x,y,21.55),banner_colors[i % banner_colors.size()])
	# Hand-painted birthday bunting and star shapes across the stage; bespoke procedural props.
	for i in range(5):
		var x := -7.2 + float(i) * 3.6
		_add_box_child(self,Vector3(x,3.1,-13.82),Vector3(2.65,0.075,0.06),Color(0.19,0.12,0.10))
		_add_star_prop(Vector3(x,3.55,-13.75),0.32,banner_colors[i % banner_colors.size()])
	# Old stage monitors, microphone stands and generic animal-mask silhouettes, all original.
	for side in [-1.0,1.0]:
		var speaker := _solid_box(Vector3(side * 8.1,1.2,-11.0),Vector3(1.0,2.2,0.75),Color(0.12,0.14,0.15),false)
		_add_box_child(self,Vector3(side * 8.1,1.2,-10.6),Vector3(0.66,1.45,0.04),Color(0.22,0.24,0.23))
		_add_cylinder(Vector3(side * 2.8,1.38,-10.8),0.035,2.65,Color(0.38,0.38,0.36),24)
		_add_sphere(self,Vector3(side * 2.8,2.75,-10.8),Vector3(0.12,0.11,0.12),Color(0.06,0.06,0.06))
	# Generic stage mascot heads: distinct simple animal-like silhouettes, not franchise designs.
	_add_original_mascot_mask(Vector3(-4.8,2.25,-11.0),Color(0.42,0.20,0.12),0)
	_add_original_mascot_mask(Vector3(0.0,2.25,-11.0),Color(0.20,0.32,0.37),1)
	_add_original_mascot_mask(Vector3(4.8,2.25,-11.0),Color(0.40,0.35,0.19),2)
	# Crumpled party hats and boxed party snacks on selected tables.
	for i in [0,3,6,9]:
		var p: Vector3 = [Vector3(-16,0,-3),Vector3(-8,0,-3),Vector3(0,0,-3),Vector3(8,0,-3),Vector3(16,0,-3),Vector3(-16,0,6),Vector3(-8,0,6),Vector3(0,0,6),Vector3(8,0,6),Vector3(16,0,6)][i]
		_add_box_child(self,p+Vector3(-0.34,0.82,-0.14),Vector3(0.58,0.11,0.42),Color(0.45,0.16,0.07))
		_add_cylinder(p+Vector3(0.38,0.92,-0.1),0.12,0.16,banner_colors[i % banner_colors.size()],16)

func _add_party_triangle(pos: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.72,0.85,0.045)
	mesh.mesh = prism
	mesh.position = pos
	mesh.material_override = _material(color)
	add_child(mesh)

func _add_star_prop(pos: Vector3, size: float, color: Color) -> void:
	var star := _add_sphere(self,pos,Vector3(size,size,size*0.20),color)
	star.name = "OriginalPartyStar"

func _add_original_mascot_mask(pos: Vector3, color: Color, variant: int) -> void:
	var root := Node3D.new()
	root.name = "OriginalGenericMascotMask_%d" % variant
	root.position = pos
	add_child(root)
	_add_sphere(root,Vector3.ZERO,Vector3(0.42,0.48,0.20),color)
	var ear_scale := Vector3(0.13,0.25,0.11) if variant != 1 else Vector3(0.11,0.38,0.10)
	for side in [-1.0,1.0]:
		_add_sphere(root,Vector3(side*0.29,0.40,0),ear_scale,Color(color.r*0.7,color.g*0.7,color.b*0.7))
		_add_sphere(root,Vector3(side*0.15,0.04,0.185),Vector3(0.075,0.095,0.035),Color(0.83,0.78,0.60))
		_add_sphere(root,Vector3(side*0.15,0.04,0.215),Vector3(0.032,0.048,0.02),Color(0.025,0.025,0.02))
	_add_sphere(root,Vector3(0,-0.17,0.22),Vector3(0.24,0.12,0.08),Color(0.10,0.065,0.055))

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
	# Store transforms by color and render each color as one MultiMesh draw call.
	var key := color.to_html(false)
	if not led_instance_data.has(key): led_instance_data[key] = {"color":color,"transforms":[]}
	var basis := Basis(Vector3(size.x,0,0),Vector3(0,size.y,0),Vector3(0,0,size.z))
	led_instance_data[key]["transforms"].append(Transform3D(basis,pos))

func _flush_led_strips() -> void:
	var unit_box := BoxMesh.new()
	unit_box.size = Vector3.ONE
	for key in led_instance_data:
		var data: Dictionary = led_instance_data[key]
		var color: Color = data["color"]
		var transforms: Array = data["transforms"]
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.2
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		unit_box = unit_box.duplicate() as BoxMesh
		unit_box.material = material
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = unit_box
		multi.instance_count = transforms.size()
		for i in range(transforms.size()): multi.set_instance_transform(i,transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.name = "BatchedEmissiveLED_%s" % key
		instance.multimesh = multi
		add_child(instance)
	var led_count := 0
	for led_data in led_instance_data.values(): led_count += led_data["transforms"].size()
	print("BATCHED_EMISSIVE_LEDS_READY strips=%d colors=%d" % [led_count,led_instance_data.size()])
	led_instance_data.clear()

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
	player.floor_snap_length = 0.28
	player.safe_margin = 0.03
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
		push_error("MIMIC_GLB_LOAD_FAILED: res://assets/models/the_mimic_dlc.glb")
	add_child(animatronic)
	var loaded_mesh_count := _count_mesh_instances(animatronic)
	if packed != null and loaded_mesh_count > 0:
		print("MIMIC_MODEL_LOADED meshes=%d" % loaded_mesh_count)
	else:
		push_error("MIMIC_MODEL_HAS_NO_MESHES")
	print("AI_ROUTE_FOLLOWER_READY")

func _count_mesh_instances(node: Node) -> int:
	var count := 1 if node is MeshInstance3D and (node as MeshInstance3D).mesh != null else 0
	for child in node.get_children():
		count += _count_mesh_instances(child)
	return count

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
	camera_filter_overlay = ColorRect.new()
	camera_filter_overlay.name = "OptionalCCTVFilter"
	camera_filter_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	camera_filter_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camera_filter_overlay.visible = false
	var cctv_shader := Shader.new()
	cctv_shader.code = CCTV_FILTER_SHADER
	var cctv_material := ShaderMaterial.new()
	cctv_material.shader = cctv_shader
	camera_filter_overlay.material = cctv_material
	root.add_child(camera_filter_overlay)
	print("OPTIONAL_CCTV_FILTER_READY")
	print("CCTV_FILTER_DEFAULT_ON" if camera_filter_enabled else "CCTV_FILTER_DEFAULT_OFF")
	hud_top_panel = Panel.new()
	hud_top_panel.name = "SecurityMonitorHeader"
	hud_top_panel.anchor_left = 0.015
	hud_top_panel.anchor_right = 0.985
	hud_top_panel.anchor_top = 0.018
	hud_top_panel.anchor_bottom = 0.105
	hud_top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.008,0.009,0.009,0.77)
	header_style.border_color = Color(0.46,0.13,0.085,0.76)
	header_style.set_border_width_all(1)
	header_style.set_corner_radius_all(3)
	hud_top_panel.add_theme_stylebox_override("panel",header_style)
	root.add_child(hud_top_panel)
	hud = Label.new()
	hud.text = "12 AM  •  NOCHE 1"
	hud.anchor_left = 0.032
	hud.anchor_right = 0.31
	hud.anchor_top = 0.024
	hud.anchor_bottom = 0.098
	hud.add_theme_font_size_override("font_size", 19)
	hud.add_theme_color_override("font_color", Color(0.90,0.83,0.69))
	root.add_child(hud)
	hud_center_label = Label.new()
	hud_center_label.text = "CAM 01  •  REC ●"
	hud_center_label.anchor_left = 0.36
	hud_center_label.anchor_right = 0.64
	hud_center_label.anchor_top = 0.024
	hud_center_label.anchor_bottom = 0.098
	hud_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_center_label.add_theme_font_size_override("font_size",16)
	hud_center_label.add_theme_color_override("font_color",Color(0.78,0.73,0.63))
	root.add_child(hud_center_label)
	threat_label = Label.new()
	threat_label.anchor_left = 0.68
	threat_label.anchor_right = 0.968
	threat_label.anchor_top = 0.024
	threat_label.anchor_bottom = 0.098
	threat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	threat_label.add_theme_font_size_override("font_size", 17)
	threat_label.add_theme_color_override("font_color", Color(0.95,0.20,0.12))
	root.add_child(threat_label)
	stick_radius = 104.0
	stick_base = Panel.new()
	stick_base.name = "JoystickBase"
	stick_base.size = Vector2(208,208)
	stick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.015,0.018,0.018,0.72)
	base_style.set_corner_radius_all(96)
	base_style.border_color = Color(0.56,0.15,0.10,0.84)
	base_style.set_border_width_all(2)
	base_style.shadow_color = Color(0,0,0,0.4)
	base_style.shadow_size = 8
	stick_base.add_theme_stylebox_override("panel",base_style)
	root.add_child(stick_base)
	stick_knob = Panel.new()
	stick_knob.name = "JoystickKnob"
	stick_knob.size = Vector2(84,84)
	stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.72,0.66,0.54,0.96)
	knob_style.set_corner_radius_all(42)
	knob_style.border_color = Color(1,1,1,0.85)
	knob_style.set_border_width_all(2)
	stick_knob.add_theme_stylebox_override("panel",knob_style)
	root.add_child(stick_knob)
	var initial_size := get_viewport().get_visible_rect().size
	stick_center = Vector2(156,initial_size.y - 156)
	_update_stick_visual()
	camera_filter_button = _make_button(root,"CAM 01 ON",Vector2(-358,-145),Vector2(104,62))
	camera_filter_button.anchor_left = 1.0; camera_filter_button.anchor_right = 1.0
	camera_filter_button.tooltip_text = "El filtro de cámara de seguridad inicia activo"
	camera_filter_button.pressed.connect(_toggle_cctv_filter)
	var light_button := _make_button(root,"LINTERNA",Vector2(-244,-145),Vector2(112,62))
	light_button.anchor_left = 1.0; light_button.anchor_right = 1.0
	light_button.pressed.connect(_toggle_flashlight)
	var sprint_button := _make_button(root,"CORRER",Vector2(-122,-145),Vector2(104,62))
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
	b.add_theme_font_size_override("font_size",15)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012,0.014,0.014,0.90)
	style.border_color = Color(0.56,0.15,0.10,0.90)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	b.add_theme_stylebox_override("normal",style)
	b.add_theme_stylebox_override("pressed",style)
	root.add_child(b)
	return b

func _setup_audio() -> void:
	ambience_player = AudioStreamPlayer.new()
	ambience_player.stream = load("res://assets/audio/pizzeria_horror_ambience.ogg")
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

func _validate_loaded_audio() -> void:
	var missing: Array[String] = []
	if ambience_player.stream == null: missing.append("pizzeria_horror_ambience.ogg")
	if footstep_a.stream == null or footstep_b.stream == null: missing.append("player_step.ogg")
	if flashlight_audio.stream == null: missing.append("flashlight_click.mp3")
	if horror_player.stream == null: missing.append("horror_sting.mp3")
	if monster_growl_player.stream == null: missing.append("monster_growl.mp3")
	if toy_voice_player.stream == null: missing.append("toy_hello.mp3")
	if laugh_player.stream == null: missing.append("toy_giggle.mp3")
	if laugh_alt_player.stream == null: missing.append("creepy_laugh.mp3")
	if robot_step_a.stream == null or robot_step_b.stream == null: missing.append("robot_step.ogg")
	if missing.is_empty():
		print("GAME_AUDIO_ASSETS_LOADED")
	else:
		push_error("GAME_AUDIO_ASSETS_MISSING: " + ", ".join(missing))

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
	camera_filter_enabled = true
	camera_filter_overlay.visible = true
	if is_instance_valid(camera_filter_button): camera_filter_button.text = "CAM 01 ON"
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
	if not player.is_on_floor():
		player.velocity.y -= 9.8 * delta
	else:
		player.velocity.y = -0.2
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
	# The Mimic uses the connected hallway/doorway route map, not a straight-line chase through walls.
	ai_repath_timer -= delta
	if ai_repath_timer <= 0.0 or ai_route_points.is_empty():
		_build_ai_route()
		ai_repath_timer = 0.55
	while ai_route_index < ai_route_points.size() and animatronic.global_position.distance_to(ai_route_points[ai_route_index]) < 1.0:
		ai_route_index += 1
	var goal: Vector3 = player.global_position
	if ai_route_index < ai_route_points.size(): goal = ai_route_points[ai_route_index]
	var to_goal := goal - animatronic.global_position
	to_goal.y = 0.0
	var goal_distance := to_goal.length()
	var to_player := player.global_position - animatronic.global_position
	to_player.y = 0.0
	var distance := to_player.length()
	if goal_distance > 0.10:
		var desired := _ai_steer_around_obstacles(to_goal.normalized())
		var chase_speed := 1.48 + minf(elapsed/110.0,0.75)
		animatronic.velocity.x = desired.x * chase_speed
		animatronic.velocity.z = desired.z * chase_speed
		animatronic.velocity.y = -0.2
		animatronic.move_and_slide()
		var moved: float = animatronic.get_position_delta().length()
		if moved < 0.018 and goal_distance > 1.2:
			ai_stuck_timer += delta
		else:
			ai_stuck_timer = maxf(0.0,ai_stuck_timer-delta*2.0)
		if ai_stuck_timer > 0.72:
			ai_stuck_timer = 0.0
			ai_steer_sign *= -1.0
			ai_repath_timer = 0.0
		animatronic.look_at(Vector3(animatronic.global_position.x+desired.x,animatronic.global_position.y,animatronic.global_position.z+desired.z),Vector3.UP)
		if anim_player:
			var wanted := _find_animation_name(anim_player,"RunA")
			var cycle_length := 0.62
			if distance > 9.0:
				wanted = _find_animation_name(anim_player,"Walk_SK")
				cycle_length = 1.29
			if wanted != "" and anim_player.current_animation != wanted:
				anim_player.play(wanted,0.18)
				anim_step_timer = 0.0
			anim_player.speed_scale = 1.0 + minf(elapsed/150.0,0.25)
			anim_step_timer -= delta
			if anim_step_timer <= 0.0 and distance < 24.0 and moved > 0.10:
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
	threat_label.text = "⚠ MOVIMIENTO CERCANO" if distance < 8.0 else "SIN MOVIMIENTO"
	hud.text = "%02d AM  •  TURNO 01" % [12 + int(elapsed/60.0)%6]
	if overlay.color.a > 0.0:
		var c := overlay.color
		c.a = maxf(0.0,c.a - delta*0.38)
		overlay.color = c

func _build_ai_route() -> void:
	ai_route_points.clear()
	ai_route_index = 0
	var p := player.global_position
	var a := animatronic.global_position
	var target_west := p.x < -20.0
	var target_east := p.x > 20.0
	var target_north := p.z < -14.0
	var target_office := p.z > 18.0 and absf(p.x) < 12.0
	var a_west := a.x < -20.0
	var a_east := a.x > 20.0
	var a_north := a.z < -14.0
	var a_office := a.z > 18.0 and absf(a.x) < 12.0
	if target_west:
		if a_east:
			ai_route_points.append_array([Vector3(19,0,1.5),Vector3(4,0,1.5),Vector3(-18.5,0,1.5)])
		elif a_north:
			ai_route_points.append_array([Vector3(0,0,-12),Vector3(4,0,-8),Vector3(4,0,1.5),Vector3(-18.5,0,1.5)])
		elif a_office:
			ai_route_points.append_array([Vector3(-10,0,24),Vector3(-18,0,24),Vector3(-24,0,18)])
		elif not a_west:
			ai_route_points.append(Vector3(-18.5,0,1.5))
	elif target_east:
		if a_west:
			ai_route_points.append_array([Vector3(-19,0,1.5),Vector3(4,0,1.5),Vector3(18.5,0,1.5)])
		elif a_north:
			ai_route_points.append_array([Vector3(0,0,-12),Vector3(4,0,-8),Vector3(4,0,1.5),Vector3(18.5,0,1.5)])
		elif a_office:
			ai_route_points.append_array([Vector3(10,0,24),Vector3(18,0,24),Vector3(24,0,18)])
		elif not a_east:
			ai_route_points.append(Vector3(18.5,0,1.5))
	elif target_north:
		if a_west:
			ai_route_points.append_array([Vector3(-24,0,2),Vector3(-18,0,1.5),Vector3(4,0,1.5),Vector3(4,0,-8),Vector3(0,0,-12)])
		elif a_east:
			ai_route_points.append_array([Vector3(24,0,2),Vector3(18,0,1.5),Vector3(4,0,1.5),Vector3(4,0,-8),Vector3(0,0,-12)])
		elif a_office:
			ai_route_points.append_array([Vector3(0,0,15),Vector3(0,0,10),Vector3(4,0,1.5),Vector3(4,0,-8),Vector3(0,0,-12)])
		elif not a_north:
			ai_route_points.append_array([Vector3(4,0,-8),Vector3(0,0,-12)])
	elif target_office:
		if a_west:
			ai_route_points.append_array([Vector3(-24,0,18),Vector3(-18,0,24),Vector3(-10,0,24),Vector3(0,0,24)])
		elif a_east:
			ai_route_points.append_array([Vector3(24,0,18),Vector3(18,0,24),Vector3(10,0,24),Vector3(0,0,24)])
		elif a_north:
			ai_route_points.append_array([Vector3(0,0,-12),Vector3(4,0,-8),Vector3(4,0,1.5),Vector3(0,0,10),Vector3(0,0,15),Vector3(0,0,20)])
		elif not a_office:
			ai_route_points.append_array([Vector3(0,0,10),Vector3(0,0,15),Vector3(0,0,20)])
	else:
		if a_west: ai_route_points.append_array([Vector3(-18.5,0,1.5),Vector3(4,0,1.5)])
		elif a_east: ai_route_points.append_array([Vector3(18.5,0,1.5),Vector3(4,0,1.5)])
		elif a_north: ai_route_points.append_array([Vector3(0,0,-12),Vector3(4,0,-8),Vector3(4,0,1.5)])
		elif a_office: ai_route_points.append_array([Vector3(0,0,15),Vector3(0,0,10),Vector3(4,0,1.5)])
	if not ai_route_points.is_empty():
		var nearest_index := 0
		var nearest_distance := INF
		for i in range(ai_route_points.size()):
			var candidate_distance := animatronic.global_position.distance_to(ai_route_points[i])
			if candidate_distance < nearest_distance:
				nearest_distance = candidate_distance
				nearest_index = i
		ai_route_index = nearest_index
		while ai_route_index < ai_route_points.size() and animatronic.global_position.distance_to(ai_route_points[ai_route_index]) < 1.15:
			ai_route_index += 1

func _ai_steer_around_obstacles(direction: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var origin := animatronic.global_position + Vector3(0,1.10,0)
	var forward_end := origin + direction * 1.55
	var query := PhysicsRayQueryParameters3D.create(origin,forward_end,1,[animatronic.get_rid(),player.get_rid()])
	query.collide_with_areas = false
	if space.intersect_ray(query).is_empty(): return direction
	var left := Vector3(-direction.z,0,direction.x) * ai_steer_sign
	var right := -left
	var left_end := origin + (direction*0.32+left*0.95).normalized()*1.45
	var right_end := origin + (direction*0.32+right*0.95).normalized()*1.45
	var left_query := PhysicsRayQueryParameters3D.create(origin,left_end,1,[animatronic.get_rid(),player.get_rid()])
	var right_query := PhysicsRayQueryParameters3D.create(origin,right_end,1,[animatronic.get_rid(),player.get_rid()])
	left_query.collide_with_areas = false
	right_query.collide_with_areas = false
	var left_blocked := not space.intersect_ray(left_query).is_empty()
	var right_blocked := not space.intersect_ray(right_query).is_empty()
	if left_blocked and right_blocked:
		ai_steer_sign *= -1.0
		return (direction*0.35+right*0.94).normalized()
	if left_blocked: return (direction*0.40+right*0.92).normalized()
	if right_blocked: return (direction*0.40+left*0.92).normalized()
	return (direction*0.25+(right if ai_steer_sign > 0.0 else left)*0.97).normalized()


func _toggle_cctv_filter() -> void:
	camera_filter_enabled = not camera_filter_enabled
	if is_instance_valid(camera_filter_overlay): camera_filter_overlay.visible = camera_filter_enabled
	if is_instance_valid(camera_filter_button):
		camera_filter_button.text = "CAM 01 ON" if camera_filter_enabled else "CAM 01"
	if is_instance_valid(threat_label) and camera_filter_enabled:
		threat_label.text = "CAM 01  •  REC ●"
	if is_instance_valid(threat_label) and not camera_filter_enabled:
		threat_label.text = "SIN MOVIMIENTO"

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
