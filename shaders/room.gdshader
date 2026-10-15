shader_type canvas_item;
// Habitación acogedora: pared con papel pintado (según el estilo elegido), luz cálida de lámpara
// y resplandor del acuario. thumb = miniatura de la tienda (coordenadas propias, sin luces).

uniform vec2 size = vec2(720.0, 1280.0);
uniform vec4 tank = vec4(100.0, 300.0, 520.0, 460.0);   // rect del acuario en píxeles
uniform float night = 0.0;
uniform vec3 wall_top : source_color = vec3(0.17, 0.25, 0.38);
uniform vec3 wall_low : source_color = vec3(0.56, 0.42, 0.5);
uniform vec3 wall_acc : source_color = vec3(1.0);
uniform int pat = 0;   // 0 rayas finas · 1 rayas anchas · 2 lunares · 3 ladrillo · 4 caramelo · 5 hojas · 6 lunas
                       // 7 cerezo · 8 shoji · 9 estrellas · 10 tablones
uniform bool thumb = false;
uniform vec3 lamp : source_color = vec3(1.0, 0.72, 0.45);
uniform vec3 glow : source_color = vec3(0.25, 0.85, 0.95);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float aa(float d) {
	return clamp(0.5 - d / max(fwidth(d), 1e-4), 0.0, 1.0);
}

// Motivo repetido en rejilla escalonada: devuelve coordenadas locales (-0.5..0.5) y la celda.
vec2 cell_uv(vec2 px, vec2 cs, out vec2 id) {
	vec2 g = px / cs;
	g.x += mod(floor(g.y), 2.0) * 0.5;
	id = floor(g);
	return fract(g) - 0.5;
}

vec3 wallpaper(vec3 col, vec2 px) {
	vec2 id;
	if (pat == 0) {
		col *= 0.97 + 0.04 * (sin(px.x * 0.105) * 0.5 + 0.5);
		vec2 dq = abs(fract(px / vec2(52.0, 64.0)) - 0.5);
		col *= 1.0 - 0.025 * smoothstep(0.06, 0.0, abs(dq.x + dq.y - 0.35));
	} else if (pat == 1) {
		// Rayas anchas de dos tonos con filete fino.
		float x = fract(px.x / 96.0);
		col = mix(col, col * 0.9, step(0.5, x));
		col = mix(col, wall_acc, aa(abs(x - 0.5) - 0.012) * 0.5 + aa(abs(x - 0.03) - 0.006) * 0.3);
	} else if (pat == 2) {
		vec2 c = cell_uv(px, vec2(46.0), id);
		col = mix(col, wall_acc, aa(length(c) * 46.0 - 6.0) * 0.55);
	} else if (pat == 3) {
		// Ladrillos con junta clara y tono propio cada uno.
		vec2 c = cell_uv(px, vec2(66.0, 28.0), id);
		float mortar = 1.0 - aa(max(abs(c.x) * 66.0 - 30.5, abs(c.y) * 28.0 - 11.5));
		vec3 brick = col * (0.85 + 0.25 * hash(id)) * (0.94 + 0.08 * vnoise(px * 0.15));
		col = mix(brick, wall_acc * 0.85, mortar * 0.85);
	} else if (pat == 4) {
		// Bastón de caramelo: franjas diagonales con un filete verde y copos.
		float s = fract((px.x + px.y) / 96.0);
		col = mix(col, mix(col, wall_acc, 0.4), aa(abs(s - 0.75) * 96.0 - 9.0));
		col = mix(col, vec3(0.16, 0.42, 0.24), aa(abs(s - 0.75) * 96.0 - 1.6) * 0.7);
		vec2 c = cell_uv(px, vec2(110.0), id);
		float r = length(c) * 110.0;
		float a = atan(c.y, c.x);
		float flake = max(aa(r - 5.0), aa(abs(sin(a * 3.0)) * r - 1.2) * aa(r - 14.0));
		col = mix(col, vec3(1.0), flake * 0.75 * step(0.4, hash(id)));
	} else if (pat == 5) {
		// Hojas de otoño sueltas, cada una con su color y giro.
		vec2 c = cell_uv(px, vec2(84.0, 76.0), id);
		float h = hash(id);
		float ang = h * 6.28;
		c = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * (c + (vec2(hash(id + 3.0), hash(id + 7.0)) - 0.5) * 0.35);
		vec2 l = c * vec2(84.0, 76.0) / vec2(22.0, 11.0);
		float leaf = aa((length(l) - 1.0 + 0.35 * abs(l.x)) * 10.0);
		vec3 lc = mix(wall_acc, mix(vec3(0.85, 0.35, 0.15), vec3(0.6, 0.2, 0.1), hash(id + 1.0)), step(0.5, h));
		col = mix(col, lc, leaf * 0.7);
		col = mix(col, lc * 0.6, aa(abs(l.y) * 11.0 - 0.6) * step(abs(l.x), 1.0) * leaf * 0.6);
	} else if (pat == 6) {
		// Lunas menguantes y estrellitas sobre rayas moradas.
		col *= 0.92 + 0.1 * step(0.5, fract(px.x / 60.0));
		vec2 c = cell_uv(px, vec2(120.0, 104.0), id);
		vec2 m = c * vec2(120.0, 104.0);
		float moon = aa(length(m) - 13.0) * (1.0 - aa(length(m - vec2(6.0, -4.0)) - 11.0));
		col = mix(col, wall_acc, moon * 0.8 * step(0.35, hash(id)));
		vec2 c2 = cell_uv(px + 37.0, vec2(54.0), id);
		vec2 st = abs(c2 * 54.0);
		col = mix(col, wall_acc, aa(st.x + st.y * 3.0 - 4.0) * 0.6 + aa(st.y + st.x * 3.0 - 4.0) * 0.6);
	} else if (pat == 7) {
		// Flores de cerezo de cinco pétalos.
		vec2 c = cell_uv(px, vec2(78.0, 70.0), id);
		c += (vec2(hash(id), hash(id + 2.0)) - 0.5) * 0.3;
		vec2 m = c * 78.0;
		float r = length(m);
		float a = atan(m.y, m.x) + hash(id) * 6.28;
		float petal = aa(r - (11.0 + 5.0 * abs(cos(a * 2.5))));
		col = mix(col, wall_acc, petal * 0.8 * step(0.25, hash(id + 5.0)));
		col = mix(col, vec3(0.92, 0.45, 0.6), aa(r - 3.5) * petal * 0.8);
	} else if (pat == 8) {
		// Shoji: papel con listones de madera.
		vec2 g = vec2(abs(fract(px.x / 80.0) - 0.5) * 80.0, abs(fract(px.y / 64.0) - 0.5) * 64.0);
		float lat = max(aa(40.0 - g.x - 2.5), aa(32.0 - g.y - 2.5));
		vec2 g3 = abs(fract(px / vec2(240.0, 320.0)) - 0.5) * vec2(240.0, 320.0);
		float frame = max(aa(120.0 - g3.x - 6.0), aa(160.0 - g3.y - 6.0));
		col *= 0.97 + 0.05 * vnoise(px * 0.08);
		col = mix(col, wall_acc, max(lat * 0.75, frame));
	} else if (pat == 9) {
		// Cielo estrellado: nebulosa suave y estrellas que titilan.
		col = mix(col, col * 1.5 + vec3(0.04, 0.0, 0.08), vnoise(px * 0.006) * vnoise(px * 0.013 + 4.0));
		vec2 c = cell_uv(px, vec2(38.0), id);
		float tw = 0.6 + 0.4 * sin(TIME * (1.0 + hash(id + 9.0) * 2.0) + hash(id) * 30.0);
		float sz = 0.8 + 1.8 * pow(hash(id + 4.0), 6.0);
		col = mix(col, wall_acc, aa(length(c * 38.0 + (vec2(hash(id + 1.0), hash(id + 6.0)) - 0.5) * 22.0) - sz) * step(0.55, hash(id)) * tw);
	} else if (pat == 10) {
		// Tablones pintados con vetas y juntas.
		float x = px.x / 52.0;
		float id_x = floor(x);
		float f = fract(x);
		col *= 0.94 + 0.1 * hash(vec2(id_x, 2.0));
		col *= 0.96 + 0.06 * vnoise(vec2(px.x * 0.4, px.y * 0.012));
		col = mix(col, col * 0.62, aa(min(f, 1.0 - f) * 52.0 - 1.2));
		col = mix(col, wall_acc, 0.12 * smoothstep(0.6, 0.9, vnoise(px * vec2(0.05, 0.01))));
	}
	return col;
}

void fragment() {
	// SCREEN_UV y no UV: el mismo material tapa las esquinas de la pecera redonda (main.gd).
	vec2 uv = thumb ? UV : SCREEN_UV;
	vec2 px = uv * size;
	vec3 col = mix(wall_top, wall_low, smoothstep(0.0, 0.85, uv.y));
	col = wallpaper(col, px);
	// Enlucido: irregularidades suaves y poro fino, como una pared de verdad.
	col *= 0.95 + 0.07 * vnoise(px * 0.012) + 0.03 * vnoise(px * 0.18);

	if (!thumb) {
		float lw = smoothstep(0.45, 0.8, dot(wall_top, vec3(0.299, 0.587, 0.114)));   // pared clara: luces más suaves
		// Lámpara cálida arriba a la izquierda.
		float lampd = length((px - vec2(-0.1 * size.x, 0.12 * size.y)) / size.x);
		col += lamp * pow(max(0.0, 1.0 - lampd / 1.1), 2.2) * mix(0.42, 0.22, night) * mix(1.0, 0.4, lw);
		// Resplandor del acuario sobre la pared.
		vec2 c = tank.xy + tank.zw * 0.5;
		vec2 d = max(abs(px - c) - tank.zw * 0.5, 0.0);
		float g = exp(-length(d) / (90.0 + tank.z * 0.25));
		col += glow * g * mix(0.32, 0.5, night) * mix(1.0, 0.35, lw);
		// Sombra suave de la pecera sobre la pared (la lámpara está arriba a la izquierda).
		vec2 sc = c + vec2(18.0, 26.0);
		vec2 sd = max(abs(px - sc) - tank.zw * 0.5 + 10.0, 0.0);
		col *= 1.0 - 0.32 * exp(-length(sd) / 26.0) * (1.0 - night * 0.5);
		col *= mix(1.0, 0.55, night);
		// Viñeta
		vec2 v = uv - 0.5;
		col *= 1.0 - dot(v, v) * mix(0.55, 0.3, lw);
	}
	float grain = fract(sin(dot(floor(px), vec2(12.9898, 78.233))) * 43758.5453);
	COLOR = vec4(col + (grain - 0.5) * 0.012, 1.0);
}
