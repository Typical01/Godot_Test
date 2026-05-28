shader_type canvas_item;

uniform float frequency = 20.0;
uniform float intansity = 1.2;
uniform float speed = 2.0;
uniform float outer_breath_speed = 2.0;
uniform float inner_breath_speed = 10.0;
uniform vec3 color1: source_color = vec3(0.0, 0.75, 0.0);
uniform vec3 color2: source_color = vec3(0.75, 0.75, 0.75);

float fbm(float x) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency_value = frequency;
	for (int i = 0; i < 4; i++) {
		value += amplitude * sin(x * frequency_value);
		amplitude *= 0.5;
		frequency_value *= 2.1;
	}
	return value;
}

float irregular_wave(float x, float t) {
	float w1 = sin(x * 12.0 - t * 3.2);
	float w2 = sin(x * 31.0 - t * 1.7) * 0.5;
	float w3 = sin(x * 57.0 - t * 2.4) * 0.3;
	return (w1 + w2 + w3) / 1.8;
}

void vertex() {
}

void fragment() {
	// 外层呼吸
	float outer_breath = (sin(TIME * outer_breath_speed) + 1.0) / 2.0;
	outer_breath = 0.4 + outer_breath * 0.6;
	
	float phase = UV.x * 15.0 - TIME * speed;
	float wave = fbm(phase);
	wave += sin(phase * 3.0) * 0.2;
	
	// 内层呼吸
	float bar_index = floor(UV.x * 30.0);
	float inner_phase = TIME * inner_breath_speed + bar_index * 1.2;
	float inner_breath = (sin(inner_phase) + 1.0) / 2.0;
	inner_breath = 0.6 + inner_breath * 0.5;
	
	float total_breath = outer_breath * inner_breath;
	float final_wave = wave * intansity * total_breath;
	
	float centered_y = UV.y * 2.0 - 1.0;
	float bar = step(abs(centered_y), abs(final_wave));
	
	vec3 color = mix(color2, color1, abs(final_wave));
	color *= (0.7 + outer_breath * 0.5);
	COLOR = vec4(color * bar, bar);
}



