shader_type canvas_item;
// Стиль «Київнаукфільм»: теплий чорнильний контур замість чорного, м'яка підсвітка з верхнього лівого боку
// (як на цельових малюнках), без зміни кольорів самого персонажа. Застосовується до CanvasGroup.
uniform sampler2D group_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform vec4 ink_color : source_color = vec4(0.20, 0.10, 0.07, 1.0);
uniform float ink_width = 1.4;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.78, 1.0);
uniform float rim_strength = 0.28;
uniform float rim_width = 1.6;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec4 c = texture(group_tex, SCREEN_UV);
	// Контур лише навколо щільних частин: прозоре сяйво (a < 0.5) не обводиться
	float solid = step(0.5, c.a);
	float around = 0.0;
	const vec2 offsets[8] = vec2[](
		vec2(1.0, 0.0), vec2(0.7071, 0.7071),
		vec2(0.0, 1.0), vec2(-0.7071, 0.7071),
		vec2(-1.0, 0.0), vec2(-0.7071, -0.7071),
		vec2(0.0, -1.0), vec2(0.7071, -0.7071)
	);
	for (int i = 0; i < 8; i++) {
		around = max(around, step(0.5, texture(group_tex, SCREEN_UV + offsets[i] * ink_width * px).a));
	}
	float edge_light = c.a * (1.0 - texture(group_tex, SCREEN_UV + vec2(-0.7071, -0.7071) * rim_width * px).a);
	vec3 lit = mix(c.rgb, rim_color.rgb, rim_strength * edge_light);
	float outline_a = around * (1.0 - solid);
	COLOR = mix(vec4(lit, c.a), vec4(ink_color.rgb, 1.0), outline_a);
}
