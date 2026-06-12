// AUDUBON_FIELD — Cardinalis cardinalis (Northern Cardinal)
// John James Audubon, The Birds of America, 1827–1838
// Single specimen | accurate plumage colors | perched branch | Latin binomial below
//
// Biology: The male Northern Cardinal (Cardinalis cardinalis) is one of North
// America's most recognized birds. The brilliant scarlet plumage results from
// carotenoid pigments. The black mask extends from the face to the upper breast.
// The crest is raised when alert or aggressive. Females are buff-brown with
// warm red tints on crest, wings, and tail.
//
// Mathematics: Bird silhouette approximated by overlapping ellipses and
// bezier-like smooth min operations. Plumage regions are masked by SDFs.
// Branch is a tapered cylinder. "Latin name" is a horizontal rule (text
// rendering requires a texture atlas not available in raw GLSL).

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

// AUDUBON_BIRD palette
vec3 C_PAPER   = vec3(1.000, 0.973, 0.863); // #FFF8DC cornsilk
vec3 C_CARDINAL = vec3(0.80,  0.05,  0.02);  // brilliant scarlet
vec3 C_MASK    = vec3(0.08,  0.06,  0.05);  // near-black mask
vec3 C_BRANCH  = vec3(0.545, 0.271, 0.075); // #8B4513 brown
vec3 C_LEAF    = vec3(0.133, 0.545, 0.133); // #228B22 green
vec3 C_INK     = vec3(0.08,  0.05,  0.03);
vec3 C_SKY     = vec3(0.529, 0.808, 0.922); // #87CEEB — accent, not used in specimen

float hash21(vec2 p) {
    p = fract(p * vec2(127.34, 311.7));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float sdCircle(vec2 p, float r) { return length(p) - r; }

float sdEllipse(vec2 p, vec2 ab) {
    // Exact SDF for axis-aligned ellipse (Inigo Quilez)
    p = abs(p); if (p.x > p.y) { p = p.yx; ab = ab.yx; }
    float l = ab.y*ab.y - ab.x*ab.x;
    float m = ab.x*p.x/l, m2 = m*m;
    float n = ab.y*p.y/l, n2 = n*n;
    float c = (m2+n2-1.0)/3.0;
    float c3 = c*c*c;
    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;
    float co;
    if (d < 0.0) {
        float h = acos(q/c3)/3.0;
        float s = cos(h), t2 = sin(h)*sqrt(3.0);
        float rx = sqrt(-c*(s+t2+2.0)+m2);
        float ry = sqrt(-c*(s-t2+2.0)+m2);
        co = (ry+sign(l)*rx+abs(g)/(rx*ry)-m)/2.0;
    } else {
        float h = 2.0*m*n*sqrt(d);
        float s = sign(q+h)*pow(abs(q+h),1.0/3.0);
        float u2 = sign(q-h)*pow(abs(q-h),1.0/3.0);
        float rx = -s-u2-c*4.0+2.0*m2;
        float ry = (s-u2)*sqrt(3.0);
        float rm = sqrt(rx*rx+ry*ry);
        co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
    }
    vec2 r2 = ab*vec2(co, sqrt(1.0-co*co));
    return length(r2-p)*sign(p.y-r2.y);
}

// Smooth minimum for blending SDF shapes together
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}

vec2 rot2(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c*v.x - s*v.y, s*v.x + c*v.y);
}

// Plumage texture: fine parallel lines for feather barbs
float featherLines(vec2 p, float spacing, float angle) {
    vec2 rp = rot2(p, angle);
    float lines = mod(rp.x, spacing);
    return smoothstep(spacing * 0.15, 0.0, min(lines, spacing - lines));
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    vec3 paper = mix(vec3(1.0), C_PAPER, u_paper_warmth);

    float ink     = 0.0;
    float cardinal = 0.0;
    float mask_v   = 0.0;
    float branch_v = 0.0;
    float leaf_v   = 0.0;

    // Shift specimen slightly up, bird perching mid-frame
    uv.y -= 0.02;

    // ======================== BRANCH ========================
    // Diagonal branch from lower-left to mid-right
    {
        // Tapered branch — approximated as thick line with taper
        vec2 ba = vec2(-0.55, -0.38), bb = vec2(0.55, -0.30);
        vec2 pa = uv - ba, bab = bb - ba;
        float ht = clamp(dot(pa, bab)/dot(bab,bab), 0.0, 1.0);
        float branch_r = mix(0.025, 0.015, ht);
        float bd = length(pa - bab*ht) - branch_r;
        branch_v += smoothstep(0.0, -0.005, bd);
        ink += smoothstep(0.005, 0.0, abs(bd)) * u_line_weight_primary * 0.8;

        // Bark texture — fine horizontal lines
        float bark = featherLines(uv * 8.0, 0.18, 0.1);
        ink += bark * step(bd, 0.0) * u_line_weight_secondary * 0.25;
    }

    // Small twig stub going up
    {
        vec2 ta = vec2(0.12, -0.31), tb = vec2(0.18, -0.18);
        vec2 pa = uv - ta, tab = tb - ta;
        float ht = clamp(dot(pa, tab)/dot(tab,tab), 0.0, 1.0);
        float td = length(pa - tab*ht) - 0.007;
        branch_v += smoothstep(0.0, -0.003, td);
        ink += smoothstep(0.004, 0.0, abs(td)) * u_line_weight_secondary * 0.7;
    }

    // ======================== LEAVES ========================
    {
        vec2 lv = rot2(uv - vec2(-0.25, -0.25), 0.6);
        float ld = sdEllipse(lv, vec2(0.10, 0.04));
        leaf_v += smoothstep(0.0, -0.005, ld);
        ink    += smoothstep(0.006, 0.0, abs(ld)) * u_line_weight_secondary * 0.8;
        float mid = abs(rot2(uv - vec2(-0.25,-0.25), 0.6).y);
        ink += smoothstep(0.003, 0.0, mid) * step(ld, 0.0) * u_line_weight_secondary * 0.35;
    }
    {
        vec2 lv2 = rot2(uv - vec2(0.30, -0.22), -0.4);
        float ld2 = sdEllipse(lv2, vec2(0.09, 0.035));
        leaf_v += smoothstep(0.0, -0.005, ld2);
        ink    += smoothstep(0.006, 0.0, abs(ld2)) * u_line_weight_secondary * 0.8;
    }

    // ======================== CARDINAL BODY ========================
    // The bird sits on the branch, facing right

    // Body — horizontal egg-shape
    float body = sdEllipse(uv - vec2(-0.04, 0.0), vec2(0.16, 0.11));
    cardinal += smoothstep(0.0, -0.01, body);

    // Breast — slightly lower, wider
    float breast = sdEllipse(uv - vec2(-0.02, -0.03), vec2(0.13, 0.09));
    cardinal += smoothstep(0.0, -0.01, breast) * 0.4;

    // Tail — long, drooping to the left
    {
        vec2 tv = rot2(uv - vec2(-0.17, -0.04), 0.25);
        float td = sdEllipse(tv, vec2(0.12, 0.035));
        cardinal += smoothstep(0.0, -0.01, td) * 0.9;
        ink += smoothstep(0.006, 0.0, abs(td)) * u_line_weight_primary * 0.75;
        // Tail feather lines
        ink += featherLines(uv * 12.0, 0.10, 0.25) * step(td, 0.0) * u_line_weight_secondary * 0.3;
    }

    // Wing — folded over body, slightly darker suggestion
    {
        vec2 wv = rot2(uv - vec2(-0.05, 0.02), 0.1);
        float wd = sdEllipse(wv, vec2(0.14, 0.07));
        cardinal += smoothstep(0.0, -0.01, wd) * 0.85;
        ink += smoothstep(0.007, 0.0, abs(wd)) * u_line_weight_secondary * 0.7;
        // Wing feather barbs
        ink += featherLines(uv * 14.0, 0.09, 0.1) * step(wd, 0.0) * u_line_weight_secondary * 0.22;
    }

    // Head — rounded
    float head = sdCircle(uv - vec2(0.12, 0.10), 0.085);
    cardinal += smoothstep(0.0, -0.01, head);

    // Crest — pointed upward (two curves approximated by small ellipse + tip)
    {
        vec2 cv = rot2(uv - vec2(0.10, 0.19), -0.3);
        float cd = sdEllipse(cv, vec2(0.06, 0.025));
        cardinal += smoothstep(0.0, -0.005, cd);
        ink += smoothstep(0.005, 0.0, abs(cd)) * u_line_weight_primary * 0.7;
    }

    // Beak — triangular wedge pointing right
    {
        vec2 bkv = uv - vec2(0.21, 0.11);
        float bk = max(abs(bkv.y) * 2.0 - (0.065 - bkv.x * 2.5), bkv.x - 0.065);
        float bk2 = max(abs(bkv.y) * 2.0 - (0.065 - bkv.x * 2.5), -bkv.x - 0.001);
        float beak_d = min(bk, bk2);
        // Upper mandible — orange-red
        cardinal += smoothstep(0.0, -0.002, bk2) * 0.9;
        ink += smoothstep(0.005, 0.0, abs(beak_d)) * u_line_weight_primary * 0.9;
    }

    // --- Mask (black face) ---
    {
        vec2 mv = uv - vec2(0.15, 0.08);
        float md = sdEllipse(mv, vec2(0.07, 0.05));
        mask_v += smoothstep(0.0, -0.005, md);
    }

    // Eye
    {
        float eye = sdCircle(uv - vec2(0.16, 0.12), 0.012);
        ink += smoothstep(0.004, 0.0, abs(eye)) * u_line_weight_primary;
        mask_v += smoothstep(0.0, -0.003, eye); // pupil
        // Highlight
        float hl = sdCircle(uv - vec2(0.163, 0.124), 0.004);
        cardinal += smoothstep(0.0, -0.001, hl) * 0.3; // slight highlight
    }

    // --- Feet / Toes ---
    // Zygodactyl toes on branch
    for (int i = 0; i < 3; i++) {
        float ta = -0.5 + float(i) * 0.25;
        vec2 tv = rot2(uv - vec2(-0.02 + float(i)*0.04, -0.09), ta);
        vec2 toe_a = vec2(0.0), toe_b = vec2(0.07, 0.0);
        float td = length(tv - toe_a - clamp(dot(tv - toe_a, toe_b - toe_a)/dot(toe_b-toe_a,toe_b-toe_a),0.0,1.0)*(toe_b-toe_a)) - 0.004;
        ink += smoothstep(0.003, 0.0, td) * u_line_weight_secondary * 0.8;
    }
    // Hind toe
    {
        vec2 tv2 = rot2(uv - vec2(-0.04, -0.10), -0.8);
        float td2 = length(tv2 - clamp(dot(tv2, vec2(0.06,0.0))/0.06/0.06,0.0,1.0)*vec2(0.06,0.0)) - 0.004;
        ink += smoothstep(0.003, 0.0, td2) * u_line_weight_secondary * 0.8;
    }

    // --- Body outline ---
    float body_all = smin(body, head, 0.03);
    ink += smoothstep(0.010, 0.0, abs(body_all)) * u_line_weight_primary;

    // Plumage detail lines on body
    ink += featherLines(uv * 12.0, 0.08, 0.0) * step(body_all, 0.0) * u_line_weight_secondary * 0.18;

    // --- Cast shadow ---
    float shadow = smoothstep(0.0, 0.2, smin(
        sdEllipse(uv - vec2(0.04, -0.12), vec2(0.22, 0.06)),
        sdCircle(uv - vec2(0.20, -0.10), 0.09), 0.05
    )) * 0.06;

    // --- Compose ---
    vec3 col = paper;
    col = mix(col, col * 0.94, shadow);
    col = mix(col, C_BRANCH,   clamp(branch_v, 0.0, 1.0) * u_wash_opacity * 0.9);
    col = mix(col, C_LEAF,     clamp(leaf_v, 0.0, 1.0) * u_wash_opacity);
    col = mix(col, C_CARDINAL, clamp(cardinal, 0.0, 1.0) * u_wash_opacity);
    col = mix(col, C_MASK,     clamp(mask_v, 0.0, 1.0));
    col = mix(col, C_INK, clamp(ink, 0.0, 1.0));

    // Label rule (dashed line below — text needs a texture atlas, so we
    // render a thin plate rule instead)
    float rule_y = -0.72;
    float rule = smoothstep(0.003, 0.0, abs(uv.y - rule_y)) * step(abs(uv.x), 0.28);
    col = mix(col, C_INK * 0.6, rule * 0.5);

    col += (hash21(gl_FragCoord.xy * 0.9) - 0.5) * 0.011;
    col = mix(col * 0.93, col, smoothstep(1.1, 0.4, length(uv)));

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
