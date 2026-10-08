shader_type canvas_item;
// Sustrato: grava (piedras Voronoi con volumen) o arena (grano y ondas), con cáusticas encima.

uniform vec3 col_a : source_color = vec3(0.55, 0.48, 0.42);
uniform vec3 col_b : source_color = vec3(0.72, 0.66, 0.58);
uniform vec3 col_c : source_color = vec3(0.37, 0.32, 0.27);
uniform vec3 fog_col : source_color = vec3(0.04, 0.3, 0.42);
uniform float pebble = 1.0;          // 1 grava · 0 arena
uniform float light = 1.0;
uniform float night = 0.0;
uniform float seed = 0.0;
uniform vec2 size = vec2(600.0, 120.0);
uniform sampler2D caustics : repeat_enable, filter_linear_mipmap;
uniform sampler2D noise : repeat_enable, filter_linear;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float x = uv.x * size.x / size.y;
	float edge = 0.3 + 0.08 * sin(x * 1.9 + seed) + 0.05 * sin(x * 4.7 + seed * 2.3) + 0.02 * sin(x * 11.0);
	float aa = 1.5 / size.y;
	float inside = smoothstep(edge - aa, edge + aa, uv.y);
	if (inside <= 0.0) {
		discard;
	}
	float depth = clamp((uv.y - edge) / (1.0 - edge), 0.0, 1.0);   // 0 fondo lejano · 1 cristal
	vec2 px = uv * size;

	// Arena
	float n = texture(noise, px / 220.0).r;
	float grain = fract(sin(dot(floor(px), vec2(12.9898, 78.233))) * 43758.5453);
	vec3 sand = mix(col_c, col_b, n * 0.8 + 0.1);
	sand = mix(sand, col_a, 0.35) * (0.92 + grain * 0.16);
	sand *= 0.94 + 0.08 * sin(px.x * 0.11 + n * 9.0 + px.y * 0.05);

	// Grava
	vec2 q = px / vec2(15.0, 10.5);
	vec2 cell = floor(q);
	vec2 f = fract(q);
	float f1 = 8.0;
	float f2 = 8.0;
	vec2 rel = vec2(0.0);
	vec2 id = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 r = g + hash2(cell + g) * 0.8 + 0.1 - f;
			float d = dot(r, r);
			if (d < f1) { f2 = f1; f1 = d; rel = r; id = cell + g; }
			else if (d < f2) { f2 = d; }
		}
	}
	f1 = sqrt(f1);
	f2 = sqrt(f2);
	vec2 h = hash2(id + 17.0);
	vec3 stone = h.x < 0.4 ? col_a : (h.x < 0.75 ? col_b : col_c);
	stone *= 0.85 + h.y * 0.3;
	float gap = smoothstep(0.03, 0.14, f2 - f1);
	float dome = 1.0 - smoothstep(0.15, 0.75, f1);
	float lit = clamp(dot(-rel, vec2(-0.55, -0.85)) * 1.6 + 0.4, 0.0, 1.0);
	vec3 gravel = stone * (0.68 + 0.32 * dome) * mix(0.86, 1.1, lit);
	gravel += vec3(1.0) * smoothstep(0.55, 0.95, lit * dome) * 0.18;
	gravel = mix(col_c * 0.55, gravel, gap);

	vec3 col = mix(sand, gravel, pebble);

	// Cáusticas en el suelo
	vec2 cuv = vec2(x, uv.y * 0.45) * 1.4;
	float c1 = texture(caustics, cuv + vec2(TIME * 0.02, TIME * 0.012)).r;
	float c2 = texture(caustics, cuv * 1.31 + vec2(-TIME * 0.015, TIME * 0.02)).r;
	col += vec3(0.6, 0.95, 0.9) * min(c1, c2) * 0.35 * light * (1.0 - depth * 0.5);

	// Fondo lejano con niebla de agua, sombra de contacto y borde inferior oscuro.
	col = mix(col, fog_col, (1.0 - smoothstep(0.0, 0.45, depth)) * 0.45);
	col *= 1.0 - 0.35 * smoothstep(0.75, 1.0, depth);
	col *= mix(1.0, 0.7, night);
	COLOR = vec4(col, inside);
}
