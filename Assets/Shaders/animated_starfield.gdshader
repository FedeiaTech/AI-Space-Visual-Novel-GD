shader_type canvas_item;

// --- COLORES Y FONDO ---
uniform vec3 background_color : source_color = vec3(0.0, 0.0, 0.02);
uniform vec3 nebula_color1 : source_color = vec3(0.2, 0.05, 0.3); // Púrpura
uniform vec3 nebula_color2 : source_color = vec3(0.0, 0.3, 0.4); // Cian/Verdoso
uniform float nebula_density : hint_range(0.0, 2.0) = 0.5;
uniform float nebula_speed : hint_range(0.0, 0.5) = 0.02;

// --- ESTRELLAS ---
uniform float aspect_ratio = 1.0;
uniform float star_density : hint_range(0.0, 3.0, 0.0001) = 1.3;
uniform int layer_parascale : hint_range(0, 5, 1) = 4;
uniform vec2 star_speed = vec2(0.01, 0.01);
uniform float star_size : hint_range(0.0, 100.0, 0.01) = 3.0;
uniform float twinkle_effect : hint_range(0.0, 1.0, 0.01) = 0.6;
uniform float twinkle_speed : hint_range(0.0, 100.0, 0.01) = 0.3;

uniform bool static_mode = false; // Si es true, apaga los efectos

// --- AGUJERO NEGRO ---
group_uniforms Black_Hole;
uniform bool black_hole_enabled = true;
uniform vec2 bh_center = vec2(0.5, 0.5);
uniform float bh_radius : hint_range(0.0, 0.5) = 0.15;
uniform float lensing_strength : hint_range(0.0, 1.0) = 0.5; // Aumentado para notar el efecto
uniform vec4 accretion_disk_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float disk_width : hint_range(0.0, 0.2) = 0.04;
group_uniforms;

// --- FUNCIONES DE RUIDO (Para las Nebulosas) ---
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
    float f = 0.0;
    float w = 0.5;
    for (int i = 0; i < 3; i++) { // 3 capas de ruido
        f += w * noise(p);
        p *= 2.0;
        w *= 0.5;
    }
	return f * 0.5 + 0.5;
}

// --- FUNCIONES DE ESTRELLAS ---
float one_div_x2(float x) { x = (abs(x) < 0.0001) ? 1.0 : (1.0/x); return x * x; }
float get_beta_w(float x, float f, float size) { return size * x * PI / f; }
float get_beta_h(float y, float f, float size) { return size * y * PI / f; }
float get_i(vec2 uv, float f, vec2 SIZE) { return one_div_x2(get_beta_w(uv.x, f, SIZE.x)) * one_div_x2(get_beta_h(uv.y, f, SIZE.y)); }
float random(vec2 st) { return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43759.5453123); }
vec2 get_snowflake_world_center(vec2 grid_id, vec2 time_offset, vec2 snow_offset, float layer_scale) { return (grid_id + snow_offset + time_offset) / layer_scale; }

// ==============================================
// MAIN
// ==============================================
void fragment() {
    // --- OPTIMIZACIÓN DE RECURSOS ---
    if (static_mode) {
        // MODO EDITOR: Solo pintamos el color de fondo.
        // Barato y rápido.
        COLOR = vec4(background_color, 1.0);
        
    } else {
        // MODO JUEGO: Ejecutamos toda la magia matemática.
        
        vec2 st = UV;
        st.x *= aspect_ratio;
        
        vec2 bh_pos = bh_center;
        bh_pos.x *= aspect_ratio;
        
        // --- 1. DISTORSIÓN GRAVITACIONAL ---
        float dist_to_bh = distance(st, bh_pos);
        float angle_to_bh = atan(st.y - bh_pos.y, st.x - bh_pos.x);
        
        vec2 distorted_st = st;
        
        if (black_hole_enabled) {
            float distortion = lensing_strength * 0.15 / (dist_to_bh + 0.05);
            distorted_st -= vec2(cos(angle_to_bh), sin(angle_to_bh)) * distortion;
        }

        // --- 2. FONDO + NEBULOSAS ---
        vec3 color = background_color;
        
        vec2 nebula_uv = distorted_st * 2.0 + vec2(TIME * nebula_speed * 0.5, TIME * nebula_speed);
        float n = fbm(nebula_uv); 
        float n2 = fbm(distorted_st * 4.0 - vec2(TIME * nebula_speed));
        
        float nebula_mask = smoothstep(0.2, 0.8, n + n2 * 0.5);
        vec3 cloud_color = mix(nebula_color1, nebula_color2, n2);
        color = mix(color, cloud_color, nebula_mask * nebula_density);

        // --- 3. ESTRELLAS ---
        vec2 cuv = (distorted_st - 0.5) * 2.0;
        
        for (int layer = 0; layer < layer_parascale; layer++) {
            float layer_scale = exp(float(layer + 1) * star_density);
            vec2 layer_speed = vec2(star_speed.x, star_speed.y) * (1.0 + float(layer) * 0.3);
            float layer_size = star_size * (1.0 - float(layer) * 0.2);

            vec2 layer_st = distorted_st * layer_scale;
            vec2 cuv_st = cuv;

            vec2 time_offset = TIME * layer_speed;
            layer_st -= time_offset;

            vec2 grid_st = fract(layer_st);
            vec2 grid_id = floor(layer_st);

            float rand_seed = random(grid_id);
            vec2 snow_pos = vec2(0.5 + 0.3 * sin(rand_seed * 6.28), 0.5 + 0.2 * cos(rand_seed * 12.56));
            
            vec2 diff = (grid_st - snow_pos); 
            float dist = length(diff);
            
            float snow_size = layer_size * 0.01 * (0.3 + 0.7 * rand_seed);
            float layer_brightness = 1.0 / (1.0 + float(layer) * 0.5);
            float star_intrinsic_brightness = 0.2 + 0.8 * rand_seed; 

            float core = exp((-dist * dist) / (snow_size * snow_size));
            
            float spikes = 0.0;
            if (rand_seed > 0.6) {
                float spike_width = snow_size * 0.3;
                float spike_len = snow_size * 5.0;
                float h_spike = exp(-abs(diff.y) / spike_width) * exp(-abs(diff.x) / spike_len);
                float v_spike = exp(-abs(diff.x) / spike_width) * exp(-abs(diff.y) / spike_len);
                spikes = (h_spike + v_spike) * 0.5;
            }

            float twinkle = (1.0 - twinkle_effect) + twinkle_effect * (sin(rand_seed * 100.0 + TIME * twinkle_speed) * cos(rand_seed * 120.0 + TIME * (twinkle_speed + 2.0)));
            
            float total_star_light = (core + spikes) * twinkle;

            vec3 color_tint = vec3(random(grid_id - 3.0), random(grid_id + 7.0), random(grid_id + 5.0));
            color_tint = mix(color_tint, vec3(1.0), 0.5);
            
            float lensing_glow = 1.0 + (1.0 / (dist_to_bh * 10.0 + 0.1)) * lensing_strength;

            color = max(color + (total_star_light * layer_brightness * star_intrinsic_brightness * lensing_glow) * color_tint, color);
        }

        // --- 4. DISCO DE ACRECIÓN ---
        if (black_hole_enabled) {
            float disk_range = smoothstep(bh_radius, bh_radius + disk_width, dist_to_bh);
            float disk_fade = smoothstep(bh_radius + disk_width + 0.15, bh_radius, dist_to_bh);
            
            float noise_rot = fbm(vec2(cos(angle_to_bh), sin(angle_to_bh)) * 4.0 + TIME * 1.5);
            
            vec3 disk_glow = accretion_disk_color.rgb * (1.0 - disk_range) * disk_fade * (noise_rot * 0.5 + 0.8) * 2.5;
            color += disk_glow;

            if (dist_to_bh < bh_radius) {
                color = vec3(0.0);
            }
        }

        COLOR = vec4(color, 1.0);
    }
}