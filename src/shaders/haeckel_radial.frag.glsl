// HAECKEL_RADIAL — Acantharia hexastyla
// Ernst Haeckel, Kunstformen der Natur, 1904
// Plate arrangement of radiolaria specimens
// 12-fold radial symmetry | stipple texture | amber skeleton | cobalt accents
//
// Biology: Radiolaria are single-celled marine organisms whose silicate
// skeletons form perfect geometric lattices. Haeckel drew them as though
// they were architecture — and in a sense they are. The skeleton is the
// organism's only lasting trace.
//
// Mathematics: 12-fold radial symmetry achieved by folding atan2 angle
// into a single 30° sector, then mirroring. Spines are SDF line segments.
// Stipple uses a Poisson-disk-approximating hash grid.

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;
uniform float u_line_weight_primary;    // primary outline (1.5–2.5)
uniform float u_line_weight_secondary;  // secondary detail (0.5–1.2)
uniform float u_wash_opacity;           // internal wash (0.0–1.0)
uniform float u_stipple_density;        // stipple dots per unit (20–120)
uniform float u_radial_symmetry;        // fold count (6/8/12/16)
uniform float u_wet_edge_intensity;     // unused in this regime
uniform float u_paper_warmth;           // cream tint (0.0–1.0)

#define PI  3.14159265358979
#define TAU 6.28318530717959

// --- Palette ---
// HAECKEL_PLATE: wheat paper, amber skeleton, brown ink, cobalt, botanical green
vec3 C_PAPER  = vec3(0.961, 0.871, 0.702); // #F5DEB3 wheat
vec3 C_AMBER  = vec3(0.855, 0.647, 0.125); // #DAA520 amber skeleton
vec3 C_INK    = vec3(0.545, 0.271, 0.075); // #8B4513 brown ink
vec3 C_COBALT = vec3(0.255, 0.412, 0.882); // #4169E1 cobalt
vec3 C_GREEN  = vec3(0.133, 0.545, 0.133); // #228B22 botanical green

// --- Utility ---
float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

float hash11(float p) { return fract(sin(p * 127.1) * 43758.5); }

// Signed distance to a line segment
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// SDF circle
float sdCircle(vec2 p, float r) { return length(p) - r; }

// Apply n-fold radial symmetry to UV (returns folded coordinate)
vec2 radialFold(vec2 uv, float n) {
    float angle = atan(uv.y, uv.x);
    float r = length(uv);
    float sector = TAU / n;
    float a = mod(angle, sector);
    if (a > sector * 0.5) a = sector - a;
    return vec2(cos(a), sin(a)) * r;
}

// Stipple texture: returns 0 or 1 per "ink dot"
float stipple(vec2 p, float density, float darkness) {
    vec2 cell = floor(p * density);
    float offset_x = hash21(cell + vec2(0.1, 0.2)) - 0.5;
    float offset_y = hash21(cell + vec2(0.3, 0.7)) - 0.5;
    vec2 center = (cell + 0.5 + vec2(offset_x, offset_y) * 0.4) / density;
    float dist = length(p - center);
    float dot_r = darkness * 0.3 / density;
    return smoothstep(dot_r, dot_r * 0.5, dist);
}

// Cross-hatch pattern (two sets of lines at 45°)
float crosshatch(vec2 p, float spacing, float weight) {
    float a = mod(p.x + p.y, spacing);
    float b = mod(p.x - p.y, spacing);
    float la = smoothstep(weight, 0.0, min(a, spacing - a));
    float lb = smoothstep(weight, 0.0, min(b, spacing - b));
    return clamp(la + lb, 0.0, 1.0);
}

// Draw a single radiolarian specimen at center, radius scale s
vec4 radiolarian(vec2 uv, float s, float fold) {
    // Normalize to specimen space
    uv /= s;

    float r = length(uv);
    float darkness = 0.0;
    float ink = 0.0;
    float amber_val = 0.0;
    float cobalt_val = 0.0;

    // --- Outer silhouette boundary for shadow ---
    float outer_r = 1.05;

    // --- Apply radial symmetry ---
    vec2 sym = radialFold(uv, fold);
    float sym_a = atan(sym.y, sym.x); // angle within sector [0, PI/fold]

    // --- Central sphere ---
    float core_r = 0.18;
    float core = sdCircle(uv, core_r);

    // Core fill — amber
    amber_val += smoothstep(0.0, -0.01 * s, core);

    // Core outline — ink
    ink += smoothstep(0.012, 0.0, abs(core)) * u_line_weight_primary * 0.8;

    // Core inner stipple texture
    if (core < 0.0) {
        float sp = stipple(uv * 4.0, u_stipple_density * 0.3, 0.6);
        ink += sp * 0.5;
    }

    // --- Inner lattice sphere (at 0.32 r) ---
    float mid_r = 0.32;
    float mid = sdCircle(uv, mid_r);
    ink += smoothstep(0.01, 0.0, abs(mid)) * u_line_weight_secondary * 0.7;

    // --- Outer lattice sphere (at 0.55 r) ---
    float lat_r = 0.55;
    float lat = sdCircle(uv, lat_r);
    ink += smoothstep(0.008, 0.0, abs(lat)) * u_line_weight_secondary * 0.6;

    // --- Primary spines: extend from core to tip at r=1.0 ---
    // In symmetric space, primary spine goes along X axis
    float spine_w = 0.008 * u_line_weight_primary;
    float spine_len = 1.0;
    float primary_spine = sdSegment(sym, vec2(0.18, 0.0), vec2(spine_len, 0.0));
    ink += smoothstep(spine_w, 0.0, primary_spine) * u_line_weight_primary;
    amber_val += smoothstep(spine_w * 3.0, 0.0, primary_spine) * 0.6;

    // Spine tip — small barb
    float barb = sdCircle(sym - vec2(spine_len, 0.0), 0.025);
    ink += smoothstep(0.005, 0.0, abs(barb)) * u_line_weight_primary;
    amber_val += smoothstep(0.03, 0.0, abs(barb) - 0.01) * 0.8;

    // --- Secondary spines at half-sector angle ---
    // Apply fold/2 symmetry for secondaries within each sector
    float sector = TAU / fold;
    float angle = atan(uv.y, uv.x);
    float ha = mod(angle + sector * 0.5, sector) - sector * 0.5;
    // secondary is at half-angle
    float sec_fold = fold * 2.0;
    vec2 sec_sym = radialFold(uv, sec_fold);
    float sec_spine = sdSegment(sec_sym, vec2(0.32, 0.0), vec2(0.7, 0.0));
    float sec_w = 0.005 * u_line_weight_secondary;
    ink += smoothstep(sec_w, 0.0, sec_spine) * u_line_weight_secondary * 0.8;

    // --- Radial struts between inner and mid lattice ---
    vec2 strut_sym = radialFold(uv, fold * 2.0);
    float strut = sdSegment(strut_sym, vec2(0.19, 0.0), vec2(0.31, 0.0));
    float strut_w = 0.004 * u_line_weight_secondary;
    ink += smoothstep(strut_w, 0.0, strut) * u_line_weight_secondary * 0.6;

    // --- Wash inside outer lattice ---
    float wash_mask = smoothstep(0.02, -0.02, lat) * u_wash_opacity;
    cobalt_val = wash_mask * 0.25;
    amber_val += wash_mask * 0.15;

    // --- Inner cross-hatch shadow on core ---
    if (core < 0.0) {
        float ch = crosshatch(uv * 6.0, 0.1, 0.012);
        ink += ch * 0.3 * smoothstep(0.0, -0.05, core);
    }

    // --- Stipple on mid zone ---
    float mid_zone = smoothstep(0.02, 0.0, abs(r - (core_r + mid_r) * 0.5));
    if (r > core_r && r < mid_r) {
        ink += stipple(uv * 3.0, u_stipple_density * 0.5, 0.4) * 0.3;
    }

    // --- Soft cast shadow ---
    vec2 shadow_uv = uv - vec2(0.08, -0.06);
    float shadow = smoothstep(0.0, 0.2, sdCircle(shadow_uv, outer_r * 0.8));
    float shadow_alpha = (1.0 - shadow) * 0.07;

    // Mask everything outside specimen outer boundary
    float mask = smoothstep(0.01, -0.01, sdCircle(uv, outer_r));

    return vec4(ink, amber_val, cobalt_val, shadow_alpha) * mask;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    // Warm paper background
    vec3 paper = mix(vec3(1.0), C_PAPER, u_paper_warmth);

    // Slight paper grain
    float grain = (hash21(gl_FragCoord.xy * 0.8) - 0.5) * 0.012;
    paper += grain;

    // Three-specimen plate arrangement:
    //  • Large central specimen (12-fold)
    //  • Two flanking specimens (8-fold, smaller)
    float fold_main = max(3.0, floor(u_radial_symmetry));

    vec2 pos_a = vec2(0.0, 0.0);   // center
    vec2 pos_b = vec2(-0.7, 0.0);  // left flank
    vec2 pos_c = vec2( 0.7, 0.0);  // right flank

    vec4 spA = radiolarian(uv - pos_a, 0.38, fold_main);
    vec4 spB = radiolarian(uv - pos_b, 0.22, max(3.0, fold_main - 4.0));
    vec4 spC = radiolarian(uv - pos_c, 0.22, 8.0);

    // Compose: shadow first, then color
    vec3 col = paper;

    // Apply shadows
    col = mix(col, C_INK, spA.w + spB.w + spC.w);

    // Helper: composite one specimen onto col
    // For each specimen: amber fill, cobalt wash, ink lines
    for (int i = 0; i < 3; i++) {
        vec4 sp = (i == 0) ? spA : (i == 1) ? spB : spC;
        float ink_v = sp.x;
        float amb_v = sp.y;
        float cob_v = sp.z;

        // Cobalt wash
        col = mix(col, mix(col, C_COBALT, 0.4), cob_v);
        // Amber skeleton fill
        col = mix(col, C_AMBER, amb_v * 0.65);
        // Ink linework on top
        col = mix(col, C_INK, clamp(ink_v, 0.0, 1.0));
    }

    // Subtle vignette
    float vig = smoothstep(1.1, 0.5, length(uv));
    col = mix(col * 0.92, col, vig);

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
