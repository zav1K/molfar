shader_type canvas_item;
// Swirling cauldron liquid: a circular mask over a warped, animated noise
// field. Rotation speed/direction and the light/dark tint follow the
// player's stirring (see stir_cauldron.gd) — idles gently on its own too.

uniform float swirl_amount : hint_range(0.0, 4.0) = 0.4;
uniform float direction : hint_range(-1.0, 1.0) = 0.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 base_color : source_color = vec4(0.35, 0.4, 0.22, 1.0);
uniform vec4 light_color : source_color = vec4(0.85, 0.7, 0.3, 1.0);
uniform vec4 dark_color : source_color = vec4(0.25, 0.05, 0.3, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered) * 2.0;
	if (dist > 1.0) {
		discard;
	}

	float angle = atan(centered.y, centered.x);
	float dir_sign = direction >= 0.0 ? 1.0 : -1.0;
	float swirl = swirl_amount * (1.0 - dist) * 3.0;
	float t = TIME * (0.25 + swirl_amount * 0.35) * dir_sign;
	float warped_angle = angle + swirl + t;
	vec2 warped = vec2(cos(warped_angle), sin(warped_angle)) * dist;

	float n = value_noise(warped * 4.0 + vec2(TIME * 0.15, -TIME * 0.1));
	n += 0.5 * value_noise(warped * 8.0 - vec2(TIME * 0.2, TIME * 0.05));
	n /= 1.5;

	vec4 tint = mix(base_color, direction >= 0.0 ? light_color : dark_color, progress);
	vec3 col = tint.rgb * (0.75 + 0.5 * n);
	col *= mix(0.85, 1.05, 1.0 - smoothstep(0.0, 1.0, dist));

	COLOR = vec4(col, 1.0);
}
