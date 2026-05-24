shader_type canvas_item;

// =============================================================================
// Bloody red flash shader
//
// Drives off two uniforms:
//   - intensity  : 0..1, master strength (tween this from 0 -> 1 -> 0)
//   - time_offset: seconds, animate this for the drip/grain motion
// =============================================================================

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time_offset = 0.0;

// Colors
uniform vec4 blood_color  : source_color = vec4(0.30, 0.0,  0.0,  1.0);  // dark blood for splats/drips
uniform vec4 bright_red   : source_color = vec4(1.0,  0.10, 0.05, 1.0);  // center red
uniform vec4 dark_edge    : source_color = vec4(0.18, 0.0,  0.0,  1.0);  // vignette corners

// Vignette: red is stronger toward the edges than the center.
uniform float vignette_strength : hint_range(0.0, 2.0)  = 1.2;
uniform float vignette_softness : hint_range(0.05, 1.5) = 0.6;

// Blood splatter spots (a handful of round blobs scattered around).
uniform float splatter_amount : hint_range(0.0, 2.0) = 1.2;
uniform int   splatter_count  : hint_range(0, 20)    = 12;
uniform float splatter_min_radius : hint_range(0.01, 0.3) = 0.06;
uniform float splatter_max_radius : hint_range(0.02, 0.4) = 0.18;

// Drips at the top of the screen.
// drip_progress is independent of time_offset so the drips are visible
// the moment the flash starts — tween it 0..1 over the show duration.
uniform float drip_amount   : hint_range(0.0, 2.0) = 1.0;
uniform float drip_progress : hint_range(0.0, 1.0) = 0.0;
uniform int   drip_count    : hint_range(1, 30)    = 14;

// Grain.
uniform float grain_strength : hint_range(0.0, 0.5) = 0.10;


// --- Hash / noise ------------------------------------------------------------
float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}


// --- Splatter ----------------------------------------------------------------
// Field of soft circular blood blobs. Each blob has a hard core and a soft halo
// so they read as real splats, not just opacity falloffs.
float splatter(vec2 uv) {
	float total = 0.0;

	for (int i = 0; i < 20; i++) {
		if (i >= splatter_count) break;
		float fi = float(i);
		vec2 seed = vec2(fi * 13.37, fi * 7.89);
		vec2 pos  = vec2(hash(seed), hash(seed + 11.1));
		float r   = mix(splatter_min_radius, splatter_max_radius, hash(seed + 3.3));

		// Distort the sample point so the blob edge is irregular, not a smooth disc.
		vec2 wobble = vec2(
			noise(uv * 18.0 + fi * 4.7) - 0.5,
			noise(uv * 18.0 + fi * 9.1) - 0.5
		) * 0.04;

		float d = distance(uv + wobble, pos);

		// Hard core + soft halo combined.
		float core = smoothstep(r * 0.55, r * 0.25, d);
		float halo = smoothstep(r * 1.10, r * 0.50, d) * 0.6;
		total = max(total, max(core, halo));

		// Small satellite droplets near each blob.
		vec2 sat_pos = pos + vec2(hash(seed + 21.1) - 0.5, hash(seed + 31.1) - 0.5) * 0.08;
		float sat_r  = r * 0.25;
		float sat    = smoothstep(sat_r, sat_r * 0.3, distance(uv, sat_pos));
		total = max(total, sat * 0.85);
	}

	return clamp(total, 0.0, 1.0);
}


// --- Drips -------------------------------------------------------------------
// Vertical streaks falling from the top of the screen. They grow downward as
// drip_progress advances from 0 -> 1.
float drips(vec2 uv) {
	float total = 0.0;

	for (int i = 0; i < 30; i++) {
		if (i >= drip_count) break;
		float fi = float(i);

		// Column x position and per-column random params.
		float col_x   = hash(vec2(fi, 1.0));
		float width   = mix(0.006, 0.020, hash(vec2(fi, 2.0)));
		float length_ = mix(0.20, 0.65, hash(vec2(fi, 3.0)));
		float delay   = hash(vec2(fi, 4.0)) * 0.5;

		// How far has this drip travelled?
		float progress = clamp(drip_progress - delay, 0.0, 1.0);
		float reach    = length_ * progress;

		if (reach <= 0.0) continue;

		// Horizontal mask: thicker near the top, narrowing toward the tip.
		float dx     = abs(uv.x - col_x);
		float taper  = 1.0 - smoothstep(0.0, reach, uv.y);
		float w      = width * (0.4 + taper * 0.6);
		float horiz  = smoothstep(w, 0.0, dx);

		// Vertical mask: present from y=0 down to y=reach, with a soft tip.
		float vert = step(0.0, uv.y) * smoothstep(reach, reach - 0.05, uv.y);

		// Rounded droplet head at the tip.
		float tip_d = distance(vec2(uv.x, uv.y), vec2(col_x, reach));
		float tip   = smoothstep(width * 1.8, width * 0.6, tip_d);

		total = max(total, max(horiz * vert, tip));
	}

	return clamp(total, 0.0, 1.0);
}


// --- Main --------------------------------------------------------------------
void fragment() {
	vec2 uv = UV;

	// Vignette mask — strongest at corners, weakest at center.
	float dist_from_center = distance(uv, vec2(0.5));
	float vignette = smoothstep(0.2, 0.2 + vignette_softness, dist_from_center) * vignette_strength;
	vignette = clamp(vignette, 0.0, 1.0);

	// Build the splatter & drip masks.
	float splat = splatter(uv) * splatter_amount;
	float drip  = drips(uv)    * drip_amount;
	float blood_mask = clamp(max(splat, drip), 0.0, 1.0);

	// Base layered red: vignette gradient between bright red and dark edge.
	vec3 col = mix(bright_red.rgb, dark_edge.rgb, vignette);

	// Stamp blood color over the base wherever blobs/drips sit. Using mix with
	// a strong factor so blobs actually look like darker stains on red.
	col = mix(col, blood_color.rgb, blood_mask * 0.9);

	// Subtle moving grain.
	float grain = noise(uv * 600.0 + time_offset * 50.0) - 0.5;
	col += grain * grain_strength;

	// Alpha: full coverage where there's vignette OR blood, see-through-er in
	// the bright center between blobs.
	float base_alpha = mix(0.55, 1.0, vignette);
	float alpha = max(base_alpha, blood_mask);
	alpha *= intensity;

	COLOR = vec4(col, alpha);
}