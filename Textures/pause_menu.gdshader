shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_strength : hint_range(0.0, 10.0) = 6.0;
uniform float darken : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 col = vec4(0.0);

	float offset = blur_strength / 1000.0;

	col += texture(SCREEN_TEXTURE, uv + vec2(-offset, 0.0));
	col += texture(SCREEN_TEXTURE, uv + vec2( offset, 0.0));
	col += texture(SCREEN_TEXTURE, uv + vec2(0.0, -offset));
	col += texture(SCREEN_TEXTURE, uv + vec2(0.0,  offset));
	col += texture(SCREEN_TEXTURE, uv);

	col /= 5.0;

	// scurisce senza toccare l'alpha del menu (il menu sta sopra)
	col.rgb *= (1.0 - darken);

	COLOR = col;
}
