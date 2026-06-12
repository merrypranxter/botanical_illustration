# Shader Parameters Reference

Complete parameter reference for the `botanical_illustration` GLSL shader collection.

## Shared Uniforms

Every shader in this collection receives the same uniform interface. Not every uniform is used by every shader — unused ones are silently ignored but still accepted.

```glsl
uniform float u_time;                   // elapsed seconds, drives animation
uniform vec2  u_resolution;             // viewport size in pixels
uniform float u_line_weight_primary;    // primary outline weight multiplier  [0.1–5.0]
uniform float u_line_weight_secondary;  // secondary / detail line weight     [0.1–3.0]
uniform float u_wash_opacity;           // watercolor / fill opacity          [0.0–1.0]
uniform float u_stipple_density;        // dots / hatching density            [5–120]
uniform float u_radial_symmetry;        // radial fold count (6/8/12/16…)     [1–24]
uniform float u_wet_edge_intensity;     // watercolor capillary bloom         [0.0–2.0]
uniform float u_paper_warmth;           // cream/wheat tint of ground         [0.0–1.0]
```

---

## Shader Catalogue

### 1. `haeckel_radial.frag.glsl`
**Regime:** `HAECKEL_RADIAL`  
**Specimen:** *Acantharia hexastyla*  
**Reference:** Ernst Haeckel, *Kunstformen der Natur*, Plate I, 1904

Three-specimen plate arrangement. Central specimen at 12-fold (or `u_radial_symmetry`) symmetry; flanking specimens at lower fold counts. Amber skeleton, cobalt wash, brown ink stipple on wheat paper.

| Uniform | Default | Notes |
|---------|---------|-------|
| `u_line_weight_primary` | 2.0 | Spine and core outline weight |
| `u_line_weight_secondary` | 0.75 | Lattice ring and strut weight |
| `u_wash_opacity` | 0.55 | Cobalt fill inside outer lattice |
| `u_stipple_density` | 60.0 | Dots on central sphere |
| `u_radial_symmetry` | 12.0 | Main specimen fold count |
| `u_paper_warmth` | 0.8 | Wheat paper intensity |

---

### 2. `haeckel_jellyfish.frag.glsl`
**Regime:** `HAECKEL_RADIAL`  
**Specimen:** *Medusa aurita* (Moon Jellyfish)  
**Reference:** Ernst Haeckel, *H.M.S. Challenger* Medusae Report, 1882

Radially symmetric bell with scalloped margin (lappets), radial canals, ring canal, and trailing tentacles. Translucent cobalt wash simulates the gelatinous mesoglea. Tentacles animate with `u_time`.

| Uniform | Default | Notes |
|---------|---------|-------|
| `u_radial_symmetry` | 8.0 | Bell fold count (4/8/16) |
| `u_wash_opacity` | 0.65 | Bell translucency |
| `u_wet_edge_intensity` | 0.5 | Bloom at bell margin |

---

### 3. `haeckel_diatom.frag.glsl`
**Regime:** `HAECKEL_RADIAL`  
**Specimen:** *Coscinodiscus concinnus*  
**Reference:** C.G. Ehrenberg, *Die Infusionsthierchen*, 1838

Circular diatom frustule (valve face view). 16-fold costae (primary ribs), hexagonal areolae pore lattice, central rosette, cingulum with transverse striae.

| Uniform | Default | Notes |
|---------|---------|-------|
| `u_radial_symmetry` | 16.0 | Number of primary costae |
| `u_stipple_density` | 40.0 | Areolae pore lattice density |
| `u_wash_opacity` | 0.45 | Silicate cobalt/amber wash |

---

### 4. `radiolaria_plate.frag.glsl`
**Regime:** `HAECKEL_RADIAL`  
**Specimen:** *Stephoidea* sp. (four specimens)  
**Reference:** Ernst Haeckel, *Kunstformen der Natur*, Plate 61, 1904

Formal plate arrangement with double-line border, four specimens in quadrants. Each specimen has progressively higher fold symmetry and structural complexity. The `u_radial_symmetry` value sets the baseline; specimens at ±2 and +4 folds surround it.

---

### 5. `watercolor_botanical.frag.glsl`
**Regime:** `WATERCOLOR_BOTANICAL`  
**Specimen:** *Rosa centifolia* (Cabbage Rose)  
**Reference:** Pierre-Joseph Redouté, *Les Roses*, Plate XXIV, 1820

Multi-layer rose: outer guard petals, middle petals, inner densely-packed petals, stamen rosette. FBM-displaced wash boundaries simulate capillary wet blooms.

| Uniform | Default | Notes |
|---------|---------|-------|
| `u_radial_symmetry` | 5.0 | Number of outer guard petals |
| `u_wash_opacity` | 0.85 | Overall petal wash intensity |
| `u_wet_edge_intensity` | 0.9 | Capillary bloom at petal edges |

---

### 6. `redoute_rose.frag.glsl`
**Regime:** `WATERCOLOR_BOTANICAL`  
**Specimen:** *Rosa gallica* (Apothecary's Rose)  
**Reference:** Pierre-Joseph Redouté, *Les Roses*, Plate XLVII, 1822

Single five-petaled rose with maximal softness. Petals have individual irregularity, notched tips, radial vein lines. Dense stamen cluster with golden-angle anther packing.

| Uniform | Default | Notes |
|---------|---------|-------|
| `u_radial_symmetry` | 5.0 | Petal count |
| `u_wet_edge_intensity` | 1.0 | Petal edge bloom; 0 = clean lines |

---

### 7. `audubon_field.frag.glsl`
**Regime:** `AUDUBON_FIELD`  
**Specimen:** *Cardinalis cardinalis* (Northern Cardinal, male)  
**Reference:** John James Audubon, *The Birds of America*, Plate CLVIII, 1831

Cardinal on diagonal branch with leaves. Scarlet body, black mask, prominent crest, zygodactyl feet. Feather barb lines on body and tail. Cast shadow on specimen ground.

| Uniform | Default | Notes |
|---------|---------|-------|
| `u_wash_opacity` | 0.9 | Bird and branch color intensity |
| `u_line_weight_primary` | 1.8 | Body outline weight |

---

### 8. `merian_insect.frag.glsl`
**Regime:** `MERIAN_INSECT_PLANT`  
**Specimen:** *Heliconius* sp. on *Passiflora*  
**Reference:** Maria Sibylla Merian, *Metamorphosis Insectorum Surinamensium*, 1705

Four-stage life cycle arranged around host plant. Stages: I egg cluster (top-left), II caterpillar larva (top-right), III chrysalis pupa (bottom-right), IV adult butterfly (bottom-left). Vine stem with phyllotaxis leaf placement and tendrils.

---

### 9. `cross_section.frag.glsl`
**Regime:** `CROSS_SECTION_PLATE`  
**Specimens:** *Citrus sinensis* (Orange) and *Rosa canina* (Dog Rose Hip)  
**Reference:** L.B. Van Houtte, *Flore des serres*, 1850

Two specimens side-by-side: orange hesperidium cross-section (segments, areolae vesicles, seeds) and rose hip longitudinal section (achene seeds, hypanthium tissue, sepal remnants).

| Uniform | Default | Notes |
|---------|---------|-------|
| `u_radial_symmetry` | 10.0 | Orange segment count |
| `u_stipple_density` | 50.0 | Juice vesicle hex lattice density |
| `u_paper_warmth` | 0.25 | Very clean/white scientific ground |

---

### 10. `specimen_clean.frag.glsl`
**Regime:** `SPECIMEN_CLEAN`  
**Specimen:** *Atropa belladonna* (Deadly Nightshade)  
**Reference:** William Woodville, *Medical Botany*, Plate XLII, 1792

Complete botanical specimen: root system below ground line, branching stem, ovate leaves with secondary venation, drooping bell flowers, glossy black berries. Near-white ground, near-black ink, maximum linework precision.

---

## Color Palettes

```glsl
// HAECKEL_PLATE
#F5DEB3  // wheat paper
#DAA520  // amber skeleton
#8B4513  // brown ink
#4169E1  // cobalt
#228B22  // botanical green

// AUDUBON_BIRD
#8B4513  // earth brown
#228B22  // leaf green
#FF4500  // cardinal red
#87CEEB  // sky blue
#FFF8DC  // cornsilk

// REDOUTE_ROSE
#FFB6C1  // light pink
#FF69B4  // hot pink
#228B22  // leaf green
#90EE90  // light green
#FFFACD  // lemon chiffon

// MERIAN_INSECT
#DAA520  // gold
#8B0000  // deep red
#006400  // dark green
#F5DEB3  // wheat

// SPECIMEN_CLEAN
#FFFEF5  // near white
#1C1C1C  // ink black
#8B4513  // warm brown
#4169E1  // cobalt wash
```

---

## Mathematical Primitives Used

### Signed Distance Functions (SDF)

```glsl
float sdCircle(vec2 p, float r)                    // circle
float sdEllipse(vec2 p, vec2 ab)                   // axis-aligned ellipse (exact)
float sdSegment(vec2 p, vec2 a, vec2 b)            // line segment
float sdPetal(vec2 p, float length, float width)   // elongated petal shape
```

### Radial Symmetry

```glsl
// Fold UV into a single sector; returns symmetric coordinate
vec2 radialFold(vec2 uv, float n) {
    float a = atan(uv.y, uv.x);
    float s = TAU / n;
    float fa = mod(a, s);
    if (fa > s * 0.5) fa = s - fa;
    return vec2(cos(fa), sin(fa)) * length(uv);
}
```

### Noise / Texture

```glsl
float hash21(vec2 p)    // pseudo-random [0,1]
float noise21(vec2 p)   // value noise
float fbm(vec2 p)       // fractional Brownian motion (5 octaves)
float stipple(vec2 p, float density, float darkness)  // Poisson-approximate stipple
float hexDist(vec2 p)   // distance to nearest hexagonal lattice center
```

### Watercolor Wet Edge

The wet edge bloom is computed by:
1. Displacing the color region SDF boundary by `fbm(uv * scale + seed) * amplitude`
2. Sampling a narrow band at the displaced boundary
3. Attenuating outward with `smoothstep` × `u_wet_edge_intensity`
4. Adding warm (red-orange) color shift to simulate capillary concentration

---

## Usage with Three.js

```js
import frag from './shaders/haeckel_radial.frag.glsl?raw';
import * as THREE from 'three';

const material = new THREE.ShaderMaterial({
  vertexShader: `void main() { gl_Position = vec4(position, 1.0); }`,
  fragmentShader: frag,
  uniforms: {
    u_time:                  { value: 0 },
    u_resolution:            { value: new THREE.Vector2(w, h) },
    u_line_weight_primary:   { value: 2.0 },
    u_line_weight_secondary: { value: 0.75 },
    u_wash_opacity:          { value: 0.55 },
    u_stipple_density:       { value: 60.0 },
    u_radial_symmetry:       { value: 12.0 },
    u_wet_edge_intensity:    { value: 0.0 },
    u_paper_warmth:          { value: 0.8 },
  },
});
```

---

## Ecosystem

This repository is a style reference for the [merrypranxter](https://github.com/merrypranxter) generative art pipeline.

- **RepoScripter2**: context source (`reposcripter2: true` in `context.manifest.json`)
- **ShaderForge**: style module (`shaderforge: true`)
- **Compatible with**: `fungi`, `diatomic`, `minerals`, `crystalline`, `morphogenesis`

See `botanical_illustration/context.manifest.json` for machine-readable metadata.
