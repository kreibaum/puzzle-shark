shader_type canvas_item;

void fragment() {
	// Place fragment code here.
	vec4 color = texture(TEXTURE, UV);
	if (COLOR.a == 0.0) {
		COLOR = vec4(0.4, 0.6, 0.9, 0.1);
	}
	else {
		COLOR = color;
	}
}
