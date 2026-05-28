shader_type canvas_item;

uniform vec4 border_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float border_width_pixels = 1.0;
uniform float expand_pixels = 1.0;
uniform vec2 rect_size = vec2(64, 64);

void vertex() {
	vec2 expand_offset = vec2(float(expand_pixels)) / rect_size;
	vec2 normalized_pos = VERTEX.xy / rect_size - 0.5;
	vec2 direction = sign(normalized_pos);
	vec2 new_pos = VERTEX.xy + expand_offset * rect_size * direction;
	VERTEX.xy = new_pos;
}

void fragment() {
	float left = UV.x;
	float right = 1.0 - UV.x;
	float top = UV.y;
	float bottom = 1.0 - UV.y;
	
	float border_uv_h = border_width_pixels * dFdx(UV.x);
	float border_uv_v = border_width_pixels * dFdy(UV.y);
	
	float is_border_h = step(min(left, right), border_uv_h);
	float is_border_v = step(min(top, bottom), border_uv_v);
	//float min_edge = min(min(left, right), min(top, bottom));
	//
	//float pixel_width = length(vec2(dFdx(UV.x), dFdy(UV.y)));
	//float uv_border_width = border_width_pixels * pixel_width;
	//
	//float is_border = step(min_edge, uv_border_width);
	float is_border = max(is_border_h, is_border_v);
	COLOR = mix(vec4(0.0), border_color, is_border);
}
