shader_type spatial;
// Cuerpo del pez en 3D: misma piel que el pez 2D (patrones, escamas, ojo, branquias) sobre una malla
// con volumen; la luz y el brillo los pone el motor. Generado a partir de fish.gdshader.
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
#include "res://shaders/fish_common.gdshaderinc"

varying vec3 rest;

void vertex() {
	rest = VERTEX;
	VERTEX = swim(VERTEX, swim_tt(TIME));
}

void fragment() {
	vec3 emis = vec3(0.0);

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
	emis = col_pat * neon * 0.5 * (0.75 + 0.25 * sin(TIME * 2.2 + seed * 5.0)) * (pm + 0.35);
	bc += col_pat * neon * 0.15 * (0.75 + 0.25 * sin(TIME * 2.2 + seed * 5.0)) * (pm + 0.35);

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


	float l = dot(bc, vec3(0.299, 0.587, 0.114));
	bc = mix(bc, vec3(l) * 0.85, sick * 0.65);
	bc = mix(bc, fog, depth * 0.42);
	float eye_m = fill(de - er);
	ALBEDO = bc;
	EMISSION = emis + bc * 0.12;                     // algo de luz propia: el agua ilumina por todos lados
	ROUGHNESS = mix(0.38, 0.08, eye_m);
	SPECULAR = mix(0.45, 0.9, eye_m);
}
