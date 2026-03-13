shader_type spatial;

uniform vec3 color1         : source_color = vec3(1.0, 1.0, 1.0);   // white tiles
uniform vec3 color2         : source_color = vec3(0.05, 0.05, 0.05); // black tiles
uniform float checker_scale : hint_range(0.01, 16.0)  = 0.10;
uniform float brick_scale   : hint_range(0.001, 1.0) = 0.025;
uniform float brick_width   : hint_range(0.1, 1.0)   = 0.250;
uniform float row_height    : hint_range(0.1, 1.0)   = 0.250;
uniform float bump_strength : hint_range(0.0, 2.0)   = 0.300;
uniform float roughness     : hint_range(0.0, 1.0)   = 0.100;

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// --- Checker ---
float checker(vec2 p, float scale) {
    vec2 q = floor(p / scale);
    return mod(q.x + q.y, 2.0);
}

// --- Brick (matches Blender's Brick Texture) ---
float brick(vec2 p, float scale, float bw, float rh) {
    vec2 uv = p / scale;
    float row = floor(uv.y / rh);
    float offset = mod(row, 2.0) * 0.5; // stagger every other row
    float col = floor((uv.x / bw) + offset);
    // mortar: thin gap between bricks
    vec2 local = vec2(
        fract((uv.x / bw) + offset),
        fract(uv.y / rh)
    );
    float mortar_size = 0.025;
    float in_mortar = step(local.x, mortar_size) + step(1.0 - mortar_size, local.x)
                    + step(local.y, mortar_size) + step(1.0 - mortar_size, local.y);
    return clamp(in_mortar, 0.0, 1.0);
}

void fragment() {
    vec2 pos2d = world_pos.xz;

    // --- Base color: checker ---
    float c = checker(pos2d, checker_scale);
    vec3 base_col = mix(color1, color2, c);

    // --- Bump: brick texture finite difference ---
    float b    = brick(pos2d,                            brick_scale, brick_width, row_height);
    float bdx  = brick(pos2d + vec2(0.001, 0.0),        brick_scale, brick_width, row_height);
    float bdy  = brick(pos2d + vec2(0.0,   0.001),      brick_scale, brick_width, row_height);
    vec3 bump_normal = normalize(vec3(
        (b - bdx) * bump_strength * 10.0,
        (b - bdy) * bump_strength * 10.0,
        1.0
    ));

    ALBEDO     = base_col;
    ROUGHNESS  = roughness;
    METALLIC   = 0.0;
    NORMAL_MAP = bump_normal;
}