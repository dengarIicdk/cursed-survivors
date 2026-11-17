// Screen-space atmosphere: drifting fog, vignette and a damage flash.
shader_type canvas_item;

uniform float fog_amount = 0.18;
uniform vec4 fog_color : source_color = vec4(0.42, 0.28, 0.55, 1.0);
uniform vec4 tint : source_color = vec4(0.10, 0.06, 0.16, 1.0);
uniform float vignette_strength = 0.55;
uniform float vignette_radius = 0.95;
uniform float damage = 0.0;
uniform float pulse = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p *= 2.07;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float aspect = 1.7778;
	vec2 c = uv - 0.5;
	c.x *= aspect;

	// Drifting fog banks.
	vec2 flow = vec2(TIME * 0.010, TIME * 0.004);
	float f = fbm(uv * vec2(4.2, 3.0) + flow);
	f = smoothstep(0.42, 0.88, f);
	float f2 = fbm(uv * vec2(2.1, 1.6) - flow * 0.6 + 13.0);
	f2 = smoothstep(0.50, 0.95, f2);
	float fog = (f * 0.6 + f2 * 0.6) * fog_amount;

	// Vignette.
	float vig = smoothstep(vignette_radius, vignette_radius + 0.62, length(c) * 1.15);
	vig = clamp(vig * vignette_strength, 0.0, 0.95);

	vec3 fog_rgb = fog_color.rgb;
	vec3 col = mix(vec3(0.0), fog_rgb, fog);
	float alpha = clamp(fog * 0.75 + vig, 0.0, 1.0);

	// Damage flash around the edges.
	float edge = smoothstep(vignette_radius - 0.1, vignette_radius + 0.5, length(c) * 1.15);
	vec3 dmg = vec3(0.72, 0.05, 0.12);
	col = mix(col, dmg, damage * edge * 0.85);
	alpha = max(alpha, damage * edge * 0.8);

	// Heartbeat pulse brightens the vignette.
	alpha *= 1.0 + pulse * 0.25;

	COLOR = vec4(col, alpha);
}