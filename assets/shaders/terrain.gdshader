shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 sand_color  : source_color = vec4(0.93, 0.87, 0.60, 1.0);
uniform vec4 grass_color : source_color = vec4(0.28, 0.65, 0.20, 1.0);
uniform vec4 rock_color  : source_color = vec4(0.50, 0.45, 0.40, 1.0);
uniform vec4 snow_color  : source_color = vec4(0.95, 0.95, 0.98, 1.0);
uniform float water_line : hint_range(0.0, 1.0) = 0.42;
uniform float max_height : hint_range(1.0, 200.0) = 38.0;

void fragment() {
	float height_norm = UV2.x;  // нормализованная высота [0..1], передаётся через UV2

	// Пляж (чуть выше воды)
	float beach_low  = water_line;
	float beach_high = water_line + 0.08;
	// Трава
	float grass_low  = beach_high;
	float grass_high = 0.70;
	// Скалы
	float rock_low   = grass_high - 0.05;
	float rock_high  = 0.88;
	// Снег (вершины)
	float snow_low   = rock_high - 0.05;

	vec4 col;
	if (height_norm < beach_low) {
		col = sand_color;  // под водой — тоже песок (не видно под водой)
	} else if (height_norm < beach_high) {
		float t = smoothstep(beach_low, beach_high, height_norm);
		col = mix(sand_color, grass_color, t);
	} else if (height_norm < grass_high) {
		col = grass_color;
	} else if (height_norm < rock_high) {
		float t = smoothstep(rock_low, rock_high, height_norm);
		col = mix(grass_color, rock_color, t);
	} else {
		float t = smoothstep(snow_low, 1.0, height_norm);
		col = mix(rock_color, snow_color, t);
	}

	// Небольшой шум для variation (используем позицию)
	vec2 tile = VERTEX.xz * 0.15;
	float noise_val = fract(sin(dot(floor(tile), vec2(127.1, 311.7))) * 43758.5);
	col.rgb *= 0.92 + noise_val * 0.16;

	ALBEDO = col.rgb;
	ROUGHNESS = 0.88;
	METALLIC = 0.0;
	SPECULAR = 0.1;
}
