// Procedural graveyard ground. No textures: the whole floor is painted by
// warped noise + voronoi so it never tiles visibly and stays crisp at any zoom.
shader_type canvas_item;

uniform vec2 world_size = vec2(9200.0, 9200.0);
uniform vec3 c_dirt : source_color = vec3(0.215, 0.155, 0.180);
uniform vec3 c_moss : source_color = vec3(0.215, 0.280, 0.180);
uniform vec3 c_moss_lt : source_color = vec3(0.330, 0.410, 0.245);
uniform vec3 c_stone : source_color = vec3(0.430, 0.400, 0.470);
uniform vec3 c_stone_dk : source_color = vec3(0.170, 0.145, 0.205);
uniform vec3 c_blood : source_color = vec3(0.290, 0.075, 0.115);
uniform vec3 c_bone : source_color = vec3(0.620, 0.570, 0.470);
uniform vec3 c_ember : source_color = vec3(0.720, 0.230, 0.130);
uniform vec3 c_grass : source_color = vec3(0.330, 0.390, 0.220);
uniform float cell = 42.0;
uniform float grout = 0.085;
uniform float gain : hint_range(0.5, 2.5) = 1.34;

const mat2 ROT = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + vec2(37.7, 91.3)));
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
		p = ROT * p * 2.03 + vec2(11.3, 7.7);
		a *= 0.5;
	}
	return v;
}

// (distance to nearest cell edge, per-cell brightness variation)
vec2 cobbles(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	float best = 8.0;
	float second = 8.0;
	vec2 best_g = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash2(n + g) * 0.8 + 0.1;
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < best) {
				second = best;
				best = d;
				best_g = n + g;
			} else if (d < second) {
				second = d;
			}
		}
	}
	return vec2(sqrt(second) - sqrt(best), hash(best_g));
}

void fragment() {
	vec2 world = UV * world_size;
	vec2 warp = vec2(fbm(world * 0.0035), fbm(world * 0.0035 + 9.2)) - 0.5;

	// Where paving lies, where moss and bare earth take over. The warp and the
	// wide smoothstep keep the borders organic instead of rectangular.
	float layout = fbm(world * 0.0028 + warp * 1.2);
	// Ragged the border with a higher-frequency term, otherwise the mask reads
	// as big translucent polygons instead of organic ground.
	layout += (fbm(world * 0.017) - 0.5) * 0.14;
	float paving = smoothstep(0.46, 0.62, layout);
	float earth = smoothstep(0.46, 0.26, layout);

	float grain = fbm(world * 0.065 + warp * 0.6);
	float speck = vnoise(world * 0.55);

	// Paving stones.
	vec2 cob = cobbles(world / cell + warp * 0.08);
	float edge = smoothstep(0.015, grout, cob.x);
	vec3 stone = mix(c_stone_dk, c_stone, 0.72 + cob.y * 0.28);
	stone *= 0.95 + grain * 0.12;
	// Each stone gets a lit bevel and its own speckle, otherwise the cells read
	// as flat translucent polygons instead of masonry.
	stone *= 0.68 + edge * 0.52;
	stone *= 0.92 + fbm(world * 0.19 + cob.y * 23.0) * 0.20;
	stone = mix(stone, c_stone_dk * 0.55, (1.0 - edge) * 0.85);
	// Puddles / worn hollows in the slabs.
	stone *= 0.90 + smoothstep(0.35, 0.65, fbm(world * 0.02 + 3.0)) * 0.18;

	// Mossy earth.
	vec3 moss = mix(c_moss, c_moss_lt, grain);
	moss = mix(moss, c_dirt, smoothstep(0.58, 0.86, fbm(world * 0.014 + 5.0)) * 0.65);
	moss *= 0.97 + speck * 0.08;

	// Dead grass tufts: short strands, only on the soft ground.
	float strands = vnoise(vec2(world.x * 0.5, world.y * 0.08));
	moss = mix(moss, c_grass, smoothstep(0.64, 0.82, strands) * (1.0 - paving) * 0.22);

	vec3 col = mix(moss, stone, paving);
	col = mix(col, c_dirt, earth * 0.10);

	// Wet blood pools.
	float blood = fbm(world * 0.0068 + vec2(21.0, 4.0));
	col = mix(col, c_blood, smoothstep(0.72, 0.92, blood) * 0.30);

	// Scattered bones, pebbles and embers.
	float bone = vnoise(world * 1.1);
	col = mix(col, c_bone, step(0.986, bone) * 0.40);
	float ember_dot = vnoise(world * 0.85 + 31.0);
	col = mix(col, c_ember, step(0.992, ember_dot) * 0.35);

	// Hairline cracks over the paving.
	float crack = abs(fbm(world * 0.035) - 0.5);
	col = mix(col, c_stone_dk * 0.60, smoothstep(0.014, 0.0, crack) * paving * 0.32);

	// Very gentle darkening toward the far edges keeps focus on the player.
	float d = length(world) * 0.00016;
	col *= 1.0 - clamp(d, 0.0, 1.0) * 0.12;
	col *= gain;

	COLOR = vec4(col, 1.0);
}