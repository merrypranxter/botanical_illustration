// REDOUTE_ROSE — Rosa gallica (Apothecary's Rose)
// Pierre-Joseph Redouté, Les Roses, 1817–1824 — Plate XLVII
// Deep pink single rose | five petals | detailed stamen cluster | thorned stem | warm wash
//
// Biology: Rosa gallica, known since antiquity as the Apothecary's Rose,
// has single or semi-double flowers with five magenta-pink petals.
// The stamens form a dense golden boss at center. Petals are silky with
// slightly notched tips. The sepals are long and reflexed.
// One of Redouté's most celebrated plates — the simplicity of five petals
// revealed in extraordinary soft-light observation.
//
// Mathematics: This shader focuses on the single-flower composition.
// Five petals use polar SDF with subtle asymmetry (no two Redouté petals
// are identical). The stamen cluster is rendered via randomized disc packing.
// Soft FBM displaces wash boundaries to simulate wet capillary action.

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

// REDOUTE_ROSE palette
vec3 C_PAPER  = vec3(1.000, 0.980, 0.945); // warm white paper
vec3 C_ROSE_D = vec3(0.900, 0.180, 0.380); // deep magenta (#E52E60 approx)
vec3 C_ROSE_M = vec3(1.000, 0.412, 0.706); // #FF69B4 mid pink
vec3 C_ROSE_L = vec3(1.000, 0.714, 0.820); // #FFB6C1 light petal edge
vec3 C_GOLD   = vec3(1.000, 0.820, 0.200); // stamen gold
vec3 C_GREEN  = vec3(0.200, 0.450, 0.130); // sepal / leaf
vec3 C_STEM   = vec3(0.380, 0.240, 0.100); // stem brown
vec3 C_INK    = vec3(0.12,  0.08,  0.06);

float hash21(vec2 p) {
    p = fract(p * vec2(127.34, 311.7));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise21(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i), b = hash21(i+vec2(1,0));
    float c = hash21(i+vec2(0,1)), d = hash21(i+vec2(1,1));
    return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 6; i++) { v += a*noise21(p); p=p*2.1+vec2(1.7,9.2); a*=0.5; }
    return v;
}

vec2 rot2(vec2 v, float a) { return vec2(cos(a)*v.x-sin(a)*v.y, sin(a)*v.x+cos(a)*v.y); }

float sdCircle(vec2 p, float r) { return length(p) - r; }

// Rosa gallica single petal — irregular, slightly crumpled
// Returns SDF where negative = inside petal
float sdRosePetal(vec2 p, float plen, float pw, float irregularity) {
    // Base: elongated ellipse, flat at base
    float ey = p.y / pw;
    float d = length(vec2(p.x, ey)) - plen;
    d = max(d, p.x); // flat at attachment
    // Notch at tip (petals are slightly emarginate)
    float notch = sdCircle(p - vec2(plen + 0.01, 0.0), 0.025);
    d = max(d, -notch + 0.008);
    // FBM edge crumple
    float crumple = (fbm(p * 8.0 + irregularity) - 0.5) * 0.018 * u_wet_edge_intensity;
    return d + crumple;
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p-a, ba = b-a;
    return length(pa - ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0));
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    uv.y -= 0.04;

    vec3 paper = mix(vec3(1.0), C_PAPER, u_paper_warmth);

    float ink   = 0.0;
    float rose_d = 0.0;
    float rose_m = 0.0;
    float rose_l = 0.0;
    float gold   = 0.0;
    float green  = 0.0;
    float wet    = 0.0;

    // ======================== STEM AND LEAVES ========================
    // Stem curves gently
    for (int seg = 0; seg < 5; seg++) {
        float t1 = float(seg) / 4.0;
        float t2 = float(seg+1) / 4.0;
        float w1 = sin(t1 * PI) * 0.03;
        float w2 = sin(t2 * PI) * 0.03;
        vec2 sa = vec2(w1, mix(-0.75, -0.08, t1));
        vec2 sb = vec2(w2, mix(-0.75, -0.08, t2));
        float sd = sdSegment(uv, sa, sb) - mix(0.008, 0.005, t1);
        green += smoothstep(0.0, -0.003, sd) * step(uv.y, -0.08) * 0.5;
        ink   += smoothstep(0.004, 0.0, abs(sd)) * step(uv.y, -0.08) * u_line_weight_primary * 0.75;
    }

    // Thorns (two, on stem)
    for (int i = 0; i < 2; i++) {
        float ty = -0.30 - float(i) * 0.22;
        float side = (i % 2 == 0) ? 1.0 : -1.0;
        vec2 thorn_p = rot2(uv - vec2(sin(ty*2.0)*0.03 + side*0.007, ty), side * 0.4);
        float th = max(thorn_p.x, abs(thorn_p.y) - (0.02 - thorn_p.x * 1.5));
        ink += smoothstep(0.004, 0.0, abs(th + 0.01)) * step(uv.y, -0.15) * u_line_weight_secondary * 0.7;
    }

    // Two compound leaves
    {
        // Left leaf cluster at mid-stem
        vec2 lc = vec2(-0.12, -0.45);
        float la = 0.7;
        float ld = length(rot2(uv-lc, la) / vec2(0.10, 0.045)) - 1.0;
        green += smoothstep(0.0, -0.006, ld) * 0.85;
        ink   += smoothstep(0.005, 0.0, abs(ld)) * u_line_weight_secondary * 0.8;
        ink   += smoothstep(0.002, 0.0, abs(rot2(uv-lc, la).y)) * step(ld, 0.0) * u_line_weight_secondary * 0.35;
        // leaflets
        vec2 lc2 = vec2(-0.22, -0.38);
        float la2 = 1.1;
        float ld2 = length(rot2(uv-lc2, la2) / vec2(0.07, 0.033)) - 1.0;
        green += smoothstep(0.0, -0.005, ld2) * 0.8;
        ink   += smoothstep(0.004, 0.0, abs(ld2)) * u_line_weight_secondary * 0.75;
    }
    {
        vec2 lc = vec2(0.10, -0.55);
        float la = -0.6;
        float ld = length(rot2(uv-lc, la) / vec2(0.09, 0.040)) - 1.0;
        green += smoothstep(0.0, -0.005, ld) * 0.8;
        ink   += smoothstep(0.005, 0.0, abs(ld)) * u_line_weight_secondary * 0.75;
        ink   += smoothstep(0.002, 0.0, abs(rot2(uv-lc, la).y)) * step(ld, 0.0) * u_line_weight_secondary * 0.3;
    }

    // ======================== SEPALS ========================
    float n_petals = max(5.0, floor(u_radial_symmetry));
    for (int i = 0; i < 5; i++) {
        float sa = TAU * float(i) / 5.0 - PI * 0.5 + 0.3;
        vec2 sp = rot2(uv - vec2(0.0, -0.08), -sa);
        float sep_d = max(-sp.x, abs(sp.y) - (0.04 - sp.x * 0.35));
        // Reflexed: project backward
        float sep_d2 = max(sp.x - 0.01, abs(sp.y) - 0.015);
        green += smoothstep(0.0, -0.004, min(sep_d, sep_d2)) * 0.65;
        ink   += smoothstep(0.005, 0.0, abs(min(sep_d, sep_d2) + 0.01)) * u_line_weight_secondary * 0.7;
    }

    // ======================== PETALS ========================
    // Five petals, Rosa gallica — arranged with natural slight irregularity
    float petal_irr[5];
    petal_irr[0] = 0.0; petal_irr[1] = 1.3; petal_irr[2] = 2.7;
    petal_irr[3] = 4.1; petal_irr[4] = 5.5;

    float petal_rot_offsets[5];
    petal_rot_offsets[0] = 0.0; petal_rot_offsets[1] = 0.05; petal_rot_offsets[2] = -0.04;
    petal_rot_offsets[3] = 0.06; petal_rot_offsets[4] = -0.03;

    float petal_len[5];
    petal_len[0] = 0.32; petal_len[1] = 0.30; petal_len[2] = 0.31;
    petal_len[3] = 0.29; petal_len[4] = 0.31;

    float petal_w[5];
    petal_w[0] = 0.195; petal_w[1] = 0.185; petal_w[2] = 0.200;
    petal_w[3] = 0.190; petal_w[4] = 0.185;

    for (int i = 0; i < 5; i++) {
        if (float(i) >= n_petals) break;
        float pa = TAU * float(i) / 5.0 - PI * 0.5 + petal_rot_offsets[i];
        // Petals fanned upward; center offset
        float offset_r = 0.06;
        vec2 pc = vec2(cos(pa), sin(pa)) * offset_r;
        vec2 pu = rot2(uv - pc, -pa + PI * 0.5);

        float pd = sdRosePetal(pu, petal_len[i], petal_w[i], petal_irr[i]);

        // Deep rose at center/base, light at edge
        float depth = clamp(-pd / 0.05 + 0.5, 0.0, 1.0);
        rose_l += smoothstep(0.02, -0.01, pd);
        rose_m += smoothstep(0.01, -0.03, pd) * (1.0 - depth * 0.3);
        rose_d += smoothstep(-0.02, -0.10, pd) * 0.5;

        // Petal veins — fine radial lines
        float vein = abs(mod(pu.y / (petal_w[i] * 0.4) + 0.5, 1.0) - 0.5);
        ink += smoothstep(0.08, 0.0, vein) * step(pd, 0.005) * u_line_weight_secondary * 0.15;

        // Outline
        ink += smoothstep(0.009, 0.0, abs(pd)) * u_line_weight_primary * 0.85;

        // Wet bloom at edge
        float wet_disp = fbm(uv * 7.0 + petal_irr[i]) * 0.035;
        float pdw = pd - wet_disp * u_wet_edge_intensity;
        wet += smoothstep(0.06, 0.0, abs(pdw)) * smoothstep(-0.01, 0.02, pdw) * u_wet_edge_intensity * 0.7;
    }

    // ======================== STAMEN CLUSTER ========================
    float stamen_r = 0.09;
    float sc = sdCircle(uv, stamen_r);
    // Gold anther mass
    gold += smoothstep(0.0, -0.01, sc) * 0.8;
    ink  += smoothstep(0.007, 0.0, abs(sc)) * u_line_weight_secondary * 0.7;

    // Individual stamens as small dots
    for (int i = 0; i < 32; i++) {
        float sa = float(i) * 0.618 * TAU; // golden angle packing
        float sr = sqrt(float(i) / 32.0) * stamen_r * 0.9;
        vec2 anther = vec2(cos(sa) * sr, sin(sa) * sr);
        float ad = sdCircle(uv - anther, 0.007);
        gold += smoothstep(0.0, -0.003, ad) * 0.9;
        ink  += smoothstep(0.003, 0.0, abs(ad)) * u_line_weight_secondary * 0.7;
    }

    // Pistil cluster (slightly elevated, darker center)
    float pistil = sdCircle(uv, 0.028);
    rose_m += smoothstep(0.0, -0.004, pistil) * 0.5;
    ink    += smoothstep(0.005, 0.0, abs(pistil)) * u_line_weight_secondary * 0.8;

    // ======================== CAST SHADOW ========================
    float shadow = smoothstep(0.0, 0.22, sdCircle(uv - vec2(0.08, -0.08), 0.42)) * 0.055;

    // ======================== COMPOSE ========================
    vec3 col = paper;
    col = mix(col, col * 0.94, shadow);
    col = mix(col, C_GREEN,  clamp(green,  0.0, 1.0) * u_wash_opacity);
    col = mix(col, C_ROSE_L, clamp(rose_l, 0.0, 1.0) * u_wash_opacity * 0.75);
    col = mix(col, C_ROSE_M, clamp(rose_m, 0.0, 1.0) * u_wash_opacity * 0.80);
    col = mix(col, C_ROSE_D, clamp(rose_d, 0.0, 1.0) * u_wash_opacity * 0.65);
    col = mix(col, C_GOLD,   clamp(gold,   0.0, 1.0) * u_wash_opacity);
    col += vec3(0.15, 0.05, 0.02) * wet;
    col = mix(col, C_INK, clamp(ink, 0.0, 1.0));

    col += (hash21(gl_FragCoord.xy * 0.9) - 0.5) * 0.013;
    col = mix(col * 0.93, col, smoothstep(1.1, 0.4, length(uv)));

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
