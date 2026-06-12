# botanical_illustration

Ernst Haeckel drew radiolaria like they were cathedrals. he was correct.

Scientific botanical and natural history illustration — Audubon's birds, Haeckel's radiolaria and jellyfish, Maria Sibylla Merian's insects and plants, Pierre-Joseph Redouté's roses. The visual grammar of scientific observation made beautiful by people who believed those were not different things.

## What This Is

Visual language for scientific illustration as generative art — the linework system, the watercolor wash technique, the specimen-on-white compositional logic, and the obsessive structural detail of life drawn to be understood.

## Visual DNA

**Core signatures:**
- Specimen isolation: single subject on white/cream ground, no context, pure form
- Linework hierarchy: primary outline (1.5–2px), secondary detail (0.75px), tertiary texture (0.25px)
- Watercolor wash: transparent color layers, wet-edge blooms, no gouache-style opacity
- Shadow: soft cast shadow at right angle, very faint, implies physical object
- Root/cross-section: often shows underground portion AND above-ground, or sectional cut
- Label: Latin binomial in italic serif, handwritten numerals for plate references
- Symmetry observation: radial symmetry in many subjects (Haeckel's radiolaria, flowers)
- Color naturalism: observed local color, slightly idealized — no chromatic exaggeration

**Haeckel signatures (Art Forms in Nature):**
- Extreme radial symmetry: 6, 8, 12, 16-fold radial organization
- Structural abstraction: the jellyfish IS a radial diagram
- Gold/amber for skeletal structures
- Ink stipple for surface texture, with cross-hatch for deep shadow
- Multiple specimens per plate in geometric arrangement

**Color palettes:**
- `HAECKEL_PLATE`: `#F5DEB3` (wheat paper), `#DAA520` (amber skeleton), `#8B4513` (brown ink), `#4169E1` (cobalt), `#228B22` (botanical green)
- `AUDUBON_BIRD`: `#8B4513` (earth brown), `#228B22` (leaf green), `#FF4500` (cardinal red), `#87CEEB` (sky), `#FFF8DC` (cornsilk)
- `REDOUTE_ROSE`: `#FFB6C1` (light pink), `#FF69B4` (hot pink), `#228B22` (leaf), `#90EE90` (light green), `#FFFACD` (lemon chiffon)
- `MERIAN_INSECT`: `#DAA520` (gold), `#8B0000` (deep red), `#006400` (dark green), `#F5DEB3` (wheat)
- `SPECIMEN_CLEAN`: `#FFFEF5` (near white), `#1C1C1C` (ink black), `#8B4513` (warm brown), `#4169E1` (cobalt wash)

## Aesthetic Regimes

### `HAECKEL_RADIAL` — Art Forms in Nature
Extreme radial symmetry. Stipple texture. Amber/cobalt/earth. Multiple specimens in geometric plate arrangement. Biological forms as architectural drawing.

### `AUDUBON_FIELD` — Bird in natural context
Single bird specimen, full body. Accurate plumage. Perched branch with leaves. Latin name below. Everything is observed, nothing is invented.

### `WATERCOLOR_BOTANICAL` — Redouté floral
Single flower or plant. Soft watercolor washes. Wet edge blooms. Root system sometimes visible. Delicate linework. Cream ground.

### `MERIAN_INSECT_PLANT` — Insect on host plant
Plant with insect life cycle stages: egg, larva, pupa, adult. Each stage labeled. Scientific and beautiful simultaneously.

### `CROSS_SECTION_PLATE` — Internal structure exposed
Fruit cut in half. Flower dissected. Seed structure revealed. Clean white ground. Heavy accurate linework. Educational and aesthetic.

## Shader Parameters

```glsl
uniform float u_line_weight_primary;    // primary outline weight
uniform float u_line_weight_secondary;  // secondary detail weight
uniform float u_wash_opacity;           // watercolor wash translucency
uniform float u_stipple_density;        // Haeckel-style stipple
uniform float u_radial_symmetry;        // 0=none, 6/8/12/16 fold
uniform float u_wet_edge_intensity;     // watercolor bloom at edges
uniform float u_paper_warmth;           // cream tint of paper ground
```

## Ecosystem

Part of the [merrypranxter](https://github.com/merrypranxter) generative art pipeline.
RepoScripter2 context source. ShaderForge style module.

Use with: `fungi`, `diatomic`, `minerals`, `crystalline`, `morphogenesis`
