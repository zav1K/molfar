shader_type canvas_item;
// Hover highlight that traces the sprite's own silhouette instead of a
// bounding rectangle — for zones with real cutout art (Cauldron, Chest)
// rather than a region of flat opaque background art (most other zones
// have no alpha edge to trace at all, see hover_glow.gd for those).
// Samples the alpha a few pixels out in 8 directions from each
// transparent pixel; if any neighbor is opaque, this pixel is on the
// silhouette's outer edge and gets painted outline_color, scaled by
// `highlight` (tweened 0..1 on hover, driven by sprite_hover_outline.gd)
// so the sprite renders completely normally at rest.
//
// outline_width is in on-screen pixels, via rect_size_px (the
// TextureRect's own displayed size, set once from GDScript — see
// sprite_hover_outline.gd) — NOT the source texture's resolution. These
// sprites are ~1024px source art shown at maybe 150px on screen; a
// width measured in source texels would shrink by the same ~7x and
// disappear into sub-pixel territory once downscaled.

uniform float highlight : hint_range(0.0, 1.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(0.95, 0.85, 0.55, 1.0);
uniform float outline_width : hint_range(0.5, 10.0) = 2.5;
uniform vec2 rect_size_px = vec2(128.0, 128.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (highlight > 0.001 && tex.a < 0.1) {
		vec2 texel = outline_width / rect_size_px;
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
