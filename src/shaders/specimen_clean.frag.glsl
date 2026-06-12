// SPECIMEN_CLEAN — Atropa belladonna (Deadly Nightshade)
// William Woodville, Medical Botany, 1790–1794
// Clean scientific specimen | ink black on near-white | root system visible | cast shadow
//
// Biology: Atropa belladonna is a solanaceous herb with ovate leaves,
// drooping bell-shaped purple-brown flowers, and glossy black berries.
// The root system is a thick taproot with spreading lateral rootlets.
// All parts contain tropane alkaloids (atropine, scopolamine).
// The dilated-pupil property (belladonna = "beautiful woman") made it
// cosmetically fashionable and medically critical.
//
// Mathematics: Stem uses Catmull-Rom-like smooth segment chains.
// Root is a branching fractal tree (L-system approximation).
// Berry: perfect circle with specular highlight.
// Flower: radial petal SDF with calyx and corolla tube.

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

// SPECIMEN_CLEAN palette
vec3 C_PAPER  = vec3(1.000, 0.999, 0.980); // #FFFEF5 near white
vec3 C_INK    = vec3(0.110, 0.110, 0.110); // #1C1C1C near black
vec3 C_BROWN  = vec3(0.545, 0.271, 0.075); // #8B4513 warm brown (root, stem)
vec3 C_COBALT = vec3(0.255, 0.412, 0.882); // #4169E1 cobalt (flower)
vec3 C_PURPLE = vec3(0.35,  0.10,  0.45);  // dull purple-brown flower
vec3 C_GREEN  = vec3(0.20,  0.42,  0.12);  // leaf
vec3 C_BERRY  = vec3(0.04,  0.03,  0.05);  // near-black berry

float hash21(vec2 p) {
    p = fract(p * vec2(127.34, 311.7));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float sdCircle(vec2 p, float r) { return length(p) - r; }

float sdEllipse(vec2 p, vec2 ab) {
    p = abs(p); if (p.x > p.y) { p = p.yx; ab = ab.yx; }
    float l = ab.y*ab.y - ab.x*ab.x;
    float m = ab.x*p.x/l, m2 = m*m;
    float n = ab.y*p.y/l, n2 = n*n;
    float c = (m2+n2-1.0)/3.0, c3 = c*c*c;
    float q = c3 + m2*n2*2.0, d = c3 + m2*n2;
    float g = m + m*n2;
    float co;
    if (d < 0.0) {
        float h = acos(q/c3)/3.0;
        float s = cos(h), t = sin(h)*sqrt(3.0);
        float rx = sqrt(-c*(s+t+2.0)+m2), ry = sqrt(-c*(s-t+2.0)+m2);
        co = (ry+sign(l)*rx+abs(g)/(rx*ry)-m)/2.0;
    } else {
        float h = 2.0*m*n*sqrt(d);
        float s = sign(q+h)*pow(abs(q+h),1.0/3.0);
        float u2 = sign(q-h)*pow(abs(q-h),1.0/3.0);
        float rx = -s-u2-c*4.0+2.0*m2, ry = (s-u2)*sqrt(3.0);
        float rm = sqrt(rx*rx+ry*ry);
        co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
    }
    vec2 r2 = ab*vec2(co, sqrt(1.0-co*co));
    return length(r2-p)*sign(p.y-r2.y);
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p-a, ba = b-a;
    return length(pa - ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0));
}

vec2 rot2(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c*v.x - s*v.y, s*v.x + c*v.y);
}

// Thick branch/stem as tapered segment
float sdThickSeg(vec2 p, vec2 a, vec2 b, float ra, float rb) {
    vec2 pa = p-a, ba = b-a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    float r = mix(ra, rb, h);
    return length(pa - ba*h) - r;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    vec3 paper = mix(vec3(1.0), C_PAPER, u_paper_warmth * 0.5);

    float ink    = 0.0;
    float cobalt = 0.0;  // flower wash
    float brown  = 0.0;  // root / stem
    float green  = 0.0;  // leaf
    float berry  = 0.0;

    // Specimen shifted slightly down to show roots below and flowers above
    uv.y -= 0.0;

    // ======================== ROOT SYSTEM (below ground line) ========================
    float ground_y = -0.18;
    float below = step(uv.y, ground_y);

    // Taproot — central vertical root descending
    {
        float td = sdThickSeg(uv, vec2(0.0, ground_y), vec2(0.02, -0.70), 0.015, 0.006);
        brown += smoothstep(0.0, -0.003, td) * below * 0.7;
        ink   += smoothstep(0.004, 0.0, abs(td)) * below * u_line_weight_primary * 0.8;
    }

    // Lateral rootlets — branching off taproot
    for (int i = 0; i < 6; i++) {
        float ty = ground_y - 0.08 - float(i) * 0.08;
        float tx = 0.02 + ty * 0.03;
        float side = (i % 2 == 0) ? 1.0 : -1.0;
        float ang = side * (PI * 0.35 + float(i) * 0.1);
        vec2 root_a = vec2(tx, ty);
        vec2 root_b = root_a + vec2(cos(ang), sin(ang)) * (0.08 + float(i) * 0.02);
        float rd = sdThickSeg(uv, root_a, root_b, 0.005, 0.002);
        brown += smoothstep(0.0, -0.002, rd) * 0.6;
        ink   += smoothstep(0.003, 0.0, abs(rd)) * below * u_line_weight_secondary * 0.7;

        // Fine rootlet tips
        vec2 root_c = root_b + vec2(cos(ang + 0.4*side), sin(ang + 0.3)) * 0.05;
        float rdt = sdThickSeg(uv, root_b, root_c, 0.002, 0.001);
        ink += smoothstep(0.002, 0.0, abs(rdt)) * below * u_line_weight_secondary * 0.5;
    }

    // Ground line — thin horizontal rule
    ink += smoothstep(0.002, 0.0, abs(uv.y - ground_y)) * step(abs(uv.x), 0.60)
         * u_line_weight_secondary * 0.4;

    // ======================== MAIN STEM ========================
    // Branching stem above ground
    float above = 1.0 - below;

    // Primary stem
    {
        float sd = sdThickSeg(uv, vec2(0.0, ground_y), vec2(-0.04, 0.25), 0.012, 0.008);
        brown += smoothstep(0.0, -0.003, sd) * above * 0.6;
        ink   += smoothstep(0.005, 0.0, abs(sd)) * above * u_line_weight_primary * 0.9;
    }
    // Left branch
    {
        float sd = sdThickSeg(uv, vec2(-0.04, 0.12), vec2(-0.28, 0.42), 0.007, 0.004);
        brown += smoothstep(0.0, -0.003, sd) * above * 0.5;
        ink   += smoothstep(0.004, 0.0, abs(sd)) * above * u_line_weight_secondary * 0.85;
    }
    // Right branch
    {
        float sd = sdThickSeg(uv, vec2(-0.04, 0.20), vec2(0.22, 0.45), 0.007, 0.004);
        brown += smoothstep(0.0, -0.003, sd) * above * 0.5;
        ink   += smoothstep(0.004, 0.0, abs(sd)) * above * u_line_weight_secondary * 0.85;
    }
    // Sub-branches
    {
        float sd = sdThickSeg(uv, vec2(-0.28, 0.42), vec2(-0.40, 0.62), 0.005, 0.003);
        ink += smoothstep(0.003, 0.0, abs(sd)) * u_line_weight_secondary * 0.8;
    }
    {
        float sd = sdThickSeg(uv, vec2(0.22, 0.45), vec2(0.36, 0.65), 0.005, 0.003);
        ink += smoothstep(0.003, 0.0, abs(sd)) * u_line_weight_secondary * 0.8;
    }

    // ======================== LEAVES ========================
    // Large ovate leaves with pointed apex
    struct Leaf { vec2 center; float angle; vec2 ab; };

    // Left large leaf
    {
        vec2 lc = vec2(-0.18, 0.30);
        float la = 0.55;
        vec2 lab = vec2(0.16, 0.09);
        vec2 lv = rot2(uv - lc, la);
        float ld = sdEllipse(lv, lab);
        green += smoothstep(0.0, -0.008, ld) * 0.8;
        ink   += smoothstep(0.006, 0.0, abs(ld)) * u_line_weight_primary * 0.85;
        // Midrib
        ink += smoothstep(0.003, 0.0, abs(rot2(uv-lc, la).y)) * step(ld, 0.0) * u_line_weight_secondary * 0.45;
        // Secondary veins
        for (int vi = 1; vi <= 5; vi++) {
            float vx = float(vi) * 0.025 - 0.065;
            float va = 0.45;
            vec2 vstart = vec2(vx, 0.0);
            vec2 vend   = vec2(vx + cos(va)*0.06, sin(va)*0.06);
            float vd = sdSegment(rot2(uv-lc, la), vstart, vend) - 0.002;
            ink += smoothstep(0.002, 0.0, vd) * step(ld, 0.0) * u_line_weight_secondary * 0.25;
            vd = sdSegment(rot2(uv-lc, la), vstart, vec2(vx + cos(-va)*0.06, sin(-va)*0.06)) - 0.002;
            ink += smoothstep(0.002, 0.0, vd) * step(ld, 0.0) * u_line_weight_secondary * 0.25;
        }
    }
    // Right medium leaf
    {
        vec2 lc = vec2(0.14, 0.34);
        float la = -0.5;
        vec2 lab = vec2(0.12, 0.07);
        vec2 lv = rot2(uv - lc, la);
        float ld = sdEllipse(lv, lab);
        green += smoothstep(0.0, -0.007, ld) * 0.75;
        ink   += smoothstep(0.006, 0.0, abs(ld)) * u_line_weight_primary * 0.85;
        ink   += smoothstep(0.002, 0.0, abs(rot2(uv-lc, la).y)) * step(ld, 0.0) * u_line_weight_secondary * 0.40;
    }
    // Upper small leaf
    {
        vec2 lc = vec2(-0.04, 0.55);
        float la = 0.15;
        vec2 lab = vec2(0.10, 0.06);
        vec2 lv = rot2(uv - lc, la);
        float ld = sdEllipse(lv, lab);
        green += smoothstep(0.0, -0.006, ld) * 0.7;
        ink   += smoothstep(0.005, 0.0, abs(ld)) * u_line_weight_primary * 0.8;
        ink   += smoothstep(0.002, 0.0, abs(rot2(uv-lc, la).y)) * step(ld, 0.0) * u_line_weight_secondary * 0.4;
    }

    // ======================== FLOWERS ========================
    // Drooping bell-shaped, dull purple-brown
    // Flower 1 — left branch tip
    {
        vec2 fc = vec2(-0.38, 0.62);
        vec2 fv = uv - fc;
        // Corolla tube (elongated bell)
        float tube = sdEllipse(fv - vec2(0.0, -0.03), vec2(0.035, 0.055));
        cobalt += smoothstep(0.0, -0.005, tube) * 0.6;
        ink    += smoothstep(0.006, 0.0, abs(tube)) * u_line_weight_primary * 0.85;
        // Five corolla lobes
        for (int i = 0; i < 5; i++) {
            float la = TAU * float(i) / 5.0 - PI * 0.5;
            vec2 lp = fv - vec2(cos(la), sin(la)) * 0.058;
            float lobe = sdEllipse(rot2(lp, la), vec2(0.026, 0.016));
            cobalt += smoothstep(0.0, -0.004, lobe) * 0.4;
            ink    += smoothstep(0.005, 0.0, abs(lobe)) * u_line_weight_secondary * 0.8;
        }
        // Calyx
        for (int i = 0; i < 5; i++) {
            float la = TAU * float(i) / 5.0 - PI * 0.5;
            vec2 cp = fv - vec2(cos(la), sin(la)) * 0.07;
            float sep = sdEllipse(rot2(cp, la), vec2(0.014, 0.022));
            green += smoothstep(0.0, -0.003, sep) * 0.6;
            ink   += smoothstep(0.004, 0.0, abs(sep)) * u_line_weight_secondary * 0.7;
        }
    }
    // Flower 2 — right branch tip
    {
        vec2 fc = vec2(0.34, 0.65);
        vec2 fv = uv - fc;
        float tube = sdEllipse(fv - vec2(0.0, -0.03), vec2(0.030, 0.048));
        cobalt += smoothstep(0.0, -0.005, tube) * 0.55;
        ink    += smoothstep(0.006, 0.0, abs(tube)) * u_line_weight_primary * 0.85;
        for (int i = 0; i < 5; i++) {
            float la = TAU * float(i) / 5.0 - PI * 0.5;
            vec2 lp = fv - vec2(cos(la), sin(la)) * 0.05;
            float lobe = sdEllipse(rot2(lp, la), vec2(0.022, 0.014));
            cobalt += smoothstep(0.0, -0.004, lobe) * 0.35;
            ink    += smoothstep(0.005, 0.0, abs(lobe)) * u_line_weight_secondary * 0.8;
        }
    }

    // ======================== BERRIES ========================
    // Glossy black berries on short pedicels
    float berry_positions[4];
    berry_positions[0] = -0.25; berry_positions[1] = 0.48;
    berry_positions[2] =  0.08; berry_positions[3] = 0.50;

    for (int bi = 0; bi < 2; bi++) {
        vec2 bc = vec2(berry_positions[bi*2], berry_positions[bi*2+1]);
        float bd = sdCircle(uv - bc, 0.040);
        berry  += smoothstep(0.0, -0.005, bd);
        ink    += smoothstep(0.007, 0.0, abs(bd)) * u_line_weight_primary;
        // Specular highlight
        float hl = sdCircle(uv - bc - vec2(0.012, 0.015), 0.010);
        float hl_val = smoothstep(0.0, -0.005, hl);
        berry -= hl_val * 0.8; // cut out highlight
        // Pedicel
        float pd = sdThickSeg(uv, bc + vec2(0.0, 0.04), bc + vec2(0.0, 0.08), 0.003, 0.002);
        ink += smoothstep(0.002, 0.0, abs(pd)) * u_line_weight_secondary * 0.7;
    }

    // ======================== CAST SHADOW ========================
    float shadow = 0.0;
    // Soft elliptical shadow under plant
    shadow += smoothstep(0.0, 0.18, sdEllipse(uv - vec2(0.08, 0.22), vec2(0.30, 0.08))) * 0.05;

    // ======================== COMPOSE ========================
    vec3 col = paper;
    col = mix(col, col * 0.94, shadow);
    col = mix(col, C_BROWN,  clamp(brown, 0.0, 1.0) * u_wash_opacity * 0.7);
    col = mix(col, C_GREEN,  clamp(green, 0.0, 1.0) * u_wash_opacity);
    col = mix(col, C_PURPLE, clamp(cobalt, 0.0, 1.0) * u_wash_opacity * 0.8);
    col = mix(col, C_BERRY,  clamp(berry, 0.0, 1.0));
    col = mix(col, C_INK, clamp(ink, 0.0, 1.0));

    // Very fine paper grain
    col += (hash21(gl_FragCoord.xy) - 0.5) * 0.009;

    // Minimal vignette on clean scientific plate
    col = mix(col * 0.97, col, smoothstep(1.0, 0.5, length(uv)));

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
