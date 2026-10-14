shader_type canvas_item;
// Agua: fondo de la pecera (póster/decorado trasero), degradado de profundidad, rayos de luz,
// cáusticas animadas, turbidez y superficie. Coste bajo: unas pocas lecturas de textura por píxel.

uniform vec3 top_col : source_color = vec3(0.42, 0.88, 0.9);
uniform vec3 deep_col : source_color = vec3(0.02, 0.24, 0.38);
uniform vec3 murk_col : source_color = vec3(0.36, 0.42, 0.16);
uniform float murk = 0.0;            // 0 limpia · 1 muy sucia
uniform float light = 1.0;           // potencia de la pantalla LED
uniform float night = 0.0;
uniform vec2 size = vec2(600.0, 500.0);
uniform int bg = 0;                  // fondo trasero (Catalog.BACKDROPS): 0 ninguno
uniform vec3 bg_a : source_color = vec3(0.0);
uniform vec3 bg_b : source_color = vec3(0.0);
uniform sampler2D caustics : repeat_enable, filter_linear_mipmap;
uniform sampler2D noise : repeat_enable, filter_linear;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float n1(float x, float row) {
	return texture(noise, vec2(x, row)).r;
}

float aa(float d) {
	return clamp(0.5 - d / max(fwidth(d), 1e-4), 0.0, 1.0);
}

// Partículas que caen despacio (nieve, hojas, pétalos): máscara y color aleatorio por partícula.
float drift(vec2 p, float cells, float speed, float r, float sway, out float h) {
	vec2 q = p * cells + vec2(0.0, -TIME * speed);
	vec2 id = floor(q);
	h = hash(id);
	vec2 f = fract(q) - 0.5;
	f.x += sin(TIME * 0.7 + h * 20.0) * sway;
	f += (vec2(hash(id + 3.0), hash(id + 5.0)) - 0.5) * 0.5;
	return aa(length(f * vec2(1.0, 1.0 + h)) - r) * step(0.45, h);
}

// Decorado trasero. Devuelve color (rgb) y cuánto tapa (a). p: x con aspecto, y de 0 (arriba) a 1.
vec4 backdrop(vec2 uv, vec2 p) {
	vec3 c = vec3(0.0);
	float a = 0.0;
	float h;
	if (bg == 1) {
		c = mix(bg_b, bg_a, smoothstep(0.0, 1.0, uv.y));
		a = 0.7;
	} else if (bg == 2) {
		c = mix(bg_b, bg_a, smoothstep(0.0, 0.8, uv.y));
		a = 0.85;
	} else if (bg == 3) {
		// Pared de roca en dos capas con grietas y luz de arriba.
		float h1 = 0.25 + 0.3 * n1(p.x * 0.35, 0.21) + 0.08 * n1(p.x * 1.7, 0.55);
		float h2 = 0.5 + 0.22 * n1(p.x * 0.5 + 3.0, 0.4);
		float tex = texture(noise, p * vec2(1.6, 2.2)).g;
		vec3 rock = mix(bg_a, bg_b, tex) * (0.75 + 0.35 * (1.0 - uv.y));
		float far = smoothstep(h1, h1 + 0.02, uv.y);
		float near = smoothstep(h2, h2 + 0.015, uv.y);
		c = mix(rock * 0.8, rock * 1.05, near);
		c *= 1.0 - 0.25 * smoothstep(0.6, 0.75, texture(noise, p * vec2(3.0, 0.8)).b);
		a = max(far * 0.55, near * 0.75);
	} else if (bg == 4) {
		// Jungla de plantas altas que se mecen.
		float sx = p.x * 9.0 + sin(uv.y * 4.0 + TIME * 0.6 + p.x * 3.0) * 0.25 * (1.0 - uv.y);
		float id = floor(sx);
		float f = abs(fract(sx) - 0.5);
		float top = 0.1 + 0.5 * hash(vec2(id, 1.0));
		float blade = aa((f - 0.22 * smoothstep(top, 1.0, uv.y)) * size.y / 9.0) * step(top, uv.y);
		float sx2 = p.x * 5.0 + 0.5 + sin(uv.y * 3.0 + TIME * 0.4) * 0.15;
		float f2 = abs(fract(sx2) - 0.5);
		float top2 = 0.05 + 0.35 * hash(vec2(floor(sx2), 7.0));
		float blade2 = step(f2, 0.3 * smoothstep(top2, 1.0, uv.y)) * step(top2, uv.y);
		c = mix(bg_a, bg_b, blade * (0.4 + 0.6 * (1.0 - uv.y)));
		a = max(blade2 * 0.45, blade * 0.65);
	} else if (bg == 5) {
		// Arrecife lejano: dos filas de cúpulas de coral de colores y abanicos detrás.
		float fan = smoothstep(0.58, 0.62, texture(noise, vec2(p.x * 2.5, uv.y * 1.2)).r) * smoothstep(0.4, 0.6, uv.y);
		c = mix(bg_a, vec3(0.6, 0.4, 0.8), 0.5) * 0.75;
		a = fan * 0.45;
		for (int i = 0; i < 2; i++) {
			float k = float(i);
			float sx = p.x * (5.0 - k * 2.2) + k * 0.43 + n1(p.x * 0.4 + k, 0.9) * 0.5;
			float seg = floor(sx);
			float f = fract(sx) * 2.0 - 1.0;
			float hs = hash(vec2(seg, 3.0 + k));
			float dome = (0.72 + k * 0.08) + 0.06 * hs - (0.09 + 0.06 * k) * sqrt(max(0.0, 1.0 - f * f));
			vec3 cc = hs < 0.33 ? bg_a : (hs < 0.66 ? bg_b : vec3(0.58, 0.4, 0.82));
			cc *= (0.75 + 0.35 * texture(noise, p * vec2(9.0, 7.0) + k).g) * (1.05 - 0.4 * smoothstep(dome, dome + 0.25, uv.y));
			float inside = smoothstep(dome, dome + 0.01, uv.y);
			c = mix(c, cc * (0.8 + 0.2 * k), inside);
			a = max(a, inside * (0.6 + 0.25 * k));
		}
	} else if (bg == 6) {
		// Nevada submarina: noche azul, abetos lejanos y copos que caen.
		c = mix(bg_a * 1.6, bg_a, uv.y);
		a = 0.7;
		float hill = 0.75 + 0.06 * n1(p.x * 0.6, 0.3);
		float tx = fract(p.x * 4.0) - 0.5;
		float tree_h = 0.12 + 0.08 * hash(vec2(floor(p.x * 4.0), 2.0));
		float tree = step(abs(tx) * 2.2, (uv.y - (hill - tree_h)) / tree_h) * step(uv.y, hill + 0.02);
		vec3 sil = bg_a * 0.45;
		c = mix(c, sil, max(step(hill, uv.y), tree) * 0.9);
		c = mix(c, vec3(0.92, 0.96, 1.0), step(hill, uv.y) * 0.35);
		float fl = drift(p, 9.0, 0.06, 0.08, 0.15, h) + drift(p + 0.37, 16.0, 0.09, 0.06, 0.12, h) * 0.6;
		c = mix(c, bg_b, fl * 0.9);
		a = max(a, fl * 0.9);
	} else if (bg == 7) {
		// Bosque otoñal: troncos, copas doradas y hojas cayendo.
		c = mix(bg_b, bg_a, uv.y * 0.9);
		a = 0.22;
		float trunk = step(abs(fract(p.x * 2.3 + 0.3) - 0.5), 0.05 * (0.7 + 0.6 * hash(vec2(floor(p.x * 2.3 + 0.3), 4.0)))) * step(0.3, uv.y);
		// Copa redonda (tres lóbulos) encima de cada tronco.
		float tx = p.x * 2.3 + 0.3;
		float tid = floor(tx);
		float dxp = (fract(tx) - 0.5) / 2.3;
		float cy = 0.2 + 0.1 * hash(vec2(tid, 8.0));
		float wob = 0.012 * texture(noise, p * 6.0).r;
		float cd = min(length(vec2(dxp, (uv.y - cy) * 1.3)), min(length(vec2(dxp - 0.07, (uv.y - cy - 0.06) * 1.3)), length(vec2(dxp + 0.07, (uv.y - cy - 0.05) * 1.3))));
		float crown = smoothstep(0.1, 0.095, cd + wob);
		vec3 crown_c = mix(bg_b, vec3(0.85, 0.3, 0.1), hash(vec2(tid, 2.0))) * (0.85 + 0.3 * texture(noise, p * 5.0).g);
		c = mix(c, bg_a * 0.55, trunk * 0.9);
		c = mix(c, crown_c, crown);
		float lf = drift(p, 7.0, 0.05, 0.09, 0.3, h);
		c = mix(c, mix(vec3(0.95, 0.55, 0.15), vec3(0.8, 0.22, 0.1), h), lf);
		a = max(max(a, crown * 0.75), max(trunk * 0.8, lf));
	} else if (bg == 8) {
		// Luna llena tras el agua, bruma y siluetas de rocas puntiagudas.
		c = mix(bg_a * 1.5, bg_a, uv.y);
		vec2 mc = vec2(size.x / size.y * 0.72, 0.28);
		float dm = length(p - mc);
		c = mix(c, bg_b, smoothstep(0.13, 0.12, dm));
		c += bg_b * 0.25 * exp(-dm * 6.0);
		c *= 1.0 - 0.15 * smoothstep(0.12, 0.0, dm) * smoothstep(0.45, 0.6, texture(noise, p * 4.0).r);
		float ridge = 0.62 + 0.1 * n1(p.x * 0.9, 0.5) + 0.06 * abs(sin(p.x * 11.0));
		c = mix(c, bg_a * 0.3, smoothstep(ridge, ridge + 0.01, uv.y));
		float mist = smoothstep(0.4, 0.7, texture(noise, vec2(p.x * 0.8 + TIME * 0.01, uv.y * 2.0)).r) * smoothstep(0.4, 0.8, uv.y);
		c = mix(c, vec3(0.75, 0.7, 0.9), mist * 0.25);
		a = 0.72;
	} else if (bg == 9) {
		// Primavera: degradado rosado y pétalos que bajan girando.
		c = mix(bg_b, bg_a, uv.y);
		a = 0.25;
		float pt = drift(p, 6.0, 0.05, 0.12, 0.35, h) + drift(p + 0.51, 10.0, 0.07, 0.1, 0.3, h) * 0.8;
		c = mix(c, vec3(1.0, 0.82, 0.9), pt);
		a = max(a, pt * 0.95);
	} else if (bg == 10) {
		// Bambú sumergido: cañas con nudos a distintas distancias.
		c = mix(bg_b * 0.7, bg_a, uv.y);
		a = 0.5;
		for (int i = 0; i < 2; i++) {
			float k = float(i);
			float sx = p.x * (3.0 + k * 2.5) + k * 0.37;
			float f = abs(fract(sx) - 0.5);
			float w = 0.09 + 0.04 * hash(vec2(floor(sx), k));
			float stalk = aa((f - w) * size.y / (3.0 + k * 2.5));
			float node = aa(abs(fract(uv.y * (5.0 + k * 2.0) + hash(vec2(floor(sx), 9.0))) - 0.5) * 30.0 - 13.5);
			vec3 sc = mix(bg_b, bg_a, k * 0.6) * (0.8 + 0.3 * (1.0 - f / max(w, 0.01)));
			sc *= 1.0 - node * 0.35;
			c = mix(c, sc, stalk * (0.55 + k * 0.35));
			a = max(a, stalk * (0.6 + k * 0.3));
		}
	} else if (bg == 11) {
		// Dunas al sol: arena lejana ondulada y un sol que se filtra.
		c = mix(vec3(0.55, 0.9, 0.95), bg_a, 0.15);
		vec2 sc = vec2(size.x / size.y * 0.25, -0.05);
		c += bg_b * 0.5 * exp(-length(p - sc) * 3.5);
		float d1 = 0.6 + 0.08 * sin(p.x * 3.0 + 1.0) + 0.04 * n1(p.x * 0.8, 0.2);
		float d2 = 0.72 + 0.06 * sin(p.x * 4.5 + 2.6);
		vec3 sand = bg_a * (0.85 + 0.2 * texture(noise, p * vec2(6.0, 18.0)).g);
		c = mix(c, sand * 0.9, smoothstep(d1, d1 + 0.01, uv.y));
		c = mix(c, sand * (1.0 + 0.1 * sin(p.x * 40.0 + uv.y * 90.0)), smoothstep(d2, d2 + 0.01, uv.y));
		a = 0.55;
	}
	return vec4(c, a);
}

void fragment() {
	vec2 uv = UV;
	float aspect = size.x / size.y;
	vec2 p = vec2(uv.x * aspect, uv.y);

	vec3 col = mix(top_col, deep_col, smoothstep(-0.1, 1.05, uv.y));
	// El decorado se ve a través del agua: lo velan el color del agua y la distancia.
	if (bg > 0) {
		vec4 b = backdrop(uv, p);
		vec3 veiled = mix(b.rgb, col, 0.16 + 0.12 * (1.0 - uv.y));
		col = mix(col, veiled, b.a);
	}

	// Rayos de luz inclinados con anchura irregular.
	float sx = uv.x * aspect * 0.9 + uv.y * 0.32;
	float r1 = texture(noise, vec2(sx * 0.55 + TIME * 0.012, 0.31)).r;
	float r2 = texture(noise, vec2(sx * 1.3 - TIME * 0.02, 0.73)).g;
	float rays = smoothstep(0.5, 0.85, r1) * 0.8 + smoothstep(0.55, 0.9, r2) * 0.5;
	rays *= (1.0 - smoothstep(0.0, 0.95, uv.y)) * light;
	col += vec3(0.8, 1.0, 0.92) * rays * 0.17;

	// Cáusticas sobre el cristal trasero: suaves (mip borroso) y más visibles abajo.
	vec2 cuv = p * 1.1;
	float c1 = texture(caustics, cuv + vec2(TIME * 0.018, TIME * 0.011), 1.6).r;
	float c2 = texture(caustics, cuv * 1.37 + vec2(-TIME * 0.014, TIME * 0.016), 1.6).r;
	float caus = min(c1, c2);
	col += vec3(0.7, 1.0, 1.0) * caus * (0.035 + 0.06 * uv.y) * light;

	// Turbidez por suciedad y penumbra nocturna.
	float m = murk * (0.45 + 0.55 * uv.y);
	col = mix(col, murk_col * (0.55 + 0.45 * (1.0 - uv.y)), m * 0.6);
	col *= mix(1.0, 0.72, night);

	// Superficie ondulada con brillo.
	float surf = 0.016 + 0.004 * sin(p.x * 16.0 + TIME * 1.4) + 0.0025 * sin(p.x * 37.0 - TIME * 2.1);
	float above = smoothstep(surf + 0.004, surf - 0.002, uv.y);
	col = mix(col, top_col * 1.12 + vec3(0.1), above * 0.75);
	col += vec3(1.0) * smoothstep(0.005, 0.0, abs(uv.y - surf)) * 0.4;

	// Viñeta lateral: da volumen al tanque.
	float vig = smoothstep(0.0, 0.2, uv.x) * smoothstep(0.0, 0.2, 1.0 - uv.x);
	col *= mix(0.74, 1.0, vig);
	COLOR = vec4(col, 1.0);
}
