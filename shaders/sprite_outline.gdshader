shader_type canvas_item;
// Hover highlight that traces the sprite's own silhouette instead of a
// bounding rectangle — for zones with real cutout art (Cauldron, Chest)
// rather than a region of flat opaque background art (most other zones
// have no alpha edge to trace at all, see hover_glow.gd for those).
// Samples the alpha a few texels out in 8 directions from each
// transparent pixel; if any neighbor is opaque, this pixel is on the
// silhouette's outer edge and gets painted outline_color, scaled by
// `highlight` (tweened 0..1 on hover, driven by sprite_hover_outline.gd)
// so the sprite renders completely normally at rest.

uniform float highlight : hint_range(0.0, 1.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(0.95, 0.85, 0.55, 1.0);
uniform float outline_width : hint_range(0.5, 6.0) = 2.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (highlight > 0.001 && tex.a < 0.1) {
		vec2 texel = outline_width / vec2(textureSize(TEXTURE, 0));
		float neighbor_alpha = 0.0;
		neighbor_alpha += texture(TEXTURE, UV + vec2(texel.x, 0.0)).a;
		neighbor_alpha += texture(TEXTURE, UV - vec2(texel.x, 0.0)).a;
		neighbor_alpha += texture(TEXTURE, UV + vec2(0.0, texel.y)).a;
		neighbor_alpha += texture(TEXTURE, UV - vec2(0.0, texel.y)).a;
		neighbor_alpha += texture(TEXTURE, UV + vec2(texel.x, texel.y)).a;
		neighbor_alpha += texture(TEXTURE, UV - vec2(texel.x, texel.y)).a;
		neighbor_alpha += texture(TEXTURE, UV + vec2(texel.x, -texel.y)).a;
		neighbor_alpha += texture(TEXTURE, UV + vec2(-texel.x, texel.y)).a;
		if (neighbor_alpha > 0.0) {
			COLOR = vec4(outline_color.rgb, outline_color.a * highlight);
			return;
		}
	}
	COLOR = tex;
}
