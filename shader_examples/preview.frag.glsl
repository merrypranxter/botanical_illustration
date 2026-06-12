// Botanical Illustration — Fragment Shader Stub
// Radial symmetry, stipple, watercolor wash, linework, cross-hatch, wet edge

precision highp float;
uniform float u_time;
uniform vec2 u_resolution;
uniform float u_line_weight_primary;
uniform float u_line_weight_secondary;
uniform float u_wash_opacity;
uniform float u_stipple_density;
uniform float u_radial_symmetry;
uniform float u_wet_edge_intensity;
uniform float u_paper_warmth;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5); }

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv = uv * 2.0 - 1.0;
    uv.x *= u_resolution.x / u_resolution.y;
    
    // Warm paper
    vec3 paper = mix(vec3(1.0), vec3(1.0, 0.95, 0.85), u_paper_warmth);
    
    // Radial symmetry
    float r = length(uv);
    float angle = atan(uv.y, uv.x);
    float n = u_radial_symmetry;
    float sym_angle = mod(angle + 3.14159, 2.0 * 3.14159 / n);
    vec2 sym_uv = vec2(r * cos(sym_angle), r * sin(sym_angle));
    
    // Stipple texture
    float stipple = 0.0;
    for (int i = 0; i < 4; i++) {
        vec2 off = vec2(float(i) * 0.3, float(i) * 0.5);
        stipple += hash(floor((uv + off) * u_stipple_density)) * 0.25;
    }
    
    // Watercolor wash
    float wash = smoothstep(0.5, 0.0, r) * u_wash_opacity;
    vec3 wash_col = mix(vec3(0.2, 0.6, 0.2), vec3(0.8, 0.9, 0.5), r * 2.0);
    
    // Linework
    float outline = smoothstep(0.3, 0.0, abs(r - 0.4)) * u_line_weight_primary;
    float detail = smoothstep(0.2, 0.0, abs(r - 0.2)) * u_line_weight_secondary;
    
    // Wet edge bloom
    float edge = smoothstep(0.05, 0.0, abs(r - 0.4)) * u_wet_edge_intensity;
    
    vec3 col = paper;
    col += stipple * 0.1;
    col = mix(col, wash_col, wash);
    col = mix(col, vec3(0.2, 0.15, 0.1), outline);
    col = mix(col, vec3(0.3, 0.25, 0.2), detail);
    col += vec3(0.1, 0.05, 0.0) * edge;
    
    gl_FragColor = vec4(col, 1.0);
}
