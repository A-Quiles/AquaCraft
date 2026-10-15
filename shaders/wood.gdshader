shader_type canvas_item;
// Madera del mueble: veta alargada con nudos suaves y algo de brillo de barniz. Respeta el color de
// cada pieza (encimera, puertas...) y solo le añade la textura.

uniform sampler2D noise : repeat_enable, filter_linear;

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec2 p = lp;
	float warp = texture(noise, p * vec2(0.0025, 0.012)).r * 18.0 + texture(noise, p * vec2(0.01, 0.05)).g * 3.0;
	float grain = 0.5 + 0.5 * sin((p.y + warp) * 0.9);
	float fine = texture(noise, p * vec2(0.004, 0.35)).b;
	float g = mix(grain, fine, 0.45);
	vec3 c = COLOR.rgb * (0.86 + 0.22 * g);
	c += vec3(1.0, 0.95, 0.85) * 0.05 * pow(1.0 - fract(p.y / 23.0), 8.0);   // brillo del barniz en las tablas
	COLOR.rgb = c;
}
