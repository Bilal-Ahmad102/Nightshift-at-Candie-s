shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.85;
uniform float speed : hint_range(1.0, 60.0) = 24.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.4;

float rand(vec2 co) {
    co += fract(TIME * speed) * 127.1;
    return fract(sin(dot(co, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    // use FRAGCOORD instead of UV for true per-pixel noise
    vec2 pos = floor(FRAGCOORD.xy);
    float t = floor(TIME * speed);

    float noise = rand(pos + t);

    // scanlines
    float scanline = 1.0;
    if (mod(FRAGCOORD.y, 4.0) < 2.0) {
        scanline = 1.0 - scanline_strength * 0.5;
    }

    // glitch band
    float band_y = fract(t * 0.031 + 0.5) * SCREEN_PIXEL_SIZE.y * 1000.0;
    float band_dist = abs(FRAGCOORD.y - band_y);
    if (band_dist < 8.0) {
        noise = min(1.0, noise + 0.4 * (1.0 - band_dist / 8.0));
    }

    // vignette
    vec2 centered = UV - 0.5;
    float vignette = 1.0 - smoothstep(0.3, 0.75, length(centered));

    float value = noise * intensity * scanline * vignette;
    COLOR = vec4(vec3(value), intensity);
}