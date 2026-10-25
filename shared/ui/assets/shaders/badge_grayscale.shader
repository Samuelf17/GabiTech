shader_type canvas_item;

uniform float grayscale_amount = 0.0;

void fragment() {
	vec4 source_color = texture(TEXTURE, UV) * COLOR;
	float luminance = dot(source_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grayscale_color = vec3(luminance);
	COLOR = vec4(mix(source_color.rgb, grayscale_color, grayscale_amount), source_color.a);
}
