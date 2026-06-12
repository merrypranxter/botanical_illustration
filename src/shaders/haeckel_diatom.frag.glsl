// HAECKEL_DIATOM — Coscinodiscus concinnus
// Ernst Haeckel / Christian Gottfried Ehrenberg, 1838–1904
// Diatom frustule: circular valve face, 16-fold symmetry | areolae lattice | silicate fine structure
//
// Biology: Diatoms (Bacillariophyta) build two-part glass boxes (frustules)
// with extraordinary nano-scale patterning. The circular valve face of
// Coscinodiscus shows a hexagonal areolae lattice organized in radial sectors.
// Each areola is a chamber with a fine silica mesh — nature's photonic crystal.
//
// Mathematics: 16-fold primary symmetry. Areolae are circles on a
// hexagonal lattice, rendered via modular distance fields.
// The silicate rim (cingulum) is a concentric band with fine transverse striae.

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
vec3 C_SILICA = vec3(0.92, 0.90, 0.88); // near-white silicate glass

float hash21(vec2 p) {
    p = fract(p * vec2(127.34, 311.7));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 radialFold(vec2 uv, float n) {
    float a = atan(uv.y, uv.x);
    float r = length(uv);
    float s = TAU / n;
    float fa = mod(a, s);
    if (fa > s * 0.5) fa = s - fa;
    return vec2(cos(fa), sin(fa)) * r;
}

// Hexagonal lattice distance — returns distance to nearest hex center
float hexLattice(vec2 p, float scale) {
    p *= scale;
    vec2 a = mod(p, vec2(1.0, 1.732)) - vec2(0.5, 0.866);
    vec2 b = mod(p - vec2(0.5, 0.866), vec2(1.0, 1.732)) - vec2(0.5, 0.866);
    return min(length(a), length(b));
}

// SDF circle
float sdCircle(vec2 p, float r) { return length(p) - r; }

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    vec3 paper = mix(vec3(1.0), C_PAPER, u_paper_warmth);

    float fold = max(8.0, floor(u_radial_symmetry));
    float r = length(uv);

    float ink = 0.0;
    float wash_cobalt = 0.0;
    float wash_amber = 0.0;
    float silica = 0.0;

    // --- Outer valve rim ---
    float outer_r = 0.48;
    float rim_w = 0.025;
    float rim = sdCircle(uv, outer_r);
    float inside = step(rim, 0.0);
    ink += smoothstep(0.010, 0.0, abs(rim)) * u_line_weight_primary;

    // Cingulum (girdle band) — concentric ring just inside rim
    float cing_r = outer_r - 0.04;
    float cingulum = sdCircle(uv, cing_r);
    ink += smoothstep(0.006, 0.0, abs(cingulum)) * u_line_weight_secondary * 0.8;

    // --- Radial costae: primary ribs from center to rim ---
    vec2 sym_fold = radialFold(uv, fold);
    float costa_w = 0.005 * u_line_weight_secondary;
    // Primary rib along x-axis in folded space
    float costa = abs(sym_fold.y);
    ink += smoothstep(costa_w, 0.0, costa) * inside * u_line_weight_secondary * 0.9;

    // Secondary costae at half-sector
    vec2 sym2 = radialFold(uv, fold * 2.0);
    float sec_costa_w = 0.003 * u_line_weight_secondary;
    ink += smoothstep(sec_costa_w, 0.0, abs(sym2.y)) * inside * u_line_weight_secondary * 0.5
           * smoothstep(0.15, 0.18, r); // only past inner zone

    // --- Areolae (hexagonal pore lattice on valve face) ---
    // Lattice density increases outward (mimics real Coscinodiscus)
    float areola_d = hexLattice(uv, u_stipple_density * 0.6);
    float areola_r = 0.3 / (u_stipple_density * 0.6); // radius of each areola hole
    float areola_mask = inside * step(0.12, r); // not in central rosette
    // Pore: dark dot surrounded by silicate ridge
    float pore = smoothstep(areola_r * 0.5, areola_r * 0.2, areola_d);
    ink += pore * areola_mask * 0.5 * u_line_weight_secondary;
    // Silicate wall around pore
    float wall = smoothstep(areola_r * 0.9, areola_r * 0.55, areola_d)
               * smoothstep(areola_r * 0.4, areola_r * 0.6, areola_d);
    silica += wall * areola_mask * 0.4;

    // --- Central rosette (no pores, solid with ribs) ---
    float rosette_r = 0.12;
    float rosette = sdCircle(uv, rosette_r);
    wash_amber += smoothstep(0.0, -0.01, rosette) * 0.7;
    ink += smoothstep(0.008, 0.0, abs(rosette)) * u_line_weight_primary * 0.9;
    // Fine striae in rosette
    vec2 r_sym = radialFold(uv, fold * 2.0);
    float stria = abs(r_sym.y);
    ink += smoothstep(0.002, 0.0, stria) * step(rosette, 0.0) * u_line_weight_secondary * 0.4;

    // --- Cobalt structural wash on valve face ---
    wash_cobalt = inside * u_wash_opacity * 0.3;
    // Gradient: denser cobalt toward center
    wash_cobalt += inside * smoothstep(0.48, 0.0, r) * u_wash_opacity * 0.15;

    // Silicate amber color
    wash_amber += inside * smoothstep(0.05, 0.15, r) * 0.15;

    // --- Cingulum striations ---
    float cingulum_zone = smoothstep(0.01, 0.0, abs(r - outer_r + 0.02))
                        * smoothstep(-0.02, 0.01, r - cing_r);
    // Vertical striae across band
    float stria_spacing = 0.015;
    float stria_x = mod(atan(uv.y, uv.x) * outer_r, stria_spacing);
    float stria_v = smoothstep(0.003, 0.0, min(stria_x, stria_spacing - stria_x));
    ink += stria_v * cingulum_zone * u_line_weight_secondary * 0.6;

    // --- Cast shadow ---
    float shadow = smoothstep(0.0, 0.15, sdCircle(uv - vec2(0.04, -0.04), outer_r)) * 0.06;

    // --- Compose ---
    vec3 col = paper;
    col = mix(col, col * 0.93, shadow);
    col = mix(col, C_COBALT, wash_cobalt);
    col = mix(col, C_AMBER, wash_amber);
    col = mix(col, C_SILICA, silica);
    col = mix(col, C_INK, clamp(ink, 0.0, 1.0));

    // Paper grain
    col += (hash21(gl_FragCoord.xy) - 0.5) * 0.01;

    // Vignette
    col = mix(col * 0.88, col, smoothstep(1.2, 0.4, length(uv)));

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
