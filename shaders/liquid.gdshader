shader_type canvas_item;
// Swirling cauldron liquid, drawn to fill whatever rect it's given (an
// ellipse rect looking into the pot at a slight angle, not straight-on
// — see stir_cauldron.gd). A soft antialiased rim, a dark falloff toward
// the edge and a highlight blob sell it as a concave surface with some
// depth rather than a flat painted disc; rotation speed/direction and
// the light/dark tint follow the player's stirring — idles gently on
// its own too.

uniform float swirl_amount : hint_range(0.0, 4.0) = 0.4;
uniform float direction : hint_range(-1.0, 1.0) = 0.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 base_color : source_color = vec4(0.35, 0.4, 0.22, 1.0);
uniform vec4 light_color : source_color = vec4(0.85, 0.7, 0.3, 1.0);
uniform vec4 dark_color : source_color = vec4(0.25, 0.05, 0.3, 1.0);
uniform float surface_alpha : hint_range(0.0, 1.0) = 0.88;

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
	if (dist > 1.08) {
		discard;
	}
	float edge_alpha = 1.0 - smoothstep(0.9, 1.05, dist);

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
	vec3 col = tint.rgb * (0.7 + 0.5 * n);

	// Concave-bowl shading: darker toward the rim, soft highlight offset
	// toward one side like light catching the surface.
	col *= mix(0.62, 1.0, 1.0 - smoothstep(0.0, 1.0, dist));
	float highlight = smoothstep(0.4, 0.0, length(centered - vec2(-0.16, -0.22)));
	col += highlight * 0.22;

	COLOR = vec4(col, surface_alpha * edge_alpha);
}
