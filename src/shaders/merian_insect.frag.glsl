// MERIAN_INSECT_PLANT — Passiflora on Papilio
// Maria Sibylla Merian, Metamorphosis Insectorum Surinamensium, 1705
// Life cycle stages on host plant | egg → larva → pupa → adult | labeled arrangement
//
// Biology: Merian was the first naturalist to document the complete life
// cycles of insects on their host plants. Her plates show all four metamorphic
// stages arranged around the plant, each with identifying marks.
// Here: a Heliconius butterfly on Passiflora (passion flower).
//
// Mathematics: Life cycle stages are placed at four cardinal positions.
// Each stage uses a distinctive SDF: oval for egg, segmented tube for
// larva (caterpillar), elongated dome for pupa (chrysalis), spread-wing
// butterfly for adult. The host plant uses spiral phyllotaxis for leaf placement.

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;
uniform float u_line_weight_primary;
uniform float u_line_weight_secondary;
uniform float u_wash_opacity;
uniform float u_stipple_density;
uniform float u_radial_symmetry;  // unused
uniform float u_wet_edge_intensity;
uniform float u_paper_warmth;

#define PI  3.14159265358979
#define TAU 6.28318530717959

// MERIAN_INSECT palette
vec3 C_PAPER  = vec3(0.980, 0.965, 0.900); // warm cream
vec3 C_GOLD   = vec3(0.855, 0.647, 0.125); // #DAA520
vec3 C_RED    = vec3(0.545, 0.000, 0.000); // #8B0000 deep red
vec3 C_GREEN  = vec3(0.000, 0.392, 0.000); // #006400 dark green
vec3 C_WHEAT  = vec3(0.961, 0.871, 0.702); // #F5DEB3
vec3 C_INK    = vec3(0.08,  0.05,  0.03);

float hash21(vec2 p) {
    p = fract(p * vec2(127.34, 311.7));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 rot2(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c*v.x - s*v.y, s*v.x + c*v.y);
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
        float s2 = cos(h), t2 = sin(h)*sqrt(3.0);
        float rx = sqrt(-c*(s2+t2+2.0)+m2);
        float ry = sqrt(-c*(s2-t2+2.0)+m2);
        co = (ry+sign(l)*rx+abs(g)/(rx*ry)-m)/2.0;
    } else {
        float h = 2.0*m*n*sqrt(d);
        float s2 = sign(q+h)*pow(abs(q+h),1.0/3.0);
        float u2 = sign(q-h)*pow(abs(q-h),1.0/3.0);
        float rx = -s2-u2-c*4.0+2.0*m2;
        float ry = (s2-u2)*sqrt(3.0);
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

// --- Stage SDFs ---

// Stage 0: Egg cluster — several small oval eggs
float stageEgg(vec2 p) {
    float d = 1e6;
    for (int i = 0; i < 6; i++) {
        float a = float(i) * 1.05;
        vec2 off = vec2(cos(a)*0.025, sin(a)*0.018);
        d = min(d, sdEllipse(p - off, vec2(0.025, 0.018)));
    }
    return d;
}

// Stage 1: Larva (caterpillar) — segmented tube
float stageLarva(vec2 p) {
    // 7 body segments along x-axis
    float d = 1e6;
    for (int i = 0; i < 7; i++) {
        float x = float(i) * 0.035 - 0.10;
        float seg = sdCircle(p - vec2(x, 0.0), 0.022);
        d = min(d, seg);
    }
    // Head
    d = min(d, sdCircle(p - vec2(0.14, 0.0), 0.026));
    return d;
}

// Stage 2: Pupa (chrysalis) — tapered dome
float stagePupa(vec2 p) {
    return sdEllipse(p, vec2(0.06, 0.04));
}

// Stage 3: Adult butterfly — spread wings
float stageAdult(vec2 p) {
    // Upper forewing (triangular rounded shape)
    float fw_l = sdEllipse(rot2(p - vec2(-0.06,  0.04), -0.3), vec2(0.12, 0.065));
    float fw_r = sdEllipse(rot2(p - vec2( 0.06,  0.04),  0.3), vec2(0.12, 0.065));
    // Lower hindwing
    float hw_l = sdEllipse(rot2(p - vec2(-0.07, -0.05), 0.2), vec2(0.09, 0.055));
    float hw_r = sdEllipse(rot2(p - vec2( 0.07, -0.05),-0.2), vec2(0.09, 0.055));
    // Body
    float body = sdEllipse(p, vec2(0.015, 0.08));
    return min(min(min(fw_l, fw_r), min(hw_l, hw_r)), body);
}

// --- Plant elements ---
// Leaf (simple SDF ellipse, rotated and positioned)
float sdLeaf(vec2 p, vec2 center, float angle, vec2 ab) {
    return sdEllipse(rot2(p - center, angle), ab);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    vec3 paper = mix(vec3(1.0), C_PAPER, u_paper_warmth);

    float ink   = 0.0;
    float gold  = 0.0;
    float red   = 0.0;
    float green = 0.0;
    float wheat = 0.0;

    // ======================== PLANT STEM ========================
    // Central vine stem
    for (int seg = 0; seg < 8; seg++) {
        float t1 = float(seg) / 7.0;
        float t2 = float(seg + 1) / 7.0;
        float wave1 = sin(t1 * PI * 2.5) * 0.04;
        float wave2 = sin(t2 * PI * 2.5) * 0.04;
        vec2 p1 = vec2(wave1, mix(-0.75, 0.65, t1));
        vec2 p2 = vec2(wave2, mix(-0.75, 0.65, t2));
        float sd = sdSegment(uv, p1, p2) - 0.006;
        green += smoothstep(0.0, -0.003, sd) * 0.9;
        ink   += smoothstep(0.003, 0.0, abs(sd)) * u_line_weight_primary * 0.7;
    }

    // Tendrils (curling)
    for (int i = 0; i < 4; i++) {
        float ty = mix(-0.4, 0.4, float(i) / 3.0);
        float wave = sin(ty * 3.0) * 0.04;
        for (int j = 0; j < 6; j++) {
            float a = float(j) * 0.8;
            float r = 0.02 + float(j) * 0.012;
            vec2 tc = vec2(wave + cos(a) * r + (i % 2 == 0 ? 0.12 : -0.12), ty + sin(a) * r);
            float td = sdCircle(uv - tc, 0.004) - 0.001;
            ink += smoothstep(0.003, 0.0, td) * u_line_weight_secondary * 0.5;
        }
    }

    // Leaves (phyllotaxis-inspired placement)
    float leaf_angles[8];
    leaf_angles[0] = 0.9; leaf_angles[1] = -0.7; leaf_angles[2] = 1.1; leaf_angles[3] = -0.5;
    leaf_angles[4] = 0.7; leaf_angles[5] = -0.9; leaf_angles[6] = 0.6; leaf_angles[7] = -1.0;
    float leaf_y[8];
    leaf_y[0] = -0.55; leaf_y[1] = -0.35; leaf_y[2] = -0.15; leaf_y[3] = 0.05;
    leaf_y[4] = 0.20;  leaf_y[5] = 0.35;  leaf_y[6] = 0.48;  leaf_y[7] = -0.68;

    for (int i = 0; i < 8; i++) {
        float la = leaf_angles[i];
        float ly = leaf_y[i];
        float lx = sin(ly * 3.0) * 0.04 + sign(la) * 0.08;
        vec2 lc = vec2(lx, ly);
        float ld = sdLeaf(uv, lc, la, vec2(0.10, 0.04));
        green += smoothstep(0.0, -0.005, ld) * 0.9;
        ink   += smoothstep(0.006, 0.0, abs(ld)) * u_line_weight_secondary * 0.75;
        // Midrib
        float mr = abs(rot2(uv - lc, la).y);
        ink += smoothstep(0.002, 0.0, mr) * step(ld, 0.0) * u_line_weight_secondary * 0.3;
        // Fine veins
        float vein_a = rot2(uv - lc, la).x;
        float vein = abs(mod(vein_a * 15.0 + 0.5, 1.0) - 0.5);
        ink += smoothstep(0.1, 0.0, vein) * step(ld, 0.0) * u_line_weight_secondary * 0.12;
    }

    // ======================== LIFE CYCLE STAGES ========================
    // Arranged at four corners, labeled I–IV (indicated by position)

    // Stage I: Egg — top left
    {
        vec2 ep = uv - vec2(-0.52, 0.42);
        float ed = stageEgg(ep);
        wheat += smoothstep(0.0, -0.005, ed) * 0.8;
        ink   += smoothstep(0.005, 0.0, abs(ed)) * u_line_weight_primary * 0.8;
        // Label circle (I)
        ink += smoothstep(0.004, 0.0, sdCircle(ep - vec2(0.0, -0.065), 0.015)) * 0.7;
    }

    // Stage II: Larva — top right
    {
        vec2 lp = uv - vec2(0.38, 0.52);
        float ld = stageLarva(lp);
        green += smoothstep(0.0, -0.005, ld) * 0.55;
        gold  += smoothstep(-0.005, -0.015, ld) * 0.4; // stripe suggestion
        ink   += smoothstep(0.007, 0.0, abs(ld)) * u_line_weight_primary * 0.85;
        // Segment lines
        for (int i = 0; i < 7; i++) {
            float sx = float(i) * 0.035 - 0.10 + 0.0175;
            ink += smoothstep(0.002, 0.0, abs(lp.x - sx)) * step(ld, 0.005)
                 * smoothstep(0.022, 0.010, abs(lp.y)) * u_line_weight_secondary * 0.4;
        }
        // Head markings
        ink += smoothstep(0.004, 0.0, sdCircle(lp - vec2(0.14, 0.009), 0.008)) * 0.8; // eye
    }

    // Stage III: Pupa — bottom right
    {
        vec2 pp = uv - vec2(0.52, -0.42);
        float pd = stagePupa(pp);
        gold  += smoothstep(0.0, -0.005, pd) * 0.7;
        ink   += smoothstep(0.007, 0.0, abs(pd)) * u_line_weight_primary * 0.9;
        // Surface striae
        for (int i = 0; i < 5; i++) {
            float sy = float(i) * 0.015 - 0.03;
            ink += smoothstep(0.002, 0.0, abs(pp.y - sy)) * step(pd, 0.003)
                 * u_line_weight_secondary * 0.3;
        }
        // Suspension thread
        ink += smoothstep(0.002, 0.0, abs(pp.x)) * smoothstep(-0.04, -0.07, pp.y)
             * u_line_weight_secondary * 0.5;
    }

    // Stage IV: Adult butterfly — bottom left
    {
        vec2 ap = uv - vec2(-0.45, -0.52);
        float ad = stageAdult(ap);
        // Wing colors — Heliconius: black wings with gold/red bands
        float body_d = sdEllipse(ap, vec2(0.015, 0.08));
        float fw_l = sdEllipse(rot2(ap - vec2(-0.06, 0.04), -0.3), vec2(0.12, 0.065));
        float fw_r = sdEllipse(rot2(ap - vec2( 0.06, 0.04),  0.3), vec2(0.12, 0.065));

        // Black forewing base
        ink   += smoothstep(0.0, -0.005, min(fw_l, fw_r)) * 0.85;
        // Gold band on forewing
        float band_l = sdEllipse(rot2(ap - vec2(-0.02, 0.03), -0.3), vec2(0.06, 0.025));
        float band_r = sdEllipse(rot2(ap - vec2( 0.02, 0.03),  0.3), vec2(0.06, 0.025));
        gold += smoothstep(0.0, -0.005, min(band_l, band_r)) * 0.85;

        // Red lower wing
        float hw_l = sdEllipse(rot2(ap - vec2(-0.07, -0.05), 0.2), vec2(0.09, 0.055));
        float hw_r = sdEllipse(rot2(ap - vec2( 0.07, -0.05),-0.2), vec2(0.09, 0.055));
        red += smoothstep(0.0, -0.005, min(hw_l, hw_r)) * 0.7;

        // Full outline
        ink += smoothstep(0.007, 0.0, abs(ad)) * u_line_weight_primary;

        // Body
        ink  += smoothstep(0.0, -0.003, body_d) * 0.9;
        // Antennae
        for (int i = 0; i < 2; i++) {
            float xs = float(i) * 2.0 - 1.0;
            vec2 ant_a = ap - vec2(xs * 0.012, 0.08);
            vec2 ant_b = ap - vec2(xs * 0.04, 0.16);
            float ant_d = sdSegment(ap, ant_a + vec2(0.0,0.0), ant_b + vec2(0.0,0.0)) - 0.003;
            ink += smoothstep(0.002, 0.0, ant_d) * u_line_weight_secondary * 0.7;
            // Clubbed tip
            ink += smoothstep(0.005, 0.0, sdCircle(ap - ant_b, 0.007)) * 0.9;
        }
    }

    // --- Cast shadow ---
    float shadow = 0.0;
    // Soft shadow under adult
    shadow += smoothstep(0.0, 0.12, stageAdult(uv - vec2(-0.40, -0.57))) * 0.04;

    // --- Compose ---
    vec3 col = paper;
    col = mix(col, col * 0.94, shadow);
    col = mix(col, C_GREEN,  clamp(green, 0.0, 1.0) * u_wash_opacity);
    col = mix(col, C_WHEAT,  clamp(wheat, 0.0, 1.0) * u_wash_opacity);
    col = mix(col, C_GOLD,   clamp(gold, 0.0, 1.0) * u_wash_opacity);
    col = mix(col, C_RED,    clamp(red, 0.0, 1.0) * u_wash_opacity);
    col = mix(col, C_INK, clamp(ink, 0.0, 1.0));

    col += (hash21(gl_FragCoord.xy * 0.9) - 0.5) * 0.011;
    col = mix(col * 0.92, col, smoothstep(1.1, 0.4, length(uv)));

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
