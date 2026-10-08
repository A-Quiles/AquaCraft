shader_type canvas_item;
// Cristal frontal: película de algas (rejilla del juego) + reflejos y cantos verdosos.

uniform sampler2D algae : filter_linear;            // L8, Game.GW × Game.GH
uniform sampler2D noise : repeat_enable, filter_linear;
uniform vec2 size = vec2(600.0, 500.0);
uniform float night = 0.0;

void fragment() {
	vec2 uv = UV;
	vec2 px = uv * size;

	// Algas: la rejilla da la cantidad y el ruido decide DÓNDE salen primero.
	// Con poca cantidad solo aparecen puntitos aislados; con más, se extienden y se unen.
	float amount = texture(algae, uv).r;
	vec3 n = texture(noise, px / 150.0).rgb;
	float fine = texture(noise, px / 38.0).b;
	float spore = n.r * 0.7 + fine * 0.3;                 // 0..1: lugares propensos
	float need = (1.0 - spore) * 0.9;                       // cantidad necesaria para cubrir aquí
	float cover = smoothstep(need, need + 0.08, amount * 1.15);
	vec3 green = mix(vec3(0.27, 0.42, 0.13), vec3(0.47, 0.56, 0.2), n.g);
	green = mix(green, vec3(0.35, 0.3, 0.12), smoothstep(0.6, 0.9, n.b) * 0.5);
	green *= 1.0 - smoothstep(0.62, 0.7, fine) * 0.3;
	float alpha = cover * (0.3 + 0.6 * smoothstep(0.1, 0.8, amount));

	// Reflejos diagonales suaves.
	float d = uv.x + uv.y * 0.45;
	float refl = smoothstep(0.03, 0.0, abs(d - 0.22)) * 0.12 + smoothstep(0.012, 0.0, abs(d - 0.27)) * 0.08
		+ smoothstep(0.05, 0.0, abs(d - 1.12)) * 0.07;
	refl *= 1.0 - night * 0.6;

	// Canto del vidrio (verdoso, como un acuario real).
	float side = smoothstep(0.012, 0.0, uv.x) + smoothstep(0.012, 0.0, 1.0 - uv.x);
	vec3 glass = mix(vec3(1.0), vec3(0.55, 0.95, 0.85), side);
	float galpha = max(refl, side * 0.5);

	vec3 col = mix(glass, green, alpha);
	COLOR = vec4(col, max(alpha, galpha));
}
