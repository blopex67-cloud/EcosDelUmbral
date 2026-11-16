shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool has_normal_tex = false;
uniform vec4 base_tint : source_color = vec4(1.0);
uniform float roughness_value : hint_range(0.05, 1.0) = 0.42;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.36;

void fragment() {
	vec4 texel = texture(albedo_tex, UV) * base_tint;
	ALBEDO = texel.rgb;
	ALPHA = texel.a;
	ROUGHNESS = roughness_value;
	METALLIC = metallic_value;
	SPECULAR = 0.55;
	if (has_normal_tex) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = 0.5;
	}
}
