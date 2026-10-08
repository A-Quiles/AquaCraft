shader_type canvas_item;
// Pez 100% procedural: cuerpo, cola, aletas, patrón, escamas, brillo y ojo, todo con
// distancias firmadas sobre un quad. Un único shader para todas las especies y mutaciones.
// Ejes: x de -1 (cola) a 1 (hocico), y hacia arriba; el quad mide 2 × 2/aspect.

uniform vec3 col_body : source_color = vec3(0.85, 0.87, 0.9);
uniform vec3 col_pat : source_color = vec3(1.0, 0.35, 0.2);
uniform vec3 col_fin : source_color = vec3(1.0, 0.45, 0.25);
uniform float aspect = 2.0;
uniform float body_len = 0.46;
uniform float body_h = 0.19;
uniform int tail_type = 0;           // 0 abanico · 1 horquilla · 2 doble · 3 velo
uniform float tail_len = 0.5;
uniform float tail_h = 0.34;
uniform float dorsal = 0.1;
uniform float anal = 0.05;
uniform float sweep = 0.3;
uniform float point = 0.3;
uniform int pattern = 0;
uniform float seed = 0.0;
uniform float phase = 0.0;           // fase de aleteo (la avanza el script según velocidad)
uniform float auto_wag = 0.0;        // >0 en las vistas previas de la UI
uniform float wag_amp = 1.0;
uniform float neon = 0.0;
uniform float albino = 0.0;
uniform float veil = 0.0;
uniform float sick = 0.0;
uniform float depth = 0.0;           // 0 cerca · 1 al fondo (se tiñe de agua)
uniform vec3 fog : source_color = vec3(0.05, 0.32, 0.45);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fill(float d) {
	float w = fwidth(d) * 0.8 + 1e-5;
	return clamp(0.5 - d / w, 0.0, 1.0);
}

vec4 over(vec4 top, vec4 base) {
	float a = top.a + base.a * (1.0 - top.a);
	vec3 c = (top.rgb * top.a + base.rgb * base.a * (1.0 - top.a)) / max(a, 1e-5);
	return vec4(c, a);
}

vec3 albinize(vec3 c) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	return mix(c, vec3(1.0, 0.92, 0.88) * (0.82 + 0.18 * l), albino * 0.82);
}

void fragment() {
	float ylim = 1.0 / aspect;
	vec2 p = vec2((UV.x - 0.5) * 2.0, (0.5 - UV.y) * 2.0 * ylim);
	float t = phase + TIME * auto_wag + seed * 6.28;

	float bl = body_len;
	float bh = body_h;
	float tl = tail_len * (1.0 + veil * 0.35);
	float th = min(tail_h * (1.0 + veil * 0.4), ylim - 0.03);
	float dor = dorsal * (1.0 + veil * 0.45);
	float ana = anal * (1.0 + veil * 0.6);
	float cx = 0.96 - bl;
	float xb = cx - bl * 0.86;
	tl = min(tl, xb + 0.99);

	// Onda de natación: crece hacia la cola.
	float tailw = clamp((cx + bl * 0.3 - p.x) / (bl * 1.3 + tl), 0.0, 1.0);
	float bend = sin(t - p.x * 3.0) * 0.075 * wag_amp * tailw * tailw;
	vec2 q = vec2(p.x, p.y - bend);

	// ── Cuerpo (huevo con hocico ajustable) ──
	float dx = (q.x - cx) / bl;
	float taper = dx < 0.0 ? 1.0 - 0.34 * smoothstep(0.0, 1.0, -dx) : 1.0 - point * 0.45 * dx * dx;
	float belly = -bh * 0.08 * (1.0 - dx * dx);
	float hh = bh * taper;
	float dy = (q.y - belly) / hh;
	float r = length(vec2(dx, dy));
	float a_body = fill((r - 1.0) * min(bl, hh));
	float prof = sqrt(max(0.04, 1.0 - dx * dx));
	float top = belly + hh * prof;
	float bot = belly - hh * prof;

	vec3 fin_c = albinize(col_fin);
	vec4 acc = vec4(0.0);

	// ── Cola ──
	float tx = (xb - q.x) / tl;
	if (tx > -0.2) {
		float flex = 1.0 + 0.1 * sin(t + 1.5);
		float yy = q.y - belly;
		float base_h = bh * 0.28;
		float k = clamp(tx, 0.0, 1.0);
		float half_h;
		float tip;
		if (tail_type == 3) {
			yy += tx * tx * 0.1;
			half_h = mix(base_h, th, sqrt(k)) * flex;
			tip = 1.0 + 0.07 * sin(yy * 22.0 + t * 0.7);
		} else if (tail_type == 1) {
			half_h = mix(base_h, th, k) * flex;
			tip = 1.0 - 0.6 * (1.0 - clamp(abs(yy) / max(half_h, 1e-3), 0.0, 1.0));
		} else if (tail_type == 2) {
			half_h = mix(base_h, th, pow(k, 0.65)) * flex;
			float ny = clamp(abs(yy) / max(half_h, 1e-3), 0.0, 1.0);
			tip = 1.0 - 0.3 * (1.0 - ny) * (1.0 - ny) - 0.12 * ny * ny;
		} else {
			half_h = mix(base_h, th, pow(k, 0.8)) * flex;
			float ny = yy / max(half_h, 1e-3);
			tip = 1.0 - 0.12 * ny * ny;
		}
		float d_tail = max(abs(yy) - half_h, (tx - tip) * tl);
		float a_tail = fill(d_tail) * step(-0.2, tx);
		float rays = 0.5 + 0.5 * sin(atan(yy, tx * tl + 0.05) * 46.0);
		vec3 tc = mix(albinize(col_body) * 0.9, fin_c, smoothstep(0.0, 0.45, tx));
		tc *= 0.9 + 0.12 * rays;
		tc += vec3(0.18) * smoothstep(0.75, 1.0, tx / max(tip, 0.01));
		acc = over(vec4(tc, a_tail * mix(0.9, 0.7, k)), acc);
	}

	// ── Aleta dorsal ──
	float d0 = cx - bl * (0.7 + sweep * 0.3);
	float d1 = cx + bl * 0.15;
	float s = (q.x - d0) / (d1 - d0);
	if (s > 0.0 && s < 1.0) {
		// Perfil asimétrico: sube rápido delante y cae hacia atrás (o se alarga si hay barrido).
		float fh = dor * pow(sin(3.1416 * pow(s, 1.5)), 0.6) * (1.0 + sweep * (1.0 - s) * 0.8);
		fh = min(fh, ylim - top - 0.015);
		float d_dor = max(q.y - (top + fh), (top - 0.03) - q.y);
		float rays = 0.5 + 0.5 * sin(s * 60.0);
		float ft = clamp((q.y - top) / max(fh, 1e-3), 0.0, 1.0);
		vec3 dc = mix(fin_c, albinize(col_body), 0.25 * (1.0 - ft)) * (0.92 + 0.1 * rays);
		dc = mix(dc, dc + 0.18, ft * ft);
		acc = over(vec4(dc, fill(d_dor) * mix(0.85, 0.6, ft)), acc);
	}

	// ── Aleta anal ──
	float a0 = cx - bl * (0.88 + sweep * 0.3);
	float a1 = cx - bl * 0.2;
	float sa = (q.x - a0) / (a1 - a0);
	if (sa > 0.0 && sa < 1.0) {
		float fh = ana * pow(sin(3.1416 * pow(sa, 1.3)), 0.6) * (1.0 + sweep * (1.0 - sa) * 0.8);
		fh = min(fh, ylim + bot - 0.015);
		float d_an = max((bot - fh) - q.y, q.y - (bot + 0.03));
		float ft = clamp((bot - q.y) / max(fh, 1e-3), 0.0, 1.0);
		float rays = 0.5 + 0.5 * sin(sa * 54.0);
		vec3 ac = fin_c * (0.9 + 0.1 * rays);
		ac = mix(ac, ac + 0.15, ft * ft);
		acc = over(vec4(ac, fill(d_an) * mix(0.82, 0.58, ft)), acc);
	}

	// ── Color del cuerpo ──
	vec3 base = col_body;
	vec3 pat = col_pat;
	float pm = 0.0;
	if (pattern == 1) {
		pm = smoothstep(0.4, -0.7, dx);
	} else if (pattern == 2) {
		vec2 sp = q * 24.0 + seed * 13.0;
		vec2 cell = floor(sp);
		vec2 off = vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5;
		pm = smoothstep(0.3, 0.2, length(fract(sp) - 0.5 - off * 0.35)) * step(0.3, hash(cell));
	} else if (pattern == 3) {
		pm = smoothstep(0.3, 0.6, sin((dx * 3.3 + 0.2) * 3.1416));
	} else if (pattern == 4) {
		pm = smoothstep(0.24, 0.1, abs(dy - 0.16)) * smoothstep(-0.98, -0.6, dx) * smoothstep(0.92, 0.6, dx);
		float red = smoothstep(0.05, -0.3, dy) * smoothstep(0.3, -0.15, dx);
		base = mix(base, col_fin * 1.05, red * 0.95);
	} else if (pattern == 5) {
		float b = abs(fract(dx * 1.35 + 0.18) - 0.5);
		pm = smoothstep(0.12, 0.08, b);
		base = mix(base, vec3(0.06), clamp(smoothstep(0.17, 0.13, b) - pm, 0.0, 1.0));
	} else if (pattern == 6) {
		float nn = vnoise(q * 9.0 + seed * 5.0) * 0.65 + vnoise(q * 21.0 - seed) * 0.35;
		pm = smoothstep(0.47, 0.55, nn);
	} else if (pattern == 7) {
		pm = smoothstep(0.05, -0.3, dx + dy * 0.15);
	}
	vec3 bc = albinize(mix(base, pat, pm));

	// Contrasombreado, escamas, brillo, branquia y contorno.
	bc = mix(bc * 1.15 + 0.07, bc, smoothstep(-0.95, 0.05, dy));
	bc *= mix(1.0, 0.72, smoothstep(0.35, 1.0, dy));
	vec2 ss = q * vec2(58.0, 66.0);
	ss.x += mod(floor(ss.y), 2.0) * 0.5;
	float scl = smoothstep(0.5, 0.32, length((fract(ss) - 0.5) * vec2(1.0, 1.25)));
	float scl_w = clamp(1.0 - fwidth(q.x) * 70.0, 0.0, 1.0) * smoothstep(0.6, -0.2, dx);
	bc *= 1.0 + (scl - 0.5) * 0.09 * scl_w;
	float spec = exp(-pow((dy - 0.48) * 3.2, 2.0)) * smoothstep(-0.75, 0.35, dx);
	bc += vec3(1.0) * spec * 0.26;
	float gill = abs(length(vec2((dx - 0.42) * 1.4, dy * 0.78)) - 0.42);
	bc *= 1.0 - 0.16 * smoothstep(0.045, 0.0, gill) * step(0.1, dx) * step(dx, 0.3) * step(abs(dy), 0.75);
	bc *= 1.0 - 0.22 * smoothstep(0.8, 1.0, r);
	bc = mix(bc, bc * 0.42, smoothstep(0.93, 0.995, r) * 0.75);

	// Brillo neón (mutación)
	float glow_t = 0.75 + 0.25 * sin(TIME * 2.2 + seed * 5.0);
	bc += col_pat * neon * 0.38 * glow_t * (pm + 0.35);

	// Ojo
	vec2 ec = vec2(cx + bl * 0.66, belly + hh * 0.22);
	float er = clamp(bh * 0.2, 0.028, 0.065);
	float de = length(q - ec);
	vec3 iris = mix(vec3(0.95, 0.8, 0.35), vec3(0.08, 0.06, 0.05), smoothstep(er * 0.5, er * 0.95, de));
	vec3 pupil_c = mix(vec3(0.04), vec3(0.85, 0.12, 0.2), albino);
	vec3 eye = mix(pupil_c, iris, smoothstep(er * 0.56, er * 0.66, de));
	eye = mix(eye, vec3(1.0), fill(length(q - ec - vec2(-er * 0.25, er * 0.32)) - er * 0.26));
	bc = mix(bc, eye, fill(de - er));

	acc = over(vec4(bc, a_body), acc);

	// ── Aleta pectoral (delante del cuerpo) ──
	vec2 pc = q - vec2(cx + bl * 0.28, belly - hh * 0.25);
	float ang = -0.45 + 0.35 * sin(t * 1.3);
	pc = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * pc;
	float pr = length(pc / vec2(max(bl * 0.22, 0.07), max(hh * 0.28, 0.035)));
	acc = over(vec4(mix(fin_c, vec3(1.0), 0.15), fill((pr - 1.0) * 0.05) * 0.5 * step(pc.x, 0.0)), acc);

	// Halo neón fuera del cuerpo
	float halo = neon * exp(-max((r - 1.0) * min(bl, hh), 0.0) / 0.03) * (1.0 - acc.a);
	acc = over(acc, vec4(col_pat, halo * 0.4 * glow_t));

	// Enfermo: apagado. Lejos: niebla de agua.
	float l = dot(acc.rgb, vec3(0.299, 0.587, 0.114));
	acc.rgb = mix(acc.rgb, vec3(l) * 0.85, sick * 0.65);
	acc.rgb = mix(acc.rgb, fog, depth * 0.42);
	COLOR = acc;
}
