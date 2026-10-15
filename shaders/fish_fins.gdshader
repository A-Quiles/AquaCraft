shader_type spatial;
// Aletas del pez en 3D: membranas translúcidas (las mismas que en 2D) sobre planos que se doblan con
// el cuerpo. COLOR.r: 0 aletas del plano medio · 0.5 pectoral · 1 pélvica. UV2: pivote de las laterales.
render_mode blend_mix, cull_disabled, depth_draw_never, diffuse_burley, specular_schlick_ggx;
#include "res://shaders/fish_common.gdshaderinc"

varying vec3 rest;
varying float part;

void vertex() {
	rest = VERTEX;
	part = COLOR.r;
	float tt = swim_tt(TIME);
	vec3 v = VERTEX;
	if (part > 0.25) {
		// Las laterales se abren hacia fuera del cuerpo al aletear.
		float side = sign(v.z);
		float flap = 0.5 + 0.5 * sin(tt * 1.3 + (part > 0.75 ? 1.0 : 0.0));
		float d = length(v.xy - UV2);
		v.z += side * d * (0.35 + 0.45 * flap);
	}
	VERTEX = swim(v, tt);
}

void fragment() {

	float ylim = 1.0 / aspect;
	vec2 p = rest.xy;
	float tt = swim_tt(TIME);

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
	float bend = 0.0;                     // la malla ya se dobla en vertex()
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


	if (part < 0.25) {
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

	if (barbels > 0.0) {
		vec2 b0 = vec2(nose - 0.03, bot_at(0.95) + 0.01);
		float wv = 0.01 * sin(tt * 1.5);
		float db = min(seg(q, b0, b0 + vec2(0.07, -0.05 + wv)), seg(q, b0, b0 + vec2(0.03, -0.08 - wv)));
		acc = over(vec4(bodyc * 0.7, fill(db - 0.006)), acc);
	}


	} else if (part < 0.75) {
	// ── Pectoral (delante del cuerpo): aletea abriéndose y cerrándose ──
	float flap = 0.5 + 0.5 * sin(tt * 1.3);
	vec2 pc0 = vec2(xs + L * (eye_t - 0.19), mix(mid, bot, 0.3));
	float plen = clamp(L * 0.15, 0.06, 0.16) * (1.0 + veil * 0.4);
	vec4 pf = fan_fin(q, pc0, 3.1416 + 0.4 + 0.3 * flap, plen, 0.38 * (top - bot) / max(plen, 0.01), mix(0.45, 1.0, flap), 7.0,
		mix(fin_c, bodyc, 0.4), fin_c, 0.55, tt * 1.3);
	acc = over(pf, acc);

	} else {
	// ── Pélvicas: bajo el vientre, por detrás del cuerpo ──
	{
		float pt = clamp(eye_t - 0.3, 0.25, 0.7);
		float hh_p = top_at(pt) - bot_at(pt);
		vec2 pv = vec2(xs + L * pt, bot_at(pt) + hh_p * 0.14);
		float plen = clamp(hh_p * 0.42, 0.035, 0.15) * (1.0 + veil * 0.6);
		vec4 pf = fan_fin(q, pv, 3.1416 + 0.75 + 0.12 * sin(tt * 1.1 + 1.0), plen, 0.42, 0.85, 5.0, bodyc, fin_c, 0.8, tt * 0.8);
		acc = over(pf, acc);
	}


	}
	if (acc.a < 0.02) {
		discard;
	}
	float l = dot(acc.rgb, vec3(0.299, 0.587, 0.114));
	acc.rgb = mix(acc.rgb, vec3(l) * 0.85, sick * 0.65);
	acc.rgb = mix(acc.rgb, fog, depth * 0.42);
	ALBEDO = acc.rgb;
	ALPHA = acc.a;
	EMISSION = acc.rgb * 0.25;                       // la membrana deja pasar la luz
	ROUGHNESS = 0.55;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
