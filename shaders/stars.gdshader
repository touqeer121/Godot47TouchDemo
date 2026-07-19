shader_type canvas_item;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV * vec2(48.0, 27.0);
	vec2 cell = floor(uv);
	vec2 f = fract(uv) - 0.5;
	float h = hash(cell);
	float star = 0.0;
	if (h > 0.986) {
		float d = length(f);
		float size = mix(0.08, 0.22, hash(cell + 3.7));
		star = smoothstep(size, 0.0, d);
		float speed = mix(1.0, 3.0, hash(cell + 7.1));
		float twinkle = 0.4 + 0.6 * sin(TIME * speed + h * 60.0);
		star *= twinkle;
	}
	vec3 col = vec3(1.0, 0.98, 0.9) * star;
	COLOR = vec4(col, star);
}
