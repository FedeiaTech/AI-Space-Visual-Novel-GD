shader_type canvas_item;

// --- CONFIGURACIÓN DE COLOR ---
uniform vec4 atmosphere_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform float atmo_intensity : hint_range(0.0, 5.0) = 2.0;

// --- TAMAÑO Y POSICIÓN ---
uniform float planet_radius : hint_range(0.0, 0.5) = 0.45; 
uniform float atmo_thickness : hint_range(0.0, 0.2) = 0.1;

// --- ILUMINACIÓN ---
uniform vec2 light_direction = vec2(-1.0, -1.0); 
uniform float shadow_intensity : hint_range(0.0, 1.0) = 0.0;

// --- NUEVO: ROTACIÓN ---
uniform float rotation_speed : hint_range(-1.0, 1.0) = 0.05;

// --- OPTIMIZACIÓN ---
uniform bool static_mode = false;

// --- NUEVO: ATMÓSFERA ANIMADA ---
group_uniforms Animated_Clouds;
uniform vec4 cloud_color : source_color = vec4(0.9, 0.9, 1.0, 1.0);
uniform float cloud_alpha : hint_range(0.0, 1.0) = 0.6;
uniform float cloud_thickness : hint_range(0.0, 0.3) = 0.15;
uniform float cloud_speed_1 : hint_range(-0.5, 0.5) = 0.05;
uniform float cloud_speed_2 : hint_range(-0.5, 0.5) = 0.08;
uniform float cloud_scale : hint_range(1.0, 10.0) = 4.0;
group_uniforms;

// --- FUNCIONES AUXILIARES ---
vec2 rotate_uv(vec2 uv, float angle) {
    uv -= 0.5;
    float s = sin(angle);
    float c = cos(angle);
    mat2 rot = mat2(vec2(c, -s), vec2(s, c));
    uv = rot * uv;
    uv += 0.5;
    return uv;
}

vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
    const float K1 = 0.366025404;
    const float K2 = 0.211324865;
    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    float m = step(a.y, a.x);
    vec2 o = vec2(m, 1.0 - m);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;
    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a, hash(i + 0.0)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
    return dot(n, vec3(70.0));
}

float fbm(vec2 p) {
    float f = 0.0; float w = 0.5;
    for (int i = 0; i < 4; i++) { 
        f += w * noise(p); p *= 2.0; w *= 0.5;
    }
    return f * 0.5 + 0.5;
}

void fragment() {
    // --- OPTIMIZACIÓN DE RECURSOS ---
    if (static_mode) {
        // MODO EDITOR: Mostramos la imagen original plana sin cálculos.
        // Rápido y eficiente.
        COLOR = texture(TEXTURE, UV);
        
    } else {
        // MODO JUEGO: Aplicamos 3D, rotación, luz y atmósfera.
        
        // 1. ROTACIÓN DEL PLANETA
        vec2 rotated_surface_uv = rotate_uv(UV, TIME * rotation_speed);
        vec4 tex_color = texture(TEXTURE, rotated_surface_uv);
        
        vec2 uv_centered = UV - vec2(0.5);
        float dist = length(uv_centered);
        
        // --- DESCARTE TEMPRANO ---
        if (dist > planet_radius + atmo_thickness + 0.01) {
            discard;
        }
        
        // 2. ILUMINACIÓN
        vec2 light_dir = normalize(light_direction);
        vec2 normal = normalize(uv_centered);
        float light_factor = dot(normal, -light_dir);
        float sun_mask = smoothstep(-0.5, 0.8, light_factor);

        // 3. ATMÓSFERA BASE
        float outer_glow = smoothstep(planet_radius + atmo_thickness, planet_radius, dist);
        float inner_cut = smoothstep(planet_radius, planet_radius - 0.05, dist);
        float halo = max(outer_glow - inner_cut, 0.0);
        vec4 final_halo = atmosphere_color * halo * sun_mask * atmo_intensity;
        
        float rim = 0.0;
        if (tex_color.a > 0.0) {
            float normalized_dist = dist / planet_radius;
            rim = pow(normalized_dist, 4.0) * sun_mask;
        }
        vec3 rim_color = atmosphere_color.rgb * rim * atmo_intensity;

        // 4. NUBES
        float cloud_region = smoothstep(planet_radius + cloud_thickness + 0.05, planet_radius + cloud_thickness, dist);
        cloud_region *= smoothstep(planet_radius - 0.05, planet_radius, dist);

        vec2 cloud_uv1 = rotate_uv(UV, TIME * cloud_speed_1);
        float noise1 = fbm(cloud_uv1 * cloud_scale);
        vec2 cloud_uv2 = rotate_uv(UV, TIME * cloud_speed_2 * -1.2);
        float noise2 = fbm(cloud_uv2 * cloud_scale * 1.5 + vec2(5.2, 1.3));
        
        float final_cloud_pattern = mix(noise1, noise2, 0.5);
        final_cloud_pattern = smoothstep(0.3, 0.7, final_cloud_pattern);

        vec4 final_clouds = cloud_color * final_cloud_pattern * cloud_region * sun_mask * cloud_alpha;

        // 5. COMPOSICIÓN
        vec3 final_rgb = tex_color.rgb;
        if (tex_color.a > 0.0) {
            float shadow = smoothstep(0.2, -0.5, light_factor);
            final_rgb = mix(final_rgb, final_rgb * (1.0 - shadow_intensity), shadow);
        }
        final_rgb += rim_color;
        
        vec4 final_composition = vec4(final_rgb, tex_color.a);
        final_composition.rgb = mix(final_composition.rgb, final_clouds.rgb, final_clouds.a);
        final_composition.a = max(final_composition.a, final_clouds.a);
        final_composition.rgb = mix(final_composition.rgb, final_halo.rgb, final_halo.a);
        final_composition.a = max(final_composition.a, final_halo.a);

        COLOR = final_composition;
    }
}