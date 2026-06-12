// HAECKEL_JELLYFISH — Medusa aurita (Moon Jellyfish)
// Ernst Haeckel, Report on the Scientific Results of the Voyage of H.M.S. Challenger, 1882
// 8-fold bell symmetry | trailing tentacles | cobalt/amber/translucent wash
//
// Biology: Medusozoa exhibit tetramerous (4-fold) or octamerous (8-fold) radial
// symmetry. The bell margin is divided into lappets; the subumbrella shows
// radial canals connecting the stomach to the ring canal. Haeckel elevated
// these anatomical features into ornamental geometry.
//
// Mathematics: Bell shape is a cardioid-modified circle. Tentacle motion
// uses sin/cos curves parameterized by arc length. Translucency is simulated
// by layered alpha-blended washes rather than true transmission.

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

vec3 C_PAPER  = vec3(0.961, 0.871, 0.702); // #F5DEB3
vec3 C_AMBER  = vec3(0.855, 0.647, 0.125); // #DAA520
vec3 C_INK    = vec3(0.545, 0.271, 0.075); // #8B4513
vec3 C_COBALT = vec3(0.255, 0.412, 0.882); // #4169E1
vec3 C_TEAL   = vec3(0.0,   0.502, 0.502); // teal accent

float hash21(vec2 p) {
    p = fract(p * vec2(127.34, 311.7));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    return length(pa - ba * clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0));
}

float sdCircle(vec2 p, float r) { return length(p) - r; }

vec2 radialFold(vec2 uv, float n) {
    float a = atan(uv.y, uv.x);
    float r = length(uv);
    float s = TAU / n;
    float fa = mod(a, s);
    if (fa > s * 0.5) fa = s - fa;
    return vec2(cos(fa), sin(fa)) * r;
}

// Bell outline SDF — flattened dome with scalloped margin
float sdBell(vec2 p, float fold) {
    float r = length(p);
    float a = atan(p.y, p.x);
    // Bell shape: radius varies with angle (scalloped margin)
    float n = fold;
    float scallop = 0.04 * cos(a * n);
    float bell_r = 0.45 + scallop - 0.18 * max(0.0, p.y / max(r, 0.001));
    return r - bell_r;
}

// Radial canal — line from stomach to ring canal
float radialCanal(vec2 uv, float fold) {
    vec2 sym = radialFold(uv, fold);
    // Canal goes inward from ring canal (r=0.36) toward center (r=0.08)
    return sdSegment(sym, vec2(0.08, 0.0), vec2(0.36, 0.0));
}

// Lappet at bell margin
float lappet(vec2 uv, float fold) {
    vec2 sym = radialFold(uv, fold);
    float r = length(sym);
    // Small rounded lobe projecting beyond bell at r ≈ 0.45
    float lobe = sdCircle(sym - vec2(0.46, 0.0), 0.05);
    return lobe;
}

// Tentacle — sinuous line segment approximated by several sub-segments
float tentacle(vec2 p, float phase, float t) {
    float total = 0.0;
    float seg_len = 0.06;
    vec2 cur = vec2(0.0);
    float amp = 0.035;
    float freq = 12.0;
    for (int i = 0; i < 10; i++) {
        float fi = float(i);
        float wave = amp * sin(freq * fi * 0.1 + phase + t * 0.6);
        vec2 dir = normalize(vec2(1.0, wave));
        vec2 next = cur + dir * seg_len;
        float d = sdSegment(p - vec2(0.0, -0.46), cur, next);
        total = min(total == 0.0 ? d : total, d);
        cur = next;
    }
    return total;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    // Shift up slightly — bell top, tentacles below
    uv.y -= 0.05;

    vec3 paper = mix(vec3(1.0), C_PAPER, u_paper_warmth);

    float fold = max(4.0, floor(u_radial_symmetry));

    float ink = 0.0;
    float wash_cobalt = 0.0;
    float wash_amber = 0.0;

    // Cast shadow (offset down-right)
    vec2 sh_uv = uv - vec2(0.05, -0.05);
    float bell_sh = sdBell(sh_uv, fold);
    float shadow = smoothstep(0.0, 0.15, bell_sh) * 0.06;

    // --- Bell body wash ---
    float bell = sdBell(uv, fold);
    float inside = step(bell, 0.0);

    // Translucent cobalt wash fills bell
    wash_cobalt = inside * u_wash_opacity * 0.45;

    // Subumbrella (inner dome) — slightly amber
    float sub_bell = sdBell(uv * 1.0, fold) + 0.06; // inset
    float sub_inside = step(sub_bell, 0.0);
    wash_amber = sub_inside * u_wash_opacity * 0.2;

    // --- Bell outline ---
    ink += smoothstep(0.010, 0.0, abs(bell)) * u_line_weight_primary;

    // --- Lappets at margin (fold*2 lobes) ---
    float lap = lappet(uv, fold * 2.0);
    ink += smoothstep(0.008, 0.0, abs(lap)) * u_line_weight_secondary;

    // --- Radial canals ---
    float canal_w = 0.004 * u_line_weight_secondary;
    float canal = radialCanal(uv, fold);
    ink += smoothstep(canal_w, 0.0, canal) * inside * u_line_weight_secondary;

    // --- Ring canal at r=0.36 ---
    float ring = sdCircle(uv, 0.36);
    ink += smoothstep(0.006, 0.0, abs(ring)) * inside * u_line_weight_secondary * 0.8;

    // --- Stomach (central manubrium) ---
    float stomach = sdCircle(uv, 0.07);
    ink += smoothstep(0.008, 0.0, abs(stomach)) * u_line_weight_primary * 0.9;
    wash_amber += smoothstep(0.0, -0.01, stomach) * 0.7;

    // Tentacles — arranged at fold positions on bell margin
    for (int i = 0; i < 8; i++) {
        if (float(i) >= fold) break;
        float ta = TAU * float(i) / fold;
        // Rotate tentacle start position
        vec2 start_rot = vec2(cos(ta) * 0.46, sin(ta) * 0.46 - 0.46);
        // Tentacle offset from rotation: project to rotated frame
        mat2 rot = mat2(cos(ta), -sin(ta), sin(ta), cos(ta));
        vec2 tent_uv = rot * (uv - start_rot) * 1.0;
        float t_d = tentacle(tent_uv * 1.5, ta * 3.0, u_time);
        float tw = 0.005 * u_line_weight_secondary;
        ink += smoothstep(tw, 0.0, t_d) * u_line_weight_secondary * 0.7;
    }

    // Stipple on bell surface for texture
    if (inside > 0.5) {
        float sp = 0.0;
        float sp_d = u_stipple_density * 0.4;
        vec2 sp_cell = floor(uv * sp_d);
        float sp_hash = hash21(sp_cell);
        vec2 sp_center = (sp_cell + 0.5) / sp_d;
        float sp_dist = length(uv - sp_center);
        sp = smoothstep(0.5/sp_d, 0.2/sp_d, sp_dist) * step(sp_hash, 0.18);
        ink += sp * 0.25;
    }

    // Wet edge bloom at bell boundary
    float edge_dist = abs(bell);
    float wet_edge = smoothstep(0.06, 0.0, edge_dist) * smoothstep(-0.01, 0.0, bell);
    wash_cobalt += wet_edge * u_wet_edge_intensity * 0.4;

    // --- Compose ---
    vec3 col = paper;
    col = mix(col, col * 0.93, shadow);             // cast shadow
    col = mix(col, C_COBALT, wash_cobalt);           // cobalt wash
    col = mix(col, C_AMBER,  wash_amber * 0.5);      // amber subumbrella
    col = mix(col, C_INK, clamp(ink, 0.0, 1.0));    // ink linework

    // Paper grain
    col += (hash21(gl_FragCoord.xy) - 0.5) * 0.01;

    // Vignette
    col = mix(col * 0.9, col, smoothstep(1.2, 0.5, length(uv)));

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
