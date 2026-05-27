shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.15, 0.65, 0.85, 0.75);
uniform vec4 deep_color    : source_color = vec4(0.05, 0.25, 0.55, 0.9);
uniform float wave_speed   : hint_range(0.1, 5.0) = 1.2;
uniform float wave_height  : hint_range(0.0, 2.0) = 0.25;
uniform float wave_scale   : hint_range(0.1, 10.0) = 2.5;
uniform float foam_level   : hint_range(0.0, 1.0) = 0.55;

void vertex() {
	float time = TIME * wave_speed;
	float wave  = sin(VERTEX.x * wave_scale + time)
				+ sin(VERTEX.z * wave_scale * 0.7 + time * 1.3)
				+ sin((VERTEX.x + VERTEX.z) * wave_scale * 0.5 + time * 0.9);
	VERTEX.y += wave * wave_height * 0.33;
}

void fragment() {
	float depth_fade = clamp(FRAGCOORD.z * 0.5, 0.0, 1.0);
	vec4 col = mix(shallow_color, deep_color, depth_fade);

	// Пена
	float time = TIME * wave_speed;
	float foam  = sin(UV.x * 20.0 + time * 2.0) * sin(UV.y * 20.0 + time * 1.5);
	foam = smoothstep(foam_level, 1.0, foam);
	col.rgb = mix(col.rgb, vec3(0.95, 0.97, 1.0), foam * 0.35);

	ALBEDO = col.rgb;
	ALPHA  = col.a;
	ROUGHNESS = 0.05;
	METALLIC  = 0.0;
	SPECULAR  = 0.9;
	NORMAL_MAP = vec3(
		sin(UV.x * 15.0 + TIME * wave_speed) * 0.3 + 0.5,
		cos(UV.y * 15.0 + TIME * wave_speed * 1.2) * 0.3 + 0.5,
		1.0
	);
}
