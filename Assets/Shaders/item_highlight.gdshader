shader_type canvas_item;

uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform float line_width : hint_range(0.0, 0.2) = 0.15;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float pause_duration : hint_range(0.0, 2.0) = 0.15;
uniform float offset = 2.0;
uniform int pixelate_line : hint_range(0, 1) = 1;

void fragment() {
    vec4 base_texture = texture(TEXTURE, UV);
    
    // Ignorar píxeles transparentes (para que el brillo no pinte el cuadrado vacío)
    if (base_texture.a < 0.01) {
        discard;
    }
    
    // Cálculo del tiempo y pausa
    float cycle_duration = offset + pause_duration;
    float adjusted_time = mod(TIME * speed, cycle_duration);
    
    // Movimiento de derecha a izquierda
    float line_position;
    if (adjusted_time <= offset) {
        line_position = offset - adjusted_time;
    } else {
        line_position = -0.3;
    }
    
    vec2 uv_for_line = UV;
    
    // Pixelación (Importante si tus iconos son pixel art)
    if (pixelate_line == 1) {
        vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
        uv_for_line = floor(UV * texture_size) / texture_size;
    }
    
    // Rotación diagonal
    vec2 rotated_uv = vec2(uv_for_line.x + uv_for_line.y, uv_for_line.y - uv_for_line.x) * 0.5;
    float dist = abs(rotated_uv.x - line_position);
    
    float line_intensity = smoothstep(line_width, 0.0, dist);
    
    // Mezcla final
    vec3 final_color = mix(base_texture.rgb, line_color.rgb, line_intensity * line_color.a);
    
    COLOR = vec4(final_color, base_texture.a);
}