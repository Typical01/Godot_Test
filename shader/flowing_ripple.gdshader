shader_type canvas_item;

uniform float wave_height_max = 10.0; 		// 波浪高度
uniform float wave_frequency = 0.05;	// 波浪密度
uniform float wave_speed = 2.0;			// 流动速度
uniform float wave_intensity = 0.5;			// 波浪强度
uniform float breath_speed = 1.5;		// 呼吸速度
uniform float breath_min = 0.3;		// 呼吸最小值

void vertex() {
	vec2 original_pos = VERTEX.xy;
	
	float breath_raw = (sin(TIME * breath_speed) + 1.0) / 2.0;
	float breath = breath_min + breath_raw * (1.0 - breath_min);
	
	float current_height = wave_height_max * breath;
	float wave = sin(original_pos.x * wave_frequency - TIME * wave_speed);
	float offset_y = wave * current_height;
	VERTEX.y += offset_y;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float wave = sin(UV.x * wave_frequency + TIME * wave_speed) * 0.5;
	float brightness = wave * wave_intensity;
	vec3 final_color = tex_color.rgb + vec3(brightness);
	COLOR = vec4(final_color, tex_color.a);
}