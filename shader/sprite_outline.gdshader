shader_type canvas_item;

uniform float outline_width = 1.0;
uniform vec4 outline_color: source_color = vec4(0, 0, 0, 1);

void fragment() {
	vec2 uv = UV;
	
	vec2 uv_up = uv + vec2(0, TEXTURE_PIXEL_SIZE.y * outline_width);
	vec4 color_up = texture(TEXTURE, uv_up);
	vec2 uv_down = uv + vec2(0, -TEXTURE_PIXEL_SIZE.y * outline_width);
	vec4 color_down = texture(TEXTURE, uv_down);
	vec2 uv_rigth = uv + vec2(TEXTURE_PIXEL_SIZE.x * outline_width, 0);
	vec4 color_rigth = texture(TEXTURE, uv_rigth);
	vec2 uv_left = uv + vec2(-TEXTURE_PIXEL_SIZE.x * outline_width, 0);
	vec4 color_left = texture(TEXTURE, uv_left);
	
	vec4 outline = color_up + color_down + color_rigth + color_left;
	outline.rgb = outline_color.rgb;
	outline.a = min(outline.a, 0.5);
	vec4 original_color = texture(TEXTURE, UV);
	COLOR = mix(outline, original_color, original_color.a);
}
