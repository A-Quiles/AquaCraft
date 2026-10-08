shader_type canvas_item;
// Pez 100% procedural con anatomía por especie: perfil de lomo y vientre independientes,
// 7 tipos de cola, dorsal (y 2ª dorsal) y anal con barrido, adiposa, barbillones, filamentos,
// pectoral, ojo, patrón, escamas y brillo. Todo con distancias firmadas (bordes suaves vía fwidth).
// Ejes: x de -1 (cola) a 1 (hocico), y hacia arriba; el quad mide 2 × 2/aspect.

uniform vec3 col_body : source_color = vec3(0.85, 0.87, 0.9);
uniform vec3 col_pat : source_color = vec3(1.0, 0.35, 0.2);
uniform vec3 col_fin : source_color = vec3(1.0, 0.45, 0.25);
uniform float aspect = 2.0;
uniform float body_len = 0.45;
uniform float h_top = 0.2;
uniform float h_bot = 0.2;
uniform float peak = 0.55;           // t del punto más alto
uniform float k_front = 0.6;         // curvatura del morro
uniform float k_rear = 0.5;          // curvatura trasera
uniform float k_bot = 0.5;           // curvatura del vientre (bajo = plano)
uniform float ped = 0.4;             // grosor del pedúnculo (relativo)
uniform int tail_type = 0;           // 0 redonda · 1 horquilla · 2 doble · 3 velo · 4 lira · 5 delta · 6 corta
uniform float tail_len = 0.4;
uniform float tail_h = 0.3;
uniform vec4 dorsal = vec4(0.3, 0.6, 0.1, 0.2);   // t0, t1, altura, barrido
uniform float dorsal_pt = 0.7;       // <1 redondeada · >1 puntiaguda
uniform float dorsal2 = 0.0;
uniform vec4 anal = vec4(0.2, 0.4, 0.06, 0.2);
uniform float adipose = 0.0;
uniform float barbels = 0.0;
uniform float threads = 0.0;
uniform float eye_t = 0.82;
uniform int pattern = 0;
uniform float seed = 0.0;
uniform float phase = 0.0;
uniform float auto_wag = 0.0;
uniform float wag_amp = 1.0;
uniform float neon = 0.0;
uniform float albino = 0.0;
uniform float veil = 0.0;
uniform float sick = 0.0;
uniform float depth = 0.0;
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

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
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

// Perfil del cuerpo (0..1) en t: trasera con pedúnculo, delantera hasta el hocico.
float prof(float t, float kr, float kf) {
	t = clamp(t, 0.0, 1.0);
	float u = t < peak ? (peak - t) / peak : (t - peak) / (1.0 - peak);
	float b = max(0.0, 1.0 - u * u);
	return t < peak ? mix(ped, 1.0, pow(b, kr)) : pow(b, kf);
}

float top_at(float t) { return h_top * prof(t, k_rear, k_front); }
float bot_at(float t) { return -h_bot * prof(t, k_bot, mix(k_front, k_bot, 0.5)); }

void fragment() {
	float ylim = 1.0 / aspect;
	vec2 p = vec2((UV.x - 0.5) * 2.0, (0.5 - UV.y) * 2.0 * ylim);
	float tt = phase + TIME * auto_wag + seed * 6.28;

	float L = body_len * 2.0;
	float nose = 0.97;
	float xs = nose - L;
	float tl = min(tail_len * (1.0 + veil * 0.35), xs + 0.99);
	float th = min(tail_h * (1.0 + veil * 0.4), ylim - 0.03);
	vec4 dor = dorsal;
	dor.z *= 1.0 + veil * 0.45;
	vec4 an = anal;
	an.z *= 1.0 + veil * 0.6;

	// Onda de natación: crece hacia la cola.
	float tailw = clamp((xs + L * 0.65 - p.x) / (L * 0.65 + tl), 0.0, 1.0);
	float bend = sin(tt - p.x * 3.0) * 0.075 * wag_amp * tailw * tailw;
	vec2 q = vec2(p.x, p.y - bend);

	// ── Cuerpo ──
	float t = (q.x - xs) / L;
	float top = top_at(t);
	float bot = bot_at(t);
	float d_body = max(max(q.y - top, bot - q.y), max(xs - q.x, q.x - nose));
	float a_body = fill(d_body);
	float mid = (top + bot) * 0.5;
	float half_h = max((top - bot) * 0.5, 1e-3);
	float dy = clamp((q.y - mid) / half_h, -1.0, 1.0);
	float dx = clamp(t, 0.0, 1.0) * 2.0 - 1.0;
	float inner = clamp(-d_body / half_h, 0.0, 1.0);   // 0 en el borde, 1 en el centro

	vec3 fin_c = albinize(col_fin);
	vec3 bodyc = albinize(col_body);
	vec4 acc = vec4(0.0);

	// ── Cola ──
	float pmid = (h_top - h_bot) * ped * 0.5;
	float tx = (xs - q.x) / tl;
	if (tx > -0.25) {
		float yy = q.y - pmid;
		float base_h = ped * (h_top + h_bot) * 0.42;
		float k = clamp(tx, 0.0, 1.0);
		float flex = 1.0 + 0.1 * sin(tt + 1.5);
		float hh;
		float tip;
		if (tail_type == 1) {
			hh = mix(base_h, th, k) * flex;
			tip = 1.0 - 0.6 * (1.0 - clamp(abs(yy) / max(hh, 1e-3), 0.0, 1.0));
		} else if (tail_type == 2) {
			hh = mix(base_h, th, pow(k, 0.65)) * flex;
			float ny = clamp(abs(yy) / max(hh, 1e-3), 0.0, 1.0);
			tip = 1.0 - 0.3 * (1.0 - ny) * (1.0 - ny) - 0.12 * ny * ny;
		} else if (tail_type == 3) {
			yy += tx * tx * 0.12;
			hh = mix(base_h, th, sqrt(k)) * flex;
			tip = 1.0 + 0.07 * sin(yy * 22.0 + tt * 0.7);
		} else if (tail_type == 4) {
			hh = mix(base_h, th, pow(k, 1.1)) * flex;
			float ny = clamp(abs(yy) / max(hh, 1e-3), 0.0, 1.0);
			tip = 0.52 + 0.55 * ny * ny;
		} else if (tail_type == 5) {
			hh = mix(base_h, th, k) * flex;
			tip = 1.0 - 0.06 * pow(yy / max(hh, 1e-3), 2.0);
		} else if (tail_type == 6) {
			hh = mix(base_h, th, sqrt(k)) * flex;
			tip = 1.0 - 0.35 * pow(yy / max(hh, 1e-3), 2.0);
		} else {
			hh = mix(base_h, th, pow(k, 0.8)) * flex;
			tip = 1.0 - 0.15 * pow(yy / max(hh, 1e-3), 2.0);
		}
		float d_tail = max(abs(yy) - hh, (tx - tip) * tl);
		float a_tail = fill(d_tail) * step(-0.25, tx);
		float rays = 0.5 + 0.5 * sin(atan(yy, tx * tl + 0.05) * 46.0);
		vec3 tc = mix(bodyc * 0.9, fin_c, smoothstep(0.0, 0.4, tx)) * (0.9 + 0.12 * rays);
		tc += vec3(0.16) * smoothstep(0.75, 1.0, tx / max(tip, 0.01));
		acc = over(vec4(tc, a_tail * mix(0.92, 0.72, k)), acc);
	}

	// ── Aletas dorsales (se inclinan hacia atrás con la altura) ──
	float ys = q.y - top;
	if (ys > -0.04) {
		float ts = t + max(ys, 0.0) * dor.w / L;
		float s = (ts - dor.x) / max(dor.y - dor.x, 1e-3);
		if (s > 0.0 && s < 1.0) {
			float fh = min(dor.z * pow(sin(3.1416 * pow(s, 1.25)), dorsal_pt), ylim - top - 0.01);
			float ft = clamp(ys / max(fh, 1e-3), 0.0, 1.0);
			vec3 dc = mix(fin_c, bodyc, 0.25 * (1.0 - ft)) * (0.92 + 0.1 * (0.5 + 0.5 * sin(s * 60.0)));
			dc = mix(dc, dc + 0.16, ft * ft);
			acc = over(vec4(dc, fill(max(ys - fh, -ys - 0.04)) * mix(0.88, 0.62, ft)), acc);
		}
		if (dorsal2 > 0.0) {
			float d0 = dor.x - (dor.y - dor.x) * 1.15;
			float s2 = (ts - d0) / max(dor.x - 0.02 - d0, 1e-3);
			if (s2 > 0.0 && s2 < 1.0) {
				float fh2 = dorsal2 * pow(sin(3.1416 * pow(s2, 1.3)), 0.7);
				acc = over(vec4(fin_c * 0.95, fill(max(ys - fh2, -ys - 0.04)) * 0.8), acc);
			}
		}
		if (adipose > 0.0) {
			float sa = (t - 0.07) / 0.08;
			float ah = 0.045 * max(0.0, 1.0 - sa * sa);
			acc = over(vec4(bodyc * 0.85, fill(max(ys - ah, -ys - 0.03)) * step(abs(sa), 1.0) * 0.85), acc);
		}
	}

	// ── Aleta anal (y pélvica) ──
	float yb = bot - q.y;
	if (yb > -0.04) {
		float ts = t + max(yb, 0.0) * an.w / L;
		float s = (ts - an.x) / max(an.y - an.x, 1e-3);
		if (s > 0.0 && s < 1.0) {
			float fh = min(an.z * pow(sin(3.1416 * pow(s, 1.2)), dorsal_pt * 0.9), ylim + bot - 0.01);
			float ft = clamp(yb / max(fh, 1e-3), 0.0, 1.0);
			vec3 ac = fin_c * (0.9 + 0.1 * (0.5 + 0.5 * sin(s * 54.0)));
			ac = mix(ac, ac + 0.14, ft * ft);
			acc = over(vec4(ac, fill(max(yb - fh, -yb - 0.04)) * mix(0.85, 0.6, ft)), acc);
		}
	}

	// ── Filamentos ventrales (pez ángel) ──
	if (threads > 0.0) {
		vec2 a0 = vec2(xs + L * 0.62, bot_at(0.62) + 0.02);
		vec2 a1 = a0 + vec2(-0.12, -threads);
		a1.y = max(a1.y, -ylim + 0.02);
		acc = over(vec4(fin_c * 0.9, fill(seg(q, a0, a1) - 0.009) * 0.85), acc);
		acc = over(vec4(fin_c * 0.8, fill(seg(q, a0 + vec2(0.03, 0.0), a1 + vec2(0.05, 0.06)) - 0.007) * 0.7), acc);
	}

	// ── Color del cuerpo ──
	vec3 base = col_body;
	float pm = 0.0;
	if (pattern == 1) {
		pm = smoothstep(0.4, -0.7, dx);
	} else if (pattern == 2) {
		vec2 sp = q * 26.0 + seed * 13.0;
		vec2 cell = floor(sp);
		vec2 off = vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5;
		pm = smoothstep(0.3, 0.2, length(fract(sp) - 0.5 - off * 0.35)) * step(0.3, hash(cell));
	} else if (pattern == 3) {
		pm = smoothstep(0.55, 0.75, sin((dx * 3.3 + 0.35) * 3.1416));
	} else if (pattern == 4) {
		pm = smoothstep(0.24, 0.1, abs(dy - 0.16)) * smoothstep(-0.98, -0.6, dx) * smoothstep(0.92, 0.6, dx);
		float red = smoothstep(0.05, -0.3, dy) * smoothstep(0.3, -0.15, dx);
		base = mix(base, col_fin * 1.05, red * 0.95);
	} else if (pattern == 5) {
		// Tres bandas (cabeza, centro, pedúnculo) con ribete oscuro, como el pez payaso.
		float b = abs(fract(dx * 1.67 - 0.25) - 0.5);
		pm = smoothstep(0.13, 0.09, b);
		base = mix(base, vec3(0.06), clamp(smoothstep(0.18, 0.14, b) - pm, 0.0, 1.0));
	} else if (pattern == 6) {
		float nn = vnoise(q * 9.0 + seed * 5.0) * 0.65 + vnoise(q * 21.0 - seed) * 0.35;
		pm = smoothstep(0.47, 0.55, nn);
	} else if (pattern == 7) {
		pm = smoothstep(0.05, -0.12, dx + dy * 0.12);
	} else if (pattern == 8) {
		// "Paleta" del cirujano azul: franja del ojo a la cola y arco hacia la dorsal.
		float c1 = 0.3 - 0.65 * smoothstep(0.25, -0.9, dx);
		float band = smoothstep(0.2, 0.12, abs(dy - c1)) * smoothstep(0.78, 0.6, dx);
		float c2 = 0.3 + 0.85 * smoothstep(0.1, -0.65, dx);
		float arc = smoothstep(0.16, 0.09, abs(dy - c2)) * step(-0.7, dx) * step(dx, 0.12);
		pm = max(band, arc);
	}
	vec3 bc = albinize(mix(base, col_pat, pm));

	// Contrasombreado, escamas, brillo, opérculo y contorno.
	bc = mix(bc * 1.15 + 0.07, bc, smoothstep(-0.95, 0.05, dy));
	bc *= mix(1.0, 0.74, smoothstep(0.4, 1.0, dy));
	vec2 ss = q * vec2(58.0, 66.0);
	ss.x += mod(floor(ss.y), 2.0) * 0.5;
	float scl = smoothstep(0.5, 0.32, length((fract(ss) - 0.5) * vec2(1.0, 1.25)));
	float scl_w = clamp(1.0 - fwidth(q.x) * 70.0, 0.0, 1.0) * smoothstep(0.55, -0.2, dx);
	bc *= 1.0 + (scl - 0.5) * 0.09 * scl_w;
	bc += vec3(1.0) * exp(-pow((dy - 0.5) * 3.2, 2.0)) * smoothstep(-0.75, 0.35, dx) * 0.24;
	float gx = eye_t - 0.12;
	float gill = abs(q.x - (xs + L * gx) - 0.04 * dy * dy);
	bc *= 1.0 - 0.14 * smoothstep(0.012, 0.0, gill) * step(abs(dy), 0.8);
	bc *= 1.0 - 0.24 * smoothstep(0.3, 0.0, inner);
	bc = mix(bc, bc * 0.45, smoothstep(0.07, 0.0, inner) * 0.7);
	bc += col_pat * neon * 0.38 * (0.75 + 0.25 * sin(TIME * 2.2 + seed * 5.0)) * (pm + 0.35);

	// Ojo
	float et = clamp(eye_t, 0.5, 0.95);
	float etop = top_at(et);
	float ebot = bot_at(et);
	vec2 ec = vec2(xs + L * et, mix((etop + ebot) * 0.5, etop, 0.32));
	float er = clamp((etop - ebot) * 0.11, 0.024, 0.06);
	float de = length(q - ec);
	vec3 iris = mix(vec3(0.95, 0.8, 0.35), vec3(0.08, 0.06, 0.05), smoothstep(er * 0.5, er * 0.95, de));
	vec3 eye = mix(mix(vec3(0.04), vec3(0.85, 0.12, 0.2), albino), iris, smoothstep(er * 0.56, er * 0.66, de));
	eye = mix(eye, vec3(1.0), fill(length(q - ec - vec2(-er * 0.25, er * 0.32)) - er * 0.26));
	bc = mix(bc, eye, fill(de - er));
	// Boca
	float my = (top_at(0.985) + bot_at(0.985)) * 0.5 - 0.004;
	bc = mix(bc, bc * 0.35, fill(seg(q, vec2(nose - 0.035, my), vec2(nose, my + 0.004)) - 0.004) * 0.7);

	acc = over(vec4(bc, a_body), acc);

	// ── Pectoral y barbillones (delante del cuerpo) ──
	vec2 pc = q - vec2(xs + L * (eye_t - 0.2), mix(mid, bot, 0.35));
	float ang = -0.45 + 0.35 * sin(tt * 1.3);
	pc = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * pc;
	float pr = length(pc / vec2(max(L * 0.12, 0.07), max(half_h * 0.28, 0.03)));
	acc = over(vec4(mix(fin_c, vec3(1.0), 0.15), fill((pr - 1.0) * 0.05) * 0.5 * step(pc.x, 0.0)), acc);
	if (barbels > 0.0) {
		vec2 b0 = vec2(nose - 0.03, bot_at(0.95) + 0.01);
		float db = min(seg(q, b0, b0 + vec2(0.07, -0.05)), seg(q, b0, b0 + vec2(0.03, -0.08)));
		acc = over(vec4(bodyc * 0.7, fill(db - 0.006)), acc);
	}

	// Halo neón
	float halo = neon * exp(-max(d_body, 0.0) / 0.03) * (1.0 - acc.a);
	acc = over(acc, vec4(col_pat, halo * 0.4));

	float l = dot(acc.rgb, vec3(0.299, 0.587, 0.114));
	acc.rgb = mix(acc.rgb, vec3(l) * 0.85, sick * 0.65);
	acc.rgb = mix(acc.rgb, fog, depth * 0.42);
	COLOR = acc;
}
