shader_type canvas_item;

// Controla qué tan agresivo es el oscurecimiento del borde.
// Juega con este valor entre 0.5 y 2.0 en el inspector.
uniform float edge_darkening : hint_range(0.0, 3.0) = 1.2;

void fragment() {
    vec4 current_color = texture(TEXTURE, UV);

    // Si el pixel tiene transparencia (es un borde)...
    if (current_color.a > 0.0 && current_color.a < 0.95) {
        // Multiplicamos el color por su propio canal alfa elevado a una potencia.
        // Esto oscurece los bordes semi-transparentes, eliminando el halo blanco.
        current_color.rgb *= pow(current_color.a, edge_darkening);
    }

    COLOR = current_color;
}