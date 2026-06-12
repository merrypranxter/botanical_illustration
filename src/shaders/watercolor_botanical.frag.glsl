// WATERCOLOR_BOTANICAL — Rosa centifolia (Cabbage Rose)
// Pierre-Joseph Redouté, Les Roses, 1817–1824
// Soft watercolor washes | wet edge blooms | petal SDF structure | cream ground
//
// Biology: Rosa centifolia, the "hundred-petalled rose", was Redouté's signature subject.
// Petals arrange in tight spirals following Fibonacci phyllotaxis. Outermost guard
// petals are larger; innermost petals densely packed, creamy-white at center.
// Sepals are narrow, pointed, with glandular margins.
//
// Mathematics: Petals use polar SDF with angular period. Wet edge bloom is an
// FBM displacement on the color region boundary, alpha-fading outward —
// simulating capillary wicking. Wash layers use additive alpha compositing.

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
vec3 C_PAPER   = vec3(1.000, 0.980, 0.902); // #FFFACD lemon chiffon
vec3 C_PINK_L  = vec3(1.000, 0.714, 0.757); // #FFB6C1 light pink
vec3 C_PINK_H  = vec3(1.000, 0.412, 0.706); // #FF69B4 hot pink
vec3 C_GREEN   = vec3(0.133, 0.545, 0.133); // #228B22 leaf green
vec3 C_GREEN_L = vec3(0.565, 0.933, 0.565); // #90EE90 light green
vec3 C_INK     = vec3(0.15,  0.10,  0.08);

float hash21(vec2 p) {
    p = fract(p * vec2(127.34, 311.7));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 rot2(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c*v.x - s*v.y, s*v.x + c*v.y);
}

float noise21(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i), b = hash21(i + vec2(1,0));
    float c2 = hash21(i + vec2(0,1)), d = hash21(i + vec2(1,1));
    return mix(mix(a,b,f.x), mix(c2,d,f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise21(p);
        p = p * 2.1 + vec2(1.7, 9.2);
        a *= 0.5;
    }
    return v;
}

// Petal SDF — elongated rounded shape in local petal space
float sdPetal(vec2 p, float plen, float width) {
    float wy = width;
    float ey = p.y / wy;
    float ex = p.x;
    float d = length(vec2(ex, ey)) - plen;
    d = max(d, p.x); // flat base
    return d * min(1.0, wy);
}

// Sepal SDF — narrow tapered lobe
float sdSepal(vec2 p, float plen, float w) {
    float h = clamp(p.x / plen, 0.0, 1.0);
    float half_w = w * (1.0 - h);
    return max(-p.x, abs(p.y) - half_w);
}

float sdCircle(vec2 p, float r) { return length(p) - r; }

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    uv.y -= 0.02;

    vec3 paper = mix(vec3(1.0), C_PAPER, u_paper_warmth);

    float ink    = 0.0;
    float pink_l = 0.0;
    float pink_h = 0.0;
    float green  = 0.0;
    float wet    = 0.0;

    float n_outer = max(5.0, floor(u_radial_symmetry));
    float n_mid   = floor(n_outer * 1.4);
    float n_inner = floor(n_outer * 2.0);

    // --- Stem ---
    float stem_mask = step(uv.y, -0.25) * step(-0.72, uv.y);
    ink += smoothstep(0.003, 0.0, abs(uv.x) - 0.006) * stem_mask * u_line_weight_primary * 0.7;

    // --- Leaves ---
    {
        vec2 lv = rot2(uv - vec2(0.06, -0.42), 0.5);
        float ld = length(lv / vec2(0.14, 0.05)) - 1.0;
        green += smoothstep(0.0, -0.01, ld) * 0.85;
        ink   += smoothstep(0.007, 0.0, abs(ld)) * u_line_weight_secondary * 0.7;
        float midrib = abs(rot2(uv - vec2(0.06, -0.42), 0.5).y);
        ink += smoothstep(0.003, 0.0, midrib) * step(ld, 0.0) * u_line_weight_secondary * 0.4;
    }
    {
        vec2 lv2 = rot2(uv - vec2(-0.07, -0.52), -0.6);
        float ld2 = length(lv2 / vec2(0.12, 0.04)) - 1.0;
        green += smoothstep(0.0, -0.01, ld2) * 0.7;
        ink   += smoothstep(0.007, 0.0, abs(ld2)) * u_line_weight_secondary * 0.7;
    }

    // --- Sepals ---
    for (int i = 0; i < 5; i++) {
        float sa = TAU * float(i) / 5.0 - PI * 0.5;
        vec2 sp = rot2(uv - vec2(0.0, -0.22), -sa);
        float s_d = sdSepal(sp, 0.14, 0.025);
        green += smoothstep(0.0, -0.01, s_d) * 0.65;
        ink   += smoothstep(0.005, 0.0, abs(s_d)) * u_line_weight_secondary * 0.7;
    }

    // --- Outer guard petals ---
    for (int i = 0; i < 16; i++) {
        if (float(i) >= n_outer) break;
        float pa = TAU * (float(i) + 0.5) / n_outer;
        vec2 pc = vec2(cos(pa), sin(pa)) * 0.28;
        vec2 pu = rot2(uv - pc, -pa + PI * 0.5);
        float pd = sdPetal(pu, 0.22, 0.13);
        float wd = fbm(uv * 6.0 + float(i) * 1.3) * 0.04;
        float pdw = pd - wd * u_wet_edge_intensity;
        pink_l += smoothstep(0.02, -0.02, pdw);
        ink    += smoothstep(0.008, 0.0, abs(pd)) * u_line_weight_primary * 0.7;
        wet    += smoothstep(0.06, 0.0, abs(pdw)) * smoothstep(-0.01, 0.02, pdw) * u_wet_edge_intensity * 0.6;
    }

    // --- Middle petals ---
    for (int i = 0; i < 20; i++) {
        if (float(i) >= n_mid) break;
        float pa = TAU * (float(i) + 0.3) / n_mid + 0.15;
        vec2 pc = vec2(cos(pa), sin(pa)) * 0.16;
        vec2 pu = rot2(uv - pc, -pa + PI * 0.5);
        float pd = sdPetal(pu, 0.16, 0.09);
        float wd = fbm(uv * 7.0 + float(i) * 2.1) * 0.03;
        float pdw = pd - wd * u_wet_edge_intensity;
        pink_l += smoothstep(0.01, -0.02, pdw) * 0.8;
        pink_h += smoothstep(0.0, -0.03, pdw) * 0.3;
        ink    += smoothstep(0.007, 0.0, abs(pd)) * u_line_weight_secondary * 0.8;
        wet    += smoothstep(0.05, 0.0, abs(pdw)) * smoothstep(-0.01, 0.02, pdw) * u_wet_edge_intensity * 0.5;
    }

    // --- Inner petals (deep pink, densely packed) ---
    for (int i = 0; i < 24; i++) {
        if (float(i) >= n_inner) break;
        float pa = TAU * (float(i) + 0.1) / n_inner + 0.4;
        vec2 pc = vec2(cos(pa), sin(pa)) * 0.07;
        vec2 pu = rot2(uv - pc, -pa + PI * 0.5);
        float pd = sdPetal(pu, 0.10, 0.07);
        float wd = fbm(uv * 9.0 + float(i) * 1.8) * 0.02;
        float pdw = pd - wd * u_wet_edge_intensity;
        pink_h += smoothstep(0.01, -0.02, pdw);
        ink    += smoothstep(0.006, 0.0, abs(pd)) * u_line_weight_secondary * 0.7;
    }

    // --- Rosette center and stamens ---
    float rosette = sdCircle(uv, 0.04);
    pink_h += smoothstep(0.0, -0.005, rosette) * 0.5;
    ink    += smoothstep(0.006, 0.0, abs(rosette)) * u_line_weight_primary * 0.8;
    for (int i = 0; i < 12; i++) {
        float sa = TAU * float(i) / 12.0;
        float sd2 = sdCircle(uv - vec2(cos(sa), sin(sa)) * 0.045, 0.008);
        ink    += smoothstep(0.003, 0.0, abs(sd2)) * u_line_weight_secondary * 0.8;
        pink_l += smoothstep(0.0, -0.003, sd2) * 0.6;
    }

    // --- Shadow ---
    float shadow = smoothstep(0.0, 0.25, sdCircle(uv - vec2(0.1, -0.08), 0.45)) * 0.05;

    // --- Compose ---
    vec3 col = paper;
    col = mix(col, col * 0.94, shadow);
    col = mix(col, C_GREEN_L, clamp(green, 0.0, 1.0) * 0.4);
    col = mix(col, C_GREEN,   clamp(green - 0.3, 0.0, 1.0) * u_wash_opacity * 0.9);
    col = mix(col, C_PINK_L,  clamp(pink_l, 0.0, 1.0) * u_wash_opacity * 0.75);
    col = mix(col, C_PINK_H,  clamp(pink_h, 0.0, 1.0) * u_wash_opacity * 0.7);
    col += vec3(0.12, 0.04, 0.01) * wet;
    col = mix(col, C_INK, clamp(ink, 0.0, 1.0));

    col += (hash21(gl_FragCoord.xy * 0.9) - 0.5) * 0.012;
    col = mix(col * 0.93, col, smoothstep(1.1, 0.4, length(uv)));

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
