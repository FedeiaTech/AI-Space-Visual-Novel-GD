shader_type canvas_item;

uniform float brightness_factor = 1.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    color.rgb *= brightness_factor;
    COLOR = color;
}