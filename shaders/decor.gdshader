shader_type canvas_item;
// Plantas y adornos bajo el agua con acabado realista: textura fina, sombra de contacto en la base,
// luz de la superficie arriba, cáusticas que pasan por encima y bruma según lo lejos que estén.
// Las plantas además ondulan con la corriente (amp > 0; la base no se mueve).

uniform float height = 200.0;
uniform float amp = 0.0;
uniform float phase = 0.0;
uniform float tint = 0.0;            // oscurece de noche
uniform float fog = 0.0;             // 0 delante · más al fondo
uniform vec3 fog_col : source_color = vec3(0.12, 0.42, 0.52);
uniform sampler2D noise : repeat_enable, filter_linear;
uniform sampler2D caustics : repeat_enable, filter_linear_mipmap;

varying vec2 lp;
varying vec2 wp;

void vertex() {
	lp = VERTEX;
	float h = clamp(-VERTEX.y / height, 0.0, 1.0);
	float w = sin(TIME * 0.9 + phase + VERTEX.x * 0.015) * amp * h * h
		+ sin(TIME * 2.1 + phase * 1.7 + VERTEX.y * 0.03) * amp * 0.22 * h;
	VERTEX.x += w;
	wp = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float h = clamp(-lp.y / height, 0.0, 1.0);
	vec3 c = COLOR.rgb;
	// Textura fina (poros, vetas) y algo de variación de tono.
	float n = texture(noise, lp * 0.018).r * 0.6 + texture(noise, lp * 0.06 + 0.3).g * 0.4;
	c *= 0.86 + 0.26 * n;
	// Sombra de contacto abajo y luz de la superficie arriba.
	c *= mix(0.62, 1.0, smoothstep(0.0, 0.22, h));
	c *= 1.0 + 0.16 * smoothstep(0.45, 1.0, h);
	// Cáusticas que se mueven por encima de las piezas.
	float ca = min(texture(caustics, wp * 0.004 + vec2(TIME * 0.02, TIME * 0.013), 1.2).r,
		texture(caustics, wp * 0.0055 + vec2(-TIME * 0.016, TIME * 0.019), 1.2).r);
	c += vec3(0.75, 1.0, 1.0) * ca * 0.22 * (0.4 + 0.6 * h);
	// Bruma del agua según la capa y penumbra nocturna.
	c = mix(c, fog_col, fog);
	c *= 1.0 - tint;
	COLOR.rgb = c;
}
