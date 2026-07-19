shader_type canvas_item;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * vec2(2.2, 5.0);
	p.y -= TIME * 3.0;
	p.x += sin(uv.y * 8.0 + TIME * 2.0) * 0.15;
	float n = fbm(p);
	float mask = smoothstep(0.02, 0.25, uv.x) * smoothstep(0.98, 0.75, uv.x);
	float rise = smoothstep(1.0, 0.05, uv.y);
	float flame = clamp(n - uv.y * 0.55, 0.0, 1.0) * mask * rise;
	vec3 col = mix(vec3(0.55, 0.05, 0.0), vec3(1.0, 0.55, 0.05), clamp(flame * 1.6, 0.0, 1.0));
	col = mix(col, vec3(1.0, 0.95, 0.55), pow(flame, 3.5));
	COLOR = vec4(col, flame);
}
