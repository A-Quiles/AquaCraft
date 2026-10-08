shader_type canvas_item;
// Plantas que ondulan con la corriente. Mueve los vértices según su altura (la base no se mueve).

uniform float height = 200.0;
uniform float amp = 9.0;
uniform float phase = 0.0;
uniform float tint = 0.0;            // oscurece plantas al fondo / de noche

void vertex() {
	float h = clamp(-VERTEX.y / height, 0.0, 1.0);
	float w = sin(TIME * 0.9 + phase + VERTEX.x * 0.015) * amp * h * h
		+ sin(TIME * 2.1 + phase * 1.7 + VERTEX.y * 0.03) * amp * 0.22 * h;
	VERTEX.x += w;
}

void fragment() {
	COLOR.rgb *= 1.0 - tint;
}
