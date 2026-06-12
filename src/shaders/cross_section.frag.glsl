// CROSS_SECTION_PLATE — Citrus sinensis (Navel Orange) and Rosa canina (Dog Rose Hip)
// Botanical Plate — Flore des serres et des jardins de l'Europe, 1845–1880
// Cross-section and longitudinal section | internal structure | clean white ground | heavy linework
//
// Biology: The orange fruit cross-section reveals the hesperidium structure:
// flavedo (outer rind), albedo (white pith), and juice vesicles packed in
// 10–12 segments separated by radial membranes. The rose hip shows
// achene seeds embedded in hypanthium tissue with prominent hairs.
//
// Mathematics: Orange segments use radial SDF tiling with n-fold symmetry.
// Each segment is a circular sector with rounded tip. The juice vesicles
// within each segment use a hexagonal packing. The cross-section cut face
// uses clean white ground — maximum linework weight, minimum wash.

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

// Clean scientific plate palette
vec3 C_PAPER   = vec3(1.000, 0.999, 0.990); // near white
vec3 C_ORANGE  = vec3(1.000, 0.647, 0.000); // orange flesh
vec3 C_RIND    = vec3(1.000, 0.800, 0.200); // flavedo yellow-orange
vec3 C_PITH    = vec3(0.980, 0.950, 0.870); // albedo white
vec3 C_SEED    = vec3(0.850, 0.780, 0.600); // seed / achene
vec3 C_INK     = vec3(0.06,  0.04,  0.03);  // near-black ink
vec3 C_VESICLE = vec3(1.000, 0.500, 0.050); // juice vesicle

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

vec2 rot2(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c*v.x - s*v.y, s*v.x + c*v.y);
}

vec2 radialFold(vec2 uv, float n) {
    float a = atan(uv.y, uv.x);
    float r = length(uv);
    float s = TAU / n;
    float fa = mod(a, s);
    if (fa > s * 0.5) fa = s - fa;
    return vec2(cos(fa), sin(fa)) * r;
}

// Hexagonal packing: distance to nearest hex center
float hexDist(vec2 p) {
    vec2 a = mod(p, vec2(1.0, 1.732)) - vec2(0.5, 0.866);
    vec2 b = mod(p - vec2(0.5, 0.866), vec2(1.0, 1.732)) - vec2(0.5, 0.866);
    return min(length(a), length(b));
}

// ---- LEFT SPECIMEN: Orange cross-section ----
vec3 drawOrange(vec2 p) {
    float n_seg = max(8.0, floor(u_radial_symmetry));

    float r = length(p);
    float ink = 0.0;
    float orange_f = 0.0;
    float pith_f = 0.0;
    float rind_f = 0.0;
    float vesicle_f = 0.0;
    float seed_f = 0.0;

    // Outer boundary
    float outer = sdCircle(p, 0.40);
    float inside = step(outer, 0.0);

    // --- Flavedo (outer rind) 0.37–0.40 ---
    float rind_inner = sdCircle(p, 0.365);
    float in_rind = step(outer, 0.0) * step(0.0, rind_inner);
    rind_f = in_rind;

    // Outer outline
    ink += smoothstep(0.009, 0.0, abs(outer)) * u_line_weight_primary;

    // Rind-flesh boundary
    ink += smoothstep(0.007, 0.0, abs(rind_inner)) * inside * u_line_weight_secondary;

    // --- Albedo (pith) 0.31–0.37 ---
    float pith_inner = sdCircle(p, 0.31);
    float in_pith = step(rind_inner, 0.0) * step(0.0, pith_inner);
    pith_f = in_pith;
    ink += smoothstep(0.006, 0.0, abs(pith_inner)) * inside * u_line_weight_secondary * 0.8;

    // --- Radial membranes (segment walls) ---
    vec2 seg_sym = radialFold(p, n_seg);
    float membrane_w = 0.006 * u_line_weight_primary;
    float membrane = abs(seg_sym.y);
    float in_flesh = step(pith_inner, 0.0); // inside pith inner circle = flesh zone
    ink += smoothstep(membrane_w, 0.0, membrane) * in_flesh * u_line_weight_primary * 0.9;

    // --- Juice vesicles in each segment ---
    // Vesicles are elongated cells packed radially within each segment
    // Use hex dist mapped in segment space
    float vesicle_scale = u_stipple_density * 1.2;
    float vhex = hexDist(seg_sym * vesicle_scale * vec2(1.0, 2.0));
    float vesicle_r = 0.25 / vesicle_scale;
    vesicle_f = smoothstep(vesicle_r, vesicle_r * 0.3, vhex) * in_flesh
              * smoothstep(membrane_w * 2.0, membrane_w * 5.0, membrane);
    ink += smoothstep(vesicle_r * 1.1, vesicle_r * 0.9, vhex) * in_flesh
         * smoothstep(membrane_w * 2.0, membrane_w * 5.0, membrane) * u_line_weight_secondary * 0.4;

    // Orange flesh color (non-vesicle cells)
    orange_f = in_flesh * (1.0 - vesicle_f);

    // --- Seeds (2 per segment, near center) ---
    for (int i = 0; i < 16; i++) {
        if (float(i) >= n_seg) break;
        float sa = TAU * (float(i) + 0.5) / n_seg;
        vec2 seed_center = vec2(cos(sa), sin(sa)) * 0.18;
        vec2 sv = rot2(p - seed_center, sa + PI * 0.5);
        float sd = length(sv / vec2(0.018, 0.028)) - 1.0;
        seed_f += smoothstep(0.0, -0.003, sd);
        ink    += smoothstep(0.004, 0.0, abs(sd)) * in_flesh * u_line_weight_secondary * 0.9;
    }

    // Central column (axile placenta)
    float col_r = sdCircle(p, 0.04);
    pith_f += smoothstep(0.0, -0.005, col_r) * 0.7;
    ink += smoothstep(0.006, 0.0, abs(col_r)) * u_line_weight_secondary * 0.7;

    // Cast shadow
    float shadow = smoothstep(0.0, 0.18, sdCircle(p - vec2(0.03, -0.03), 0.40)) * 0.06;

    vec3 col = vec3(0.0);

    // Accumulate colors
    col += C_PAPER     * (1.0 - inside);                         // white outside
    col += C_RIND      * rind_f * u_wash_opacity;
    col += C_PITH      * pith_f * 0.4 * u_wash_opacity;         // pith is pale
    col += C_ORANGE    * orange_f * u_wash_opacity * 0.8;
    col += C_VESICLE   * vesicle_f * u_wash_opacity;
    col += C_SEED      * seed_f * u_wash_opacity;

    // Make sure background is white where not covered
    col = mix(C_PAPER, col, inside);

    // Shadow on background
    col = mix(col, col * 0.93, shadow * (1.0 - inside));

    // Ink
    col = mix(col, C_INK, clamp(ink, 0.0, 1.0));

    return col;
}

// ---- RIGHT SPECIMEN: Rose hip longitudinal section ----
vec3 drawRoseHip(vec2 p) {
    float ink = 0.0;
    float outer_f = 0.0;  // hypanthium flesh
    float seed_f  = 0.0;
    float hair_f  = 0.0;

    // Outer hip — oval (urceolate)
    float outer = length(p / vec2(0.22, 0.30)) - 1.0;
    float inside = step(outer, 0.0);

    // Neck constriction at top
    float neck = length((p - vec2(0.0, 0.30)) / vec2(0.07, 0.05)) - 1.0;
    float in_neck = step(neck, 0.0);

    // Outer outline
    ink += smoothstep(0.009, 0.0, abs(outer)) * u_line_weight_primary;
    ink += smoothstep(0.007, 0.0, abs(neck)) * u_line_weight_secondary;

    // Flesh (hypanthium wall)
    float inner_cavity = length(p / vec2(0.14, 0.20)) - 1.0;
    float flesh = inside * step(0.0, inner_cavity); // between outer and cavity
    outer_f = flesh;
    ink += smoothstep(0.007, 0.0, abs(inner_cavity)) * inside * u_line_weight_secondary * 0.8;

    // Achene seeds arranged around inner cavity wall
    for (int i = 0; i < 8; i++) {
        float sa = TAU * float(i) / 8.0 - PI * 0.5;
        float sr = 0.13;
        vec2 sc = vec2(cos(sa) * sr * 0.75, sin(sa) * sr);
        vec2 sv = rot2(p - sc, sa);
        float sd = length(sv / vec2(0.025, 0.038)) - 1.0;
        seed_f += smoothstep(0.0, -0.003, sd);
        ink    += smoothstep(0.004, 0.0, abs(sd)) * inside * u_line_weight_secondary * 0.9;
        // Seed hairs (styles)
        float hair_d = abs(sv.x) - 0.003;
        ink += smoothstep(0.002, 0.0, hair_d) * smoothstep(-0.038, -0.055, sv.y)
             * inside * u_line_weight_secondary * 0.5;
    }

    // Interior hairs on cavity wall (silky)
    {
        float angle = atan(p.y, p.x);
        float hair_t = mod(angle * 8.0 / PI, 1.0);
        float hair_layer = smoothstep(0.01, 0.0, abs(inner_cavity + 0.05))
                         * smoothstep(0.5, 0.0, hair_t) * inside;
        ink += hair_layer * u_line_weight_secondary * 0.35;
    }

    // Transverse hatching on flesh for texture
    float hatch = abs(mod((p.x + p.y) * 12.0, 1.0) - 0.5);
    ink += smoothstep(0.12, 0.0, hatch) * flesh * u_line_weight_secondary * 0.15;

    // Sepal remnants at neck
    for (int i = 0; i < 5; i++) {
        float sa = TAU * float(i) / 5.0;
        vec2 sep_p = rot2(p - vec2(0.0, 0.30), -sa);
        float sd = max(sep_p.x, abs(sep_p.y) - (0.035 - sep_p.x * 0.4));
        ink += smoothstep(0.004, 0.0, abs(sd + 0.02)) * u_line_weight_secondary * 0.7;
    }

    float shadow = smoothstep(0.0, 0.15, length(p / vec2(0.26, 0.34) - vec2(0.05, -0.04)) - 1.0) * 0.05;

    vec3 col = C_PAPER;
    col = mix(col, C_RIND,  outer_f * u_wash_opacity * 0.8);
    col = mix(col, C_SEED,  seed_f  * u_wash_opacity);
    col = mix(col, col * 0.93, shadow * (1.0 - inside));
    col = mix(col, C_INK, clamp(ink, 0.0, 1.0));

    return col;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    vec3 paper = mix(vec3(1.0), C_PAPER, u_paper_warmth * 0.3); // very clean ground

    // --- Two specimens side by side ---
    vec2 left_uv  = uv - vec2(-0.48, 0.0);
    vec2 right_uv = uv - vec2( 0.44, 0.0);

    float scale = 1.0;
    left_uv  *= scale;
    right_uv *= scale;

    vec3 left_col  = drawOrange(left_uv);
    vec3 right_col = drawRoseHip(right_uv);

    // Blend with paper based on distance to each specimen center
    float left_mask  = step(sdCircle(left_uv, 0.50), 0.2);
    float right_mask = step(length(right_uv / vec2(0.30, 0.40)) - 1.2, 0.0);

    vec3 col = paper;
    // Simple composite — closer specimen wins; both are on same white ground
    col = mix(col, left_col, clamp(left_mask, 0.0, 1.0));
    col = mix(col, right_col, clamp(right_mask, 0.0, 1.0));

    // Dividing line between plates (thin vertical rule)
    float div = smoothstep(0.003, 0.0, abs(uv.x)) * smoothstep(0.8, 0.0, abs(uv.y));
    col = mix(col, C_INK * 0.4, div * 0.3);

    // Paper grain — less prominent on clean scientific ground
    col += (hash21(gl_FragCoord.xy * 1.1) - 0.5) * 0.007;

    // Frame border rule
    float border = max(abs(uv.x) - 0.92, abs(uv.y) - 0.88);
    col = mix(col, C_INK * 0.5, smoothstep(0.008, 0.0, abs(border)) * 0.5);

    // Very subtle vignette
    col = mix(col * 0.96, col, smoothstep(1.0, 0.5, length(uv * vec2(0.9, 1.0))));

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
