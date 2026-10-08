shader_type canvas_item;
// Agua: degradado de profundidad, rayos de luz, cáusticas animadas, turbidez y superficie.
// Coste bajo: 2 lecturas de cáusticas + 1 de ruido por píxel, sin bucles.

uniform vec3 top_col : source_color = vec3(0.42, 0.88, 0.9);
uniform vec3 deep_col : source_color = vec3(0.02, 0.24, 0.38);
uniform vec3 murk_col : source_color = vec3(0.36, 0.42, 0.16);
uniform float murk = 0.0;            // 0 limpia · 1 muy sucia
uniform float light = 1.0;           // potencia de la pantalla LED
uniform float night = 0.0;
uniform vec2 size = vec2(600.0, 500.0);
uniform sampler2D caustics : repeat_enable, filter_linear_mipmap;
uniform sampler2D noise : repeat_enable, filter_linear;

void fragment() {
	vec2 uv = UV;
	float aspect = size.x / size.y;
	vec2 p = vec2(uv.x * aspect, uv.y);

	vec3 col = mix(top_col, deep_col, smoothstep(-0.1, 1.05, uv.y));

	// Rayos de luz inclinados con anchura irregular.
	float sx = uv.x * aspect * 0.9 + uv.y * 0.32;
	float r1 = texture(noise, vec2(sx * 0.55 + TIME * 0.012, 0.31)).r;
	float r2 = texture(noise, vec2(sx * 1.3 - TIME * 0.02, 0.73)).g;
	float rays = smoothstep(0.5, 0.85, r1) * 0.8 + smoothstep(0.55, 0.9, r2) * 0.5;
	rays *= (1.0 - smoothstep(0.0, 0.95, uv.y)) * light;
	col += vec3(0.8, 1.0, 0.92) * rays * 0.17;

	// Cáusticas: dos capas que se cruzan.
	// Cáusticas sobre el cristal trasero: suaves (mip borroso) y más visibles abajo.
	vec2 cuv = p * 1.1;
	float c1 = texture(caustics, cuv + vec2(TIME * 0.018, TIME * 0.011), 1.6).r;
	float c2 = texture(caustics, cuv * 1.37 + vec2(-TIME * 0.014, TIME * 0.016), 1.6).r;
	float caus = min(c1, c2);
	col += vec3(0.7, 1.0, 1.0) * caus * (0.035 + 0.06 * uv.y) * light;

	// Turbidez por suciedad y penumbra nocturna.
	float m = murk * (0.45 + 0.55 * uv.y);
	col = mix(col, murk_col * (0.55 + 0.45 * (1.0 - uv.y)), m * 0.6);
	col *= mix(1.0, 0.72, night);

	// Superficie ondulada con brillo.
	float surf = 0.016 + 0.004 * sin(p.x * 16.0 + TIME * 1.4) + 0.0025 * sin(p.x * 37.0 - TIME * 2.1);
	float above = smoothstep(surf + 0.004, surf - 0.002, uv.y);
	col = mix(col, top_col * 1.12 + vec3(0.1), above * 0.75);
	col += vec3(1.0) * smoothstep(0.005, 0.0, abs(uv.y - surf)) * 0.4;

	// Viñeta lateral: da volumen al tanque.
	float vig = smoothstep(0.0, 0.2, uv.x) * smoothstep(0.0, 0.2, 1.0 - uv.x);
	col *= mix(0.74, 1.0, vig);
	COLOR = vec4(col, 1.0);
}
