// RADIOLARIA_PLATE — Kunstformen der Natur, Plate 61: Stephoidea
// Ernst Haeckel, 1904
// Multi-specimen plate arrangement | 4 specimens | 6/8/12/16-fold symmetry gradient
// Amber/cobalt/earth | wheat paper | formal plate border
//
// Biology: Stephoidea are nassellarian radiolarians whose silicate skeletons form
// bilateral or conical shapes rather than the fully radial Acantharia forms.
// Haeckel arranged multiple specimens per plate at varied scales to show
// structural diversity. This shader arranges 4 specimens in formal quadrant
// layout, each with different fold symmetry — illustrating the evolutionary
// relationship between lower and higher radial orders.
//
// Mathematics: Each specimen occupies a quadrant. Within each quadrant,
// a complete radiolarian is drawn with its own fold count and lattice complexity.
// Plate is framed with a double-line border, inner and outer rules.
// Roman numeral labels are approximated with simple geometric marks.

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;
uniform float u_line_weight_primary;
uniform float u_line_weight_secondary;
uniform float u_wash_opacity;
uniform float u_stipple_density;
uniform float u_radial_symmetry;
uniform float u_wet_edge_intensity;
uniform float u_paper_warmth;

#define PI  3.14159265358979
#define TAU 6.28318530717959

vec3 C_PAPER  = vec3(0.961, 0.871, 0.702);
vec3 C_AMBER  = vec3(0.855, 0.647, 0.125);
vec3 C_INK    = vec3(0.545, 0.271, 0.075);
vec3 C_COBALT = vec3(0.255, 0.412, 0.882);
vec3 C_GREEN  = vec3(0.133, 0.545, 0.133);
vec3 C_DARK   = vec3(0.10,  0.07,  0.04);

float hash21(vec2 p) {
    p = fract(p * vec2(127.34, 311.7));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float sdCircle(vec2 p, float r) { return length(p) - r; }

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p-a, ba = b-a;
    return length(pa - ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0));
}

vec2 radialFold(vec2 uv, float n) {
    float a = atan(uv.y, uv.x);
    float r = length(uv);
    float s = TAU / n;
    float fa = mod(a, s);
    if (fa > s * 0.5) fa = s - fa;
    return vec2(cos(fa), sin(fa)) * r;
}

float stipple(vec2 p, float density, float darkness) {
    vec2 cell = floor(p * density);
    float ox = hash21(cell + vec2(0.1, 0.2)) - 0.5;
    float oy = hash21(cell + vec2(0.3, 0.7)) - 0.5;
    vec2 center = (cell + 0.5 + vec2(ox, oy) * 0.4) / density;
    float dist = length(p - center);
    float dot_r = darkness * 0.3 / density;
    return smoothstep(dot_r, dot_r * 0.5, dist);
}

// Draw a single radiolarian specimen
// Returns (ink, amber, cobalt) as .xyz, shadow as .w
vec4 specimen(vec2 p, float fold, float complexity) {
    float r = length(p);
    float ink = 0.0;
    float amber = 0.0;
    float cobalt = 0.0;

    float outer_r = 0.85;
    vec2 sym = radialFold(p, fold);

    // Central sphere
    float core = sdCircle(p, 0.16);
    amber += smoothstep(0.0, -0.01, core);
    ink   += smoothstep(0.012, 0.0, abs(core)) * u_line_weight_primary;
    // Stipple on core
    if (core < 0.0) ink += stipple(p * 4.0, u_stipple_density * 0.3, 0.5) * 0.5;

    // Lattice spheres
    float m1 = sdCircle(p, 0.32);
    ink += smoothstep(0.008, 0.0, abs(m1)) * u_line_weight_secondary * 0.8;
    float m2 = sdCircle(p, 0.55);
    ink += smoothstep(0.007, 0.0, abs(m2)) * u_line_weight_secondary * 0.65;

    // Primary spines
    float sw = 0.008 * u_line_weight_primary;
    float pspine = sdSegment(sym, vec2(0.16, 0.0), vec2(0.85, 0.0));
    ink   += smoothstep(sw, 0.0, pspine) * u_line_weight_primary;
    amber += smoothstep(sw*3.0, 0.0, pspine) * 0.5;

    // Spine tip bulb (different per specimen)
    float bulb = sdCircle(sym - vec2(0.85, 0.0), 0.025 + complexity * 0.01);
    ink   += smoothstep(0.005, 0.0, abs(bulb)) * u_line_weight_primary;
    amber += smoothstep(0.03, 0.0, abs(bulb) - 0.01) * 0.7;

    // Secondary spines
    vec2 sym2 = radialFold(p, fold * 2.0);
    float ss = sdSegment(sym2, vec2(0.32, 0.0), vec2(0.7, 0.0));
    float ssw = 0.005 * u_line_weight_secondary;
    ink += smoothstep(ssw, 0.0, ss) * u_line_weight_secondary * 0.8;

    // Struts
    vec2 sym4 = radialFold(p, fold * 2.0);
    float strut = sdSegment(sym4, vec2(0.17, 0.0), vec2(0.31, 0.0));
    ink += smoothstep(0.004, 0.0, strut) * u_line_weight_secondary * 0.5;

    // Wash inside outer lattice
    float lmask = step(m2, 0.0);
    cobalt = lmask * u_wash_opacity * 0.22;
    amber += lmask * u_wash_opacity * 0.12;

    // If high complexity: additional details
    if (complexity > 1.5) {
        // Tertiary spines
        vec2 sym3 = radialFold(p, fold * 3.0);
        float ts = sdSegment(sym3, vec2(0.56, 0.0), vec2(0.75, 0.0));
        ink += smoothstep(0.003, 0.0, ts) * u_line_weight_secondary * 0.5;
    }

    // Shadow
    float shadow = smoothstep(0.0, 0.2, sdCircle(p - vec2(0.07, -0.05), outer_r * 0.75)) * 0.065;

    return vec4(ink, amber, cobalt, shadow);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    vec3 paper = mix(vec3(1.0), C_PAPER, u_paper_warmth);

    // Paper grain
    float grain = (hash21(gl_FragCoord.xy * 0.8) - 0.5) * 0.012;
    paper += grain;

    // Aspect-correct bounds
    float aspect = u_resolution.x / u_resolution.y;

    // --- Plate border ---
    float border_ink = 0.0;
    // Outer rule
    float obx = max(abs(uv.x) - 0.88, abs(uv.y) - 0.90);
    border_ink += smoothstep(0.008, 0.0, abs(obx)) * u_line_weight_primary;
    // Inner rule (double border)
    float ibx = max(abs(uv.x) - 0.82, abs(uv.y) - 0.84);
    border_ink += smoothstep(0.006, 0.0, abs(ibx)) * u_line_weight_secondary * 0.8;

    // --- Dividing cross lines ---
    float cross_v = abs(uv.x) * step(abs(uv.y), 0.84);
    float cross_h = abs(uv.y) * step(abs(uv.x), 0.88);
    border_ink += smoothstep(0.004, 0.0, cross_v - 0.002) * 0.3;
    border_ink += smoothstep(0.004, 0.0, cross_h - 0.002) * 0.3;

    // --- Four specimens in quadrants ---
    // Specimen positions and fold counts
    vec2 quad_centers[4];
    quad_centers[0] = vec2(-0.43,  0.43);  // top-left    — 6-fold
    quad_centers[1] = vec2( 0.43,  0.43);  // top-right   — 8-fold
    quad_centers[2] = vec2(-0.43, -0.43);  // bottom-left — 12-fold
    quad_centers[3] = vec2( 0.43, -0.43);  // bottom-right — 16-fold

    float folds[4];
    folds[0] = max(4.0, floor(u_radial_symmetry) - 4.0);
    folds[0] = max(4.0, folds[0]);
    folds[1] = max(4.0, floor(u_radial_symmetry) - 2.0);
    folds[2] = max(4.0, floor(u_radial_symmetry));
    folds[3] = max(4.0, floor(u_radial_symmetry) + 2.0);
    // Clamp to reasonable range
    for (int i = 0; i < 4; i++) folds[i] = clamp(folds[i], 4.0, 24.0);

    float complexities[4];
    complexities[0] = 1.0; complexities[1] = 1.5;
    complexities[2] = 2.0; complexities[3] = 2.5;

    float scale = 0.36;

    vec3 col = paper;

    for (int qi = 0; qi < 4; qi++) {
        vec2 qp = (uv - quad_centers[qi]) / scale;
        vec4 sp = specimen(qp, folds[qi], complexities[qi]);

        float s_ink    = sp.x;
        float s_amber  = sp.y;
        float s_cobalt = sp.z;
        float s_shadow = sp.w;

        col = mix(col, C_INK * 0.7, s_shadow);
        col = mix(col, C_COBALT, s_cobalt);
        col = mix(col, C_AMBER, s_amber * 0.65);
        col = mix(col, C_INK, clamp(s_ink, 0.0, 1.0));

        // Small numeral mark below each specimen (horizontal rule = plate number suggestion)
        float num_y = quad_centers[qi].y - 0.35;
        float num_d = smoothstep(0.003, 0.0, abs(uv.y - num_y)) * step(abs(uv.x - quad_centers[qi].x), 0.08);
        col = mix(col, C_INK * 0.55, num_d * 0.6);
    }

    // Plate border on top
    col = mix(col, C_DARK, clamp(border_ink, 0.0, 1.0));

    // Vignette (warm, like aged paper)
    float vig = smoothstep(1.15, 0.5, length(uv));
    col = mix(col * 0.88, col, vig);

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
