shader_type spatial;

// --- Tuning ---
uniform vec3 fabric_color : source_color = vec3(0.6, 0.15, 0.1);
uniform float voronoi_scale : hint_range(0.1, 10.0) = 0.4;
uniform float noise1_scale  : hint_range(0.1, 10.0) = 0.2;
uniform float noise1_detail : hint_range(1.0, 8.0)  = 4.5;
uniform float noise2_scale  : hint_range(0.1, 10.0) = 0.4;
uniform float noise2_detail : hint_range(1.0, 8.0)  = 4.2;
uniform float roughness_min : hint_range(0.0, 1.0)  = 0.5;
uniform float roughness_max : hint_range(0.0, 1.0)  = 0.85;
uniform float bump_strength : hint_range(0.0, 2.0)  = 0.4;

varying vec3 world_pos;

// --- Hash helpers ---
float hash(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

// --- Smooth Voronoi F2-F1 (no dark center dots) ---
float voronoi(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    float min_dist = 8.0;
    float second_dist = 8.0;
    for (int z = -1; z <= 1; z++) {
        for (int y = -1; y <= 1; y++) {
            for (int x = -1; x <= 1; x++) {
                vec3 neighbor = vec3(float(x), float(y), float(z));
                vec3 cell = vec3(
                    hash(i + neighbor + vec3(0.0)),
                    hash(i + neighbor + vec3(1.0)),
                    hash(i + neighbor + vec3(2.0))
                );
                vec3 diff = neighbor + cell - f;
                float d = dot(diff, diff);
                if (d < min_dist) {
                    second_dist = min_dist;
                    min_dist = d;
                } else if (d < second_dist) {
                    second_dist = d;
                }
            }
        }
    }
    // F2-F1: ridges at cell edges, bright centers — no dots
    return sqrt(second_dist) - sqrt(min_dist);
}

// --- FBM Noise ---
float noise3(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float fbm(vec3 p, float detail) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    int octaves = int(detail);
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise3(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec3 pos = world_pos;

    // --- Base color: Voronoi fabric weave (no dots) ---
    float v = voronoi(pos * voronoi_scale);
    float ramp1 = smoothstep(0.0, 0.6, v);
    vec3 base_col = mix(fabric_color * 0.75, fabric_color, ramp1);

    // --- Roughness: Noise #1 ---
    float n1 = fbm(pos * noise1_scale, noise1_detail);
    float rough = mix(roughness_min, roughness_max, smoothstep(0.0, 0.43, n1));

    // --- Bump: Noise #2 ---
    float n2   = fbm(pos * noise2_scale, noise2_detail);
    float n2dx = fbm(pos * noise2_scale + vec3(0.01, 0.0, 0.0), noise2_detail);
    float n2dy = fbm(pos * noise2_scale + vec3(0.0, 0.01, 0.0), noise2_detail);
    vec3 bump_normal = normalize(vec3(
        (n2 - n2dx) * bump_strength * 10.0,
        (n2 - n2dy) * bump_strength * 10.0,
        1.0
    ));

    ALBEDO    = base_col;
    ROUGHNESS = rough;
    METALLIC  = 0.0;
    NORMAL_MAP = bump_normal;
}