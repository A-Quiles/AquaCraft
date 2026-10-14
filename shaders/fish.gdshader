shader_type canvas_item;
// Pez 100% procedural con anatomía por especie: perfil de lomo y vientre, 7 tipos de cola, dorsal
// (y 2ª dorsal), anal, adiposa, pectoral, pélvicas, barbillones y filamentos.
// Aletas: membrana translúcida con radios, borde festoneado entre radios y ondas que la recorren al nadar.
// Cuerpo: escamas imbricadas con destellos, contrasombreado, especular, luz de contorno y branquias que respiran.
// Ejes: x de -1 (cola) a 1 (hocico), y hacia arriba; el quad mide 2 × 2/aspect. Bordes suaves vía fwidth.

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
	float w = min(fwidth(d) * 0.8, 0.05) + 1e-5;     // tope: donde la forma se pliega, fwidth se dispara
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

// Radios de aleta: c vale un entero sobre cada radio. Se apagan cuando quedan a menos de ~3 px.
float ray_mask(float c, float w) {
	float f = abs(fract(c + 0.5) - 0.5);
	float fw = fwidth(c) + 1e-5;
	return clamp((w - f) / fw + 0.5, 0.0, 1.0) * clamp(1.6 - fw * 5.0, 0.0, 1.0);
}

// 0 sobre un radio, 1 a medio camino entre dos: la membrana se recoge entre radios (borde festoneado).
float ray_gap(float c) {
	return abs(fract(c + 0.5) - 0.5) * 2.0;
}

// Membrana de aleta. u: 0 en la base → 1 en el borde; c: coordenada de radios; w: ondulación.
vec4 membrane(vec3 base_c, vec3 fin_c, float u, float c, float spots, float alpha_k, float w) {
	float r = ray_mask(c, mix(0.14, 0.06, u));
	vec3 col = mix(base_c, fin_c, smoothstep(0.0, 0.38, u));
	col = mix(col * 1.07 + 0.035, col * 0.74, r);                                   // radios más saturados
	col *= 1.0 - 0.12 * smoothstep(0.55, 0.78, u) * (1.0 - smoothstep(0.82, 0.95, u)); // banda submarginal
	col += vec3(0.85, 0.96, 1.0) * 0.2 * smoothstep(0.84, 1.0, u);                  // borde fino a contraluz
	col *= 0.93 + 0.1 * sin(w);                                                     // pliegues que captan la luz
	col = mix(col, albinize(col_pat) * 0.85, spots);                                 // manchas del color del patrón
	float a = mix(0.9, 0.4, u * u);
	a = mix(a * 0.78, min(1.0, a * 1.25), r);
	return vec4(col, a * alpha_k);
}

// Lunares o moteado también en las aletas, como en los guppys y platys reales.
float fin_spots(vec2 q) {
	if (pattern == 2) {
		vec2 sp = q * 30.0 + seed * 9.0;
		vec2 cell = floor(sp);
		vec2 off = vec2(hash(cell + 1.3), hash(cell + 5.1)) - 0.5;
		return smoothstep(0.26, 0.16, length(fract(sp) - 0.5 - off * 0.3)) * step(0.45, hash(cell)) * 0.75;
	} else if (pattern == 6) {
		return smoothstep(0.5, 0.58, vnoise(q * 11.0 + seed * 3.0)) * 0.55;
	}
	return 0.0;
}

mat2 rot(float a) {
	return mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a)));
}

// Aleta en abanico desde un punto (pectoral y pélvicas). dir: hacia dónde apunta; open: 0 cerrada · 1 abierta.
vec4 fan_fin(vec2 q, vec2 pivot, float ang, float len, float wide, float open, float nrays, vec3 base_c, vec3 fin_c, float alpha_k, float w) {
	vec2 v = rot(-ang) * (q - pivot);
	float u = v.x / len;
	float hw = len * wide * (0.12 + 0.88 * open) * sqrt(clamp(u, 0.0, 1.0)) * (1.25 - 0.45 * u);
	float vn = clamp(v.y / max(hw, 1e-4), -1.5, 1.5);
	float c = vn * nrays * 0.5;
	float tip = 1.0 - 0.28 * vn * vn - 0.05 * ray_gap(c);
	float d = max(abs(v.y) - hw, max(-v.x, (u - tip) * len));
	vec4 m = membrane(base_c, fin_c, clamp(u / max(tip, 0.1), 0.0, 1.0), c, 0.0, alpha_k, w + u * 3.0);
	return vec4(m.rgb, m.a * fill(d));
}

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
	float flow = 1.0 + veil * 0.9 + (tail_type == 3 ? 0.7 : 0.0);   // las aletas largas ondean más

	// Onda de natación: nace tras la cabeza y crece hacia la cola; el hocico apenas cabecea.
	float tailw = clamp((xs + L * 0.75 - p.x) / (L * 0.75 + tl), 0.0, 1.0);
	float bend = (sin(tt - p.x * 3.2) * 0.08 * tailw * tailw - sin(tt) * 0.006 * smoothstep(0.3, 1.0, p.x)) * wag_amp;
	vec2 q = vec2(p.x, p.y - bend);

	// ── Cuerpo (forma) ──
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

	// ── Pélvicas: bajo el vientre, por detrás del cuerpo ──
	if (threads <= 0.0) {
		float pt = clamp(eye_t - 0.3, 0.25, 0.7);
		float hh_p = top_at(pt) - bot_at(pt);
		vec2 pv = vec2(xs + L * pt, bot_at(pt) + hh_p * 0.14);
		float plen = clamp(hh_p * 0.42, 0.035, 0.15) * (1.0 + veil * 0.6);
		vec4 pf = fan_fin(q, pv, 3.1416 + 0.75 + 0.12 * sin(tt * 1.1 + 1.0), plen, 0.42, 0.85, 5.0, bodyc, fin_c, 0.8, tt * 0.8);
		acc = over(pf, acc);
	}

	// ── Cola ──
	float pmid = (h_top - h_bot) * ped * 0.5;
	float tx = (xs - q.x) / tl;
	if (tx > -0.25) {
		float yy = q.y - pmid;
		float k = clamp(tx, 0.0, 1.0);
		// La onda sigue recorriendo la cola: el borde va con retraso respecto a la base.
		yy -= sin(tt - k * 3.0) * 0.045 * flow * k * k * wag_amp;
		float base_h = ped * (h_top + h_bot) * 0.42;
		float flex = 1.0 + 0.09 * sin(tt + 1.5);
		float hh;
		float tip;
		float nr = 8.0;
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
			nr = 10.0;
		} else if (tail_type == 4) {
			hh = mix(base_h, th, pow(k, 1.1)) * flex;
			float ny = clamp(abs(yy) / max(hh, 1e-3), 0.0, 1.0);
			tip = 0.52 + 0.55 * ny * ny;
		} else if (tail_type == 5) {
			hh = mix(base_h, th, k) * flex;
			tip = 1.0 - 0.06 * pow(yy / max(hh, 1e-3), 2.0);
			nr = 10.0;
		} else if (tail_type == 6) {
			hh = mix(base_h, th, sqrt(k)) * flex;
			tip = 1.0 - 0.35 * pow(yy / max(hh, 1e-3), 2.0);
			nr = 6.0;
		} else {
			hh = mix(base_h, th, pow(k, 0.8)) * flex;
			tip = 1.0 - 0.15 * pow(yy / max(hh, 1e-3), 2.0);
		}
		float ny = clamp(yy / max(hh, 1e-3), -1.0, 1.0);
		float c = ny * nr;
		tip -= 0.07 * pow(ray_gap(c), 1.6);                  // festón entre radios
		float d_tail = max(abs(yy) - hh, (tx - tip) * tl);
		float a_tail = fill(d_tail) * step(-0.25, tx);
		float u = clamp(tx / max(tip, 0.05), 0.0, 1.0);
		vec4 m = membrane(bodyc * 0.92, fin_c, u, c, fin_spots(q) * smoothstep(0.15, 0.4, u), 1.0, ny * 2.5 - tt * 1.4 + u * 4.0);
		acc = over(vec4(m.rgb, m.a * a_tail), acc);
	}

	// ── Aletas dorsales (se inclinan hacia atrás con la altura y ondean de delante atrás) ──
	float ys = q.y - top;
	if (ys > -0.04) {
		float sweep = dor.w * (1.0 + 0.12 * flow * sin(tt * 0.8));
		float ts = t + max(ys, 0.0) * sweep / L;
		float s = (ts - dor.x) / max(dor.y - dor.x, 1e-3);
		if (s > 0.0 && s < 1.0) {
			float c = s * max(5.0, (dor.y - dor.x) * L * 38.0);
			float fh = min(dor.z * pow(sin(3.1416 * pow(s, 1.25)), dorsal_pt), ylim - top - 0.01);
			fh *= (1.0 + 0.06 * flow * sin(s * 7.0 - tt * 1.6)) * (1.0 - 0.08 * pow(ray_gap(c), 1.5));
			float ft = clamp(ys / max(fh, 1e-3), 0.0, 1.0);
			vec4 m = membrane(bodyc, fin_c, ft, c, fin_spots(q) * 0.7, 0.96, s * 7.0 - tt * 1.6 + ft * 2.0);
			acc = over(vec4(m.rgb, m.a * fill(max(ys - fh, -ys - 0.04))), acc);
		}
		if (dorsal2 > 0.0) {
			float d0 = dor.x - (dor.y - dor.x) * 1.15;
			float s2 = (ts - d0) / max(dor.x - 0.02 - d0, 1e-3);
			if (s2 > 0.0 && s2 < 1.0) {
				float c2 = s2 * 6.0;
				float fh2 = dorsal2 * pow(sin(3.1416 * pow(s2, 1.3)), 0.7) * (1.0 - 0.08 * pow(ray_gap(c2), 1.5));
				vec4 m2 = membrane(bodyc, fin_c * 0.95, clamp(ys / max(fh2, 1e-3), 0.0, 1.0), c2, 0.0, 0.9, s2 * 6.0 - tt * 1.6);
				acc = over(vec4(m2.rgb, m2.a * fill(max(ys - fh2, -ys - 0.04))), acc);
			}
		}
		if (adipose > 0.0) {
			float sa = (t - 0.07) / 0.08;
			float ah = 0.045 * max(0.0, 1.0 - sa * sa);
			acc = over(vec4(bodyc * 0.85, fill(max(ys - ah, -ys - 0.03)) * step(abs(sa), 1.0) * 0.85), acc);
		}
	}

	// ── Aleta anal ──
	float yb = bot - q.y;
	if (yb > -0.04) {
		float ts = t + max(yb, 0.0) * an.w * (1.0 + 0.12 * flow * sin(tt * 0.8 + 1.0)) / L;
		float s = (ts - an.x) / max(an.y - an.x, 1e-3);
		if (s > 0.0 && s < 1.0) {
			float c = s * max(5.0, (an.y - an.x) * L * 38.0);
			float fh = min(an.z * pow(sin(3.1416 * pow(s, 1.2)), dorsal_pt * 0.9), ylim + bot - 0.01);
			fh *= (1.0 + 0.07 * flow * sin(s * 6.0 - tt * 1.5 + 0.8)) * (1.0 - 0.08 * pow(ray_gap(c), 1.5));
			float ft = clamp(yb / max(fh, 1e-3), 0.0, 1.0);
			vec4 m = membrane(bodyc * 0.95, fin_c, ft, c, fin_spots(q) * 0.7, 0.92, s * 6.0 - tt * 1.5 + ft * 2.0);
			acc = over(vec4(m.rgb, m.a * fill(max(yb - fh, -yb - 0.04))), acc);
		}
	}

	// ── Filamentos ventrales (pez ángel): ondean con el agua ──
	if (threads > 0.0) {
		vec2 a0 = vec2(xs + L * 0.62, bot_at(0.62) + 0.02);
		vec2 a1 = a0 + vec2(-0.12 + 0.03 * sin(tt * 0.9), -threads);
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
	} else if (pattern == 9) {
		// Rayas longitudinales (pez cebra, ángel emperador).
		pm = smoothstep(0.35, 0.65, sin(dy * 15.0 + dx * 1.2)) * smoothstep(-0.95, -0.75, dx) * smoothstep(0.95, 0.7, dx);
	} else if (pattern == 10) {
		// Triángulo negro en la mitad trasera (rasbora arlequín).
		float w = (dx + 0.8) * 0.32;
		pm = smoothstep(0.03, -0.03, abs(dy + 0.05) - w) * step(dx, 0.2) * smoothstep(-0.85, -0.6, dx);
	}
	vec3 bc = albinize(mix(base, col_pat, pm));
	bc *= 0.95 + 0.1 * vnoise(q * 7.0 + seed * 11.0);                       // moteado natural muy suave

	// ── Volumen: sección ovalada, morro y pedúnculo redondeados, luz desde arriba y de frente ──
	float nz0 = sqrt(max(0.0, 1.0 - dy * dy));
	float nxs = smoothstep(0.5, 1.0, dx) * 0.9 - smoothstep(-0.7, -1.0, dx) * 0.4;
	vec3 n = normalize(vec3(nxs * nz0, dy, nz0 + 0.05));
	vec3 ld = normalize(vec3(0.25, 0.8, 0.55));
	float lam = clamp(dot(n, ld) * 0.6 + 0.45, 0.0, 1.0);
	// Contrasombreado: lomo más oscuro, vientre claro y algo nacarado.
	vec3 belly = mix(bc, vec3(1.0, 0.98, 0.94), 0.32) * 1.04;
	bc = mix(belly, bc, smoothstep(-0.9, -0.15, dy));
	bc = mix(bc, bc * vec3(0.72, 0.76, 0.84), smoothstep(0.35, 1.0, dy) * 0.4);
	bc *= mix(0.66, 1.1, lam);

	// ── Escamas imbricadas: cada fila tapa el arranque de la siguiente, así solo se ve el borde trasero ──
	vec2 g = vec2(nose - q.x, q.y) * 30.0;                 // 1 = distancia entre filas
	const float SC = 0.55;                                 // separación entre columnas (las escamas se solapan)
	const float SR = 0.75;
	float c0 = floor(g.x / SC);
	float bd = 1.0;
	float bx = 0.0;
	float shade = 0.0;
	vec2 bid = vec2(0.0);
	for (int i = 0; i >= -1; i--) {
		float cx = c0 + float(i);
		float off = mod(cx, 2.0) * 0.5;
		vec2 cc = vec2(cx * SC, floor(g.y - off + 0.5) + off);
		vec2 dv = g - cc;
		float d = length(dv) / SR;
		if (d < 1.0) {                                     // la más adelantada que cubre el punto queda encima
			bd = d;
			bx = dv.x / SR;
			bid = vec2(cx, cc.y);
		} else if (i == -1) {
			shade = smoothstep(1.2, 1.0, d);               // sombra que proyecta la escama de delante
		}
	}
	float sc_w = clamp(1.5 - fwidth(g.x) * 3.0, 0.0, 1.0) * smoothstep(0.58, 0.25, dx) * smoothstep(-1.0, -0.72, dy) * smoothstep(-0.98, -0.82, dx);
	float edge = smoothstep(0.82, 0.98, bd) * smoothstep(-0.1, 0.3, bx);       // borde libre (trasero)
	float glint = hash(bid + seed * 3.0);
	bc *= 1.0 - (edge * 0.15 + shade * 0.1) * sc_w;
	bc += bc * smoothstep(0.5, 0.85, bd) * (1.0 - edge) * smoothstep(0.0, 0.6, bx) * 0.08 * sc_w * lam;  // reflejo junto al borde
	bc += vec3(1.0, 0.98, 0.9) * pow(glint, 22.0) * (1.0 - bd) * sc_w * 0.4
		* (0.5 + 0.5 * sin(TIME * 1.7 + glint * 40.0 + phase * 0.2));          // destellos sueltos
	// Iridiscencia que cambia con el movimiento.
	vec3 iri = 0.5 + 0.5 * cos(6.2832 * (dy * 0.8 + dx * 0.3 + tt * 0.05 + vec3(0.0, 0.33, 0.67)));
	bc += iri * 0.06 * smoothstep(-0.2, 0.6, dy) * (1.0 - bd * 0.6) * sc_w;

	// ── Brillo especular (roto por las escamas), contorno y rebote del fondo ──
	vec3 hv = normalize(ld + vec3(0.0, 0.0, 1.0));
	float spec = pow(max(dot(n, hv), 0.0), 26.0);
	bc += vec3(1.0) * spec * 0.3 * (0.65 + 0.35 * (1.0 - edge * sc_w)) * smoothstep(-0.85, 0.3, dx);
	float rim = pow(1.0 - nz0, 3.0);
	bc += vec3(0.8, 0.95, 1.0) * rim * smoothstep(0.0, 0.8, dy) * 0.22;
	bc += vec3(0.95, 0.85, 0.6) * rim * smoothstep(0.0, -0.8, dy) * 0.07;
	// Línea lateral punteada.
	float ll = abs(dy - (0.18 + 0.12 * dx));
	bc *= 1.0 - 0.08 * smoothstep(0.03, 0.0, ll) * step(-0.85, dx) * step(dx, eye_t * 2.0 - 1.25) * (0.6 + 0.4 * step(0.5, fract(q.x * 40.0)));
	// Opérculo (tapa de las branquias): sombra en media luna con borde claro; se mueve al respirar.
	float breath = 0.004 * sin(TIME * 3.2 + seed * 7.0);
	float gx = xs + L * (eye_t - 0.13) + breath;
	float gd = q.x - gx - 0.05 * dy * dy;
	bc *= 1.0 - 0.16 * smoothstep(0.0, -0.04, gd) * smoothstep(-0.08, -0.02, gd) * step(abs(dy), 0.85);
	bc += vec3(0.09) * smoothstep(0.008, 0.0, abs(gd)) * step(abs(dy), 0.8);
	// Cabeza algo más lisa y brillante que el resto.
	bc += vec3(0.04) * smoothstep(0.0, 0.01, gd) * lam;
	// Borde: piel fina que oscurece al girar hacia fuera.
	bc *= 1.0 - 0.16 * smoothstep(0.22, 0.0, inner);
	bc = mix(bc, bc * 0.5, smoothstep(0.05, 0.0, inner) * 0.45 * (1.0 - smoothstep(0.2, 0.9, dy)));
	bc += col_pat * neon * 0.38 * (0.75 + 0.25 * sin(TIME * 2.2 + seed * 5.0)) * (pm + 0.35);

	// ── Ojo: cuenca, iris dorado con estrías, pupila y dos reflejos ──
	float et = clamp(eye_t, 0.5, 0.95);
	float etop = top_at(et);
	float ebot = bot_at(et);
	vec2 ec = vec2(xs + L * et, mix((etop + ebot) * 0.5, etop, 0.32));
	float er = clamp((etop - ebot) * 0.12, 0.026, 0.065);
	float de = length(q - ec);
	float ang_e = atan(q.y - ec.y, q.x - ec.x);
	vec3 iris = mix(vec3(1.0, 0.84, 0.42), vec3(0.62, 0.36, 0.12), 0.5 + 0.5 * sin(ang_e * 16.0));
	iris = mix(iris, mix(iris, col_pat, 0.3), smoothstep(er * 0.6, er * 0.9, de));
	iris *= mix(1.15, 0.8, smoothstep(er * 0.4, er * 0.95, de)) * (0.85 + 0.25 * smoothstep(-er, er, q.y - ec.y));
	iris = mix(iris, vec3(0.05, 0.04, 0.04), smoothstep(er * 0.82, er * 0.99, de));   // anillo oscuro
	vec2 pup = ec + vec2(er * 0.06, 0.0);
	vec3 eye = mix(mix(vec3(0.015), vec3(0.85, 0.12, 0.2), albino), iris, smoothstep(er * 0.47, er * 0.57, length(q - pup)));
	eye = mix(eye, vec3(1.0), fill(length(q - ec - vec2(-er * 0.3, er * 0.32)) - er * 0.22) * 0.95);
	eye = mix(eye, vec3(1.0), fill(length(q - ec - vec2(er * 0.28, -er * 0.28)) - er * 0.09) * 0.7);
	bc *= 1.0 - 0.32 * fill(de - er * 1.4) * (1.0 - fill(de - er));                     // cuenca
	bc += vec3(0.08) * fill(abs(de - er * 1.42) - er * 0.06) * step(0.0, q.y - ec.y);   // párpado claro arriba
	bc = mix(bc, eye, fill(de - er));
	// Boca con labio
	float my = (top_at(0.985) + bot_at(0.985)) * 0.5 - 0.004;
	bc = mix(bc, bc * 0.35, fill(seg(q, vec2(nose - 0.04, my), vec2(nose, my + 0.004)) - 0.0045) * 0.75);
	bc += vec3(0.06) * fill(seg(q, vec2(nose - 0.035, my + 0.009), vec2(nose - 0.005, my + 0.011)) - 0.003);

	acc = over(vec4(bc, a_body), acc);

	// ── Pectoral (delante del cuerpo): aletea abriéndose y cerrándose ──
	float flap = 0.5 + 0.5 * sin(tt * 1.3);
	vec2 pc0 = vec2(xs + L * (eye_t - 0.19), mix(mid, bot, 0.3));
	float plen = clamp(L * 0.15, 0.06, 0.16) * (1.0 + veil * 0.4);
	vec4 pf = fan_fin(q, pc0, 3.1416 + 0.4 + 0.3 * flap, plen, 0.38 * (top - bot) / max(plen, 0.01), mix(0.45, 1.0, flap), 7.0,
		mix(fin_c, bodyc, 0.4), fin_c, 0.55, tt * 1.3);
	acc = over(pf, acc);
	if (barbels > 0.0) {
		vec2 b0 = vec2(nose - 0.03, bot_at(0.95) + 0.01);
		float wv = 0.01 * sin(tt * 1.5);
		float db = min(seg(q, b0, b0 + vec2(0.07, -0.05 + wv)), seg(q, b0, b0 + vec2(0.03, -0.08 - wv)));
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
