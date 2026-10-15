// Código común de los peces 3D (cuerpo y aletas): uniforms, perfil, membranas y natación.
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

float prof(float t, float kr, float kf) {
	t = clamp(t, 0.0, 1.0);
	float u = t < peak ? (peak - t) / peak : (t - peak) / (1.0 - peak);
	float b = max(0.0, 1.0 - u * u);
	return t < peak ? mix(ped, 1.0, pow(b, kr)) : pow(b, kf);
}

float top_at(float t) { return h_top * prof(t, k_rear, k_front); }
float bot_at(float t) { return -h_bot * prof(t, k_bot, mix(k_front, k_bot, 0.5)); }

float ray_mask(float c, float w) {
	float f = abs(fract(c + 0.5) - 0.5);
	float fw = fwidth(c) + 1e-5;
	return clamp((w - f) / fw + 0.5, 0.0, 1.0) * clamp(1.6 - fw * 5.0, 0.0, 1.0);
}

float ray_gap(float c) {
	return abs(fract(c + 0.5) - 0.5) * 2.0;
}

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

// Natación en 3D: la parte trasera gira hacia los lados (eje Y) con una onda que viaja hacia la cola,
// así la cola se escorza al batir; un poco de onda vertical para que también se note de perfil.
vec3 swim(vec3 v, float tt) {
	float L = body_len * 2.0;
	float x0 = 0.97 - L * 0.38;
	float D = x0 + 1.0;
	float d = max(0.0, x0 - v.x);
	float th = sin(tt - v.x * 3.0) * 0.5 * pow(d / D, 1.3) * wag_amp;
	vec3 o = v;
	o.x = mix(v.x, x0 - d * cos(th) - v.z * sin(th), step(1e-5, d));
	o.z = mix(v.z, v.z * cos(th) + d * sin(th), step(1e-5, d));
	o.y += sin(tt - v.x * 3.2) * 0.022 * clamp(d / D * 2.0, 0.0, 1.0) * wag_amp;
	o.z -= sin(tt) * 0.02 * smoothstep(0.3, 1.0, v.x) * wag_amp;
	return o;
}

float swim_tt(float t) {
	return phase + t * auto_wag + seed * 6.28;
}

