// botanical_illustration — shader gallery
// Scientific natural history illustration as generative art
// Haeckel | Audubon | Redouté | Merian
// Three.js + WebGL2 + GLSL | Vite

import * as THREE from 'three';

import haeckelRadialFrag  from './shaders/haeckel_radial.frag.glsl?raw';
import haeckelJellyfishFrag from './shaders/haeckel_jellyfish.frag.glsl?raw';
import haeckelDiatomFrag  from './shaders/haeckel_diatom.frag.glsl?raw';
import radiolariaPlateFrag from './shaders/radiolaria_plate.frag.glsl?raw';
import watercolorFrag     from './shaders/watercolor_botanical.frag.glsl?raw';
import redouteRoseFrag    from './shaders/redoute_rose.frag.glsl?raw';
import audubonFrag        from './shaders/audubon_field.frag.glsl?raw';
import merianFrag         from './shaders/merian_insect.frag.glsl?raw';
import crossSectionFrag   from './shaders/cross_section.frag.glsl?raw';
import specimenCleanFrag  from './shaders/specimen_clean.frag.glsl?raw';

// Vertex shader — full-screen quad
const VERTEX = `void main() { gl_Position = vec4(position, 1.0); }`;

// Shader definitions — metadata + uniform defaults
const SHADERS = [
  {
    name: 'HAECKEL_RADIAL',
    latin: 'Acantharia hexastyla',
    ref: 'Plate I — Kunstformen der Natur, 1904',
    frag: haeckelRadialFrag,
    uniforms: {
      u_line_weight_primary:   2.0,
      u_line_weight_secondary: 0.75,
      u_wash_opacity:          0.55,
      u_stipple_density:       60.0,
      u_radial_symmetry:       12.0,
      u_wet_edge_intensity:    0.0,
      u_paper_warmth:          0.8,
    },
  },
  {
    name: 'HAECKEL_JELLYFISH',
    latin: 'Medusa aurita',
    ref: 'H.M.S. Challenger Report, 1882',
    frag: haeckelJellyfishFrag,
    uniforms: {
      u_line_weight_primary:   1.8,
      u_line_weight_secondary: 0.7,
      u_wash_opacity:          0.65,
      u_stipple_density:       50.0,
      u_radial_symmetry:       8.0,
      u_wet_edge_intensity:    0.5,
      u_paper_warmth:          0.7,
    },
  },
  {
    name: 'HAECKEL_DIATOM',
    latin: 'Coscinodiscus concinnus',
    ref: 'Bacillariophyta — Ehrenberg, 1838',
    frag: haeckelDiatomFrag,
    uniforms: {
      u_line_weight_primary:   2.0,
      u_line_weight_secondary: 0.8,
      u_wash_opacity:          0.45,
      u_stipple_density:       40.0,
      u_radial_symmetry:       16.0,
      u_wet_edge_intensity:    0.0,
      u_paper_warmth:          0.7,
    },
  },
  {
    name: 'RADIOLARIA_PLATE',
    latin: 'Stephoidea quad-plate',
    ref: 'Plate 61 — Kunstformen der Natur, 1904',
    frag: radiolariaPlateFrag,
    uniforms: {
      u_line_weight_primary:   2.0,
      u_line_weight_secondary: 0.65,
      u_wash_opacity:          0.5,
      u_stipple_density:       55.0,
      u_radial_symmetry:       12.0,
      u_wet_edge_intensity:    0.0,
      u_paper_warmth:          0.85,
    },
  },
  {
    name: 'WATERCOLOR_BOTANICAL',
    latin: 'Rosa centifolia',
    ref: 'Les Roses, Plate XXIV — Redouté, 1820',
    frag: watercolorFrag,
    uniforms: {
      u_line_weight_primary:   1.5,
      u_line_weight_secondary: 0.6,
      u_wash_opacity:          0.85,
      u_stipple_density:       40.0,
      u_radial_symmetry:       5.0,
      u_wet_edge_intensity:    0.9,
      u_paper_warmth:          0.75,
    },
  },
  {
    name: 'REDOUTE_ROSE',
    latin: 'Rosa gallica',
    ref: 'Les Roses, Plate XLVII — Redouté, 1822',
    frag: redouteRoseFrag,
    uniforms: {
      u_line_weight_primary:   1.6,
      u_line_weight_secondary: 0.55,
      u_wash_opacity:          0.9,
      u_stipple_density:       35.0,
      u_radial_symmetry:       5.0,
      u_wet_edge_intensity:    1.0,
      u_paper_warmth:          0.8,
    },
  },
  {
    name: 'AUDUBON_FIELD',
    latin: 'Cardinalis cardinalis',
    ref: 'Plate CLVIII — Birds of America, 1831',
    frag: audubonFrag,
    uniforms: {
      u_line_weight_primary:   1.8,
      u_line_weight_secondary: 0.65,
      u_wash_opacity:          0.9,
      u_stipple_density:       45.0,
      u_radial_symmetry:       1.0,
      u_wet_edge_intensity:    0.3,
      u_paper_warmth:          0.7,
    },
  },
  {
    name: 'MERIAN_INSECT_PLANT',
    latin: 'Heliconius on Passiflora',
    ref: 'Metamorphosis Insectorum Surinamensium — Merian, 1705',
    frag: merianFrag,
    uniforms: {
      u_line_weight_primary:   1.7,
      u_line_weight_secondary: 0.65,
      u_wash_opacity:          0.85,
      u_stipple_density:       40.0,
      u_radial_symmetry:       5.0,
      u_wet_edge_intensity:    0.4,
      u_paper_warmth:          0.75,
    },
  },
  {
    name: 'CROSS_SECTION_PLATE',
    latin: 'Citrus sinensis & Rosa canina',
    ref: 'Flore des serres — Van Houtte, 1850',
    frag: crossSectionFrag,
    uniforms: {
      u_line_weight_primary:   2.2,
      u_line_weight_secondary: 0.85,
      u_wash_opacity:          0.7,
      u_stipple_density:       50.0,
      u_radial_symmetry:       10.0,
      u_wet_edge_intensity:    0.0,
      u_paper_warmth:          0.25,
    },
  },
  {
    name: 'SPECIMEN_CLEAN',
    latin: 'Atropa belladonna',
    ref: 'Medical Botany, Plate XLII — Woodville, 1792',
    frag: specimenCleanFrag,
    uniforms: {
      u_line_weight_primary:   2.0,
      u_line_weight_secondary: 0.7,
      u_wash_opacity:          0.75,
      u_stipple_density:       40.0,
      u_radial_symmetry:       5.0,
      u_wet_edge_intensity:    0.2,
      u_paper_warmth:          0.3,
    },
  },
];

// --- Renderer setup ---
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.insertBefore(renderer.domElement, document.body.firstChild);

const scene  = new THREE.Scene();
const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
const geo    = new THREE.PlaneGeometry(2, 2);

// Build shared uniform object (values updated per shader)
function makeUniforms(shaderDef) {
  const u = {
    u_time:       { value: 0 },
    u_resolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
  };
  for (const [key, val] of Object.entries(shaderDef.uniforms)) {
    u[key] = { value: val };
  }
  return u;
}

// Pre-compile all materials
const materials = SHADERS.map(def => new THREE.ShaderMaterial({
  vertexShader:   VERTEX,
  fragmentShader: def.frag,
  uniforms:       makeUniforms(def),
}));

const mesh = new THREE.Mesh(geo, materials[0]);
scene.add(mesh);

// --- State ---
let currentIndex = 0;
let paused = false;
let time = 0;
let lastTime = performance.now();

// --- UI elements ---
const regimeEl  = document.getElementById('regime-name');
const latinEl   = document.getElementById('latin-name');
const plateEl   = document.getElementById('plate-ref');
const indexEl   = document.getElementById('shader-index');
const paramList = document.getElementById('params-list');

const UNIFORM_LABELS = {
  u_line_weight_primary:   'line.primary',
  u_line_weight_secondary: 'line.secondary',
  u_wash_opacity:          'wash.opacity',
  u_stipple_density:       'stipple.density',
  u_radial_symmetry:       'radial.fold',
  u_wet_edge_intensity:    'wet.edge',
  u_paper_warmth:          'paper.warmth',
};

const UNIFORM_RANGES = {
  u_line_weight_primary:   [0.1, 5.0, 0.1],
  u_line_weight_secondary: [0.1, 3.0, 0.1],
  u_wash_opacity:          [0.0, 1.0, 0.01],
  u_stipple_density:       [5.0, 120.0, 1.0],
  u_radial_symmetry:       [1.0, 24.0, 1.0],
  u_wet_edge_intensity:    [0.0, 2.0, 0.05],
  u_paper_warmth:          [0.0, 1.0, 0.01],
};

function rebuildParamPanel(idx) {
  const def  = SHADERS[idx];
  const mat  = materials[idx];
  paramList.innerHTML = '';

  for (const [key, label] of Object.entries(UNIFORM_LABELS)) {
    const row = document.createElement('div');
    row.className = 'param-row';

    const lbl = document.createElement('label');
    lbl.textContent = label;

    const [min, max, step] = UNIFORM_RANGES[key];
    const input = document.createElement('input');
    input.type  = 'range';
    input.min   = min;
    input.max   = max;
    input.step  = step;
    input.value = mat.uniforms[key].value;

    const val = document.createElement('span');
    val.className = 'val';
    val.textContent = (+input.value).toFixed(input.step < 0.1 ? 2 : 0);

    input.addEventListener('input', () => {
      mat.uniforms[key].value = parseFloat(input.value);
      val.textContent = (+input.value).toFixed(input.step < 0.1 ? 2 : 0);
    });

    row.appendChild(lbl);
    row.appendChild(input);
    row.appendChild(val);
    paramList.appendChild(row);
  }
}

function setShader(idx) {
  currentIndex = ((idx % SHADERS.length) + SHADERS.length) % SHADERS.length;
  const def = SHADERS[currentIndex];
  mesh.material = materials[currentIndex];

  regimeEl.textContent = def.name;
  latinEl.textContent  = def.latin;
  plateEl.textContent  = def.ref;
  indexEl.textContent  = String(currentIndex + 1).padStart(2, '0') + ' / ' + String(SHADERS.length).padStart(2, '0');

  rebuildParamPanel(currentIndex);
}

// Reset uniforms to defaults
function resetUniforms() {
  const def = SHADERS[currentIndex];
  const mat = materials[currentIndex];
  for (const [key, val] of Object.entries(def.uniforms)) {
    mat.uniforms[key].value = val;
  }
  rebuildParamPanel(currentIndex);
}

// --- Navigation ---
document.getElementById('btn-prev').addEventListener('click', () => setShader(currentIndex - 1));
document.getElementById('btn-next').addEventListener('click', () => setShader(currentIndex + 1));

document.addEventListener('keydown', e => {
  if (e.key === 'ArrowRight' || e.key === 'l') setShader(currentIndex + 1);
  if (e.key === 'ArrowLeft'  || e.key === 'h') setShader(currentIndex - 1);
  if (e.key === ' ') { paused = !paused; e.preventDefault(); }
  if (e.key === 'r' || e.key === 'R') resetUniforms();
  if (e.key >= '1' && e.key <= '9') setShader(parseInt(e.key) - 1);
});

// --- Resize ---
window.addEventListener('resize', () => {
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  for (const mat of materials) {
    mat.uniforms.u_resolution.value.set(window.innerWidth, window.innerHeight);
  }
});

// --- Render loop ---
function animate(ts) {
  requestAnimationFrame(animate);
  const dt = (ts - lastTime) * 0.001;
  lastTime = ts;
  if (!paused) time += dt;

  const mat = materials[currentIndex];
  mat.uniforms.u_time.value = time;

  renderer.render(scene, camera);
}

// --- Init ---
setShader(0);
requestAnimationFrame(animate);
