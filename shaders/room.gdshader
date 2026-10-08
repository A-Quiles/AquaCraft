shader_type canvas_item;
// Habitación acogedora: pared con papel pintado, luz cálida de lámpara y resplandor del acuario.

uniform vec2 size = vec2(720.0, 1280.0);
uniform vec4 tank = vec4(100.0, 300.0, 520.0, 460.0);   // rect del acuario en píxeles
uniform float night = 0.0;
uniform vec3 wall_top : source_color = vec3(0.17, 0.25, 0.38);
uniform vec3 wall_low : source_color = vec3(0.56, 0.42, 0.5);
uniform vec3 lamp : source_color = vec3(1.0, 0.72, 0.45);
uniform vec3 glow : source_color = vec3(0.25, 0.85, 0.95);

void fragment() {
	vec2 px = UV * size;
	vec3 col = mix(wall_top, wall_low, smoothstep(0.0, 0.85, UV.y));

	// Papel pintado: rayas finas + rombos muy sutiles.
	float stripe = sin(px.x * 0.105) * 0.5 + 0.5;
	col *= 0.97 + 0.04 * stripe;
	vec2 dq = abs(fract(px / vec2(52.0, 64.0)) - 0.5);
	col *= 1.0 - 0.025 * smoothstep(0.06, 0.0, abs(dq.x + dq.y - 0.35));

	// Lámpara cálida arriba a la izquierda.
	float lampd = length((px - vec2(-0.1 * size.x, 0.12 * size.y)) / size.x);
	col += lamp * pow(max(0.0, 1.0 - lampd / 1.1), 2.2) * mix(0.42, 0.22, night);

	// Resplandor del acuario sobre la pared.
	vec2 c = tank.xy + tank.zw * 0.5;
	vec2 d = max(abs(px - c) - tank.zw * 0.5, 0.0);
	float g = exp(-length(d) / (90.0 + tank.z * 0.25));
	col += glow * g * mix(0.32, 0.5, night);

	col *= mix(1.0, 0.55, night);
	// Viñeta
	vec2 v = UV - 0.5;
	col *= 1.0 - dot(v, v) * 0.55;
	float grain = fract(sin(dot(floor(px), vec2(12.9898, 78.233))) * 43758.5453);
	COLOR = vec4(col + (grain - 0.5) * 0.012, 1.0);
}
