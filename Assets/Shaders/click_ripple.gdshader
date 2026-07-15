shader_type canvas_item;

uniform float time : hint_range(0.0, 1.0) = 0.0; // Progreso de la animación (0 a 1)
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 0.5);

void fragment() {
    // Centramos las coordenadas UV (0.5, 0.5 es el centro)
    vec2 centered_uv = UV - vec2(0.5);
    float dist = length(centered_uv);

    // Radio del anillo (crece con el tiempo)
    // Multiplicamos por 0.5 porque el UV va de 0 a 1, así que el radio máximo es 0.5
    float radius = 0.5 * time;

    // Grosor del anillo (se hace más fino al final)
    float thickness = 0.1 * (1.0 - time);

    // Creamos el anillo usando smoothstep para bordes suaves
    float ring = smoothstep(radius - thickness, radius, dist) * smoothstep(radius + thickness, radius, dist);

    // Desvanecimiento general (Alpha baja mientras crece)
    float fade = 1.0 - time;

    COLOR = vec4(color.rgb, ring * fade * color.a);
}