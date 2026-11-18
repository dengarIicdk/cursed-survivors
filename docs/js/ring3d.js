/* The hero scene: the closing ring, built out of three.js primitives.
   Everything here is procedural — no models, no textures on disk. */

import * as THREE from "three";

const canvas = document.getElementById("ring3d");
const stage = canvas ? canvas.parentElement : null;
const forceMotion = new URLSearchParams(location.search).has("motion");
const reduce = !forceMotion && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

if (canvas && stage) {
  const RING_MEMBERS = 44;
  const FOG = 0x0a0611;

  const wantShot = new URLSearchParams(location.search).has("shot");
  const renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: true,
    powerPreference: "high-performance",
    preserveDrawingBuffer: wantShot,
  });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setClearColor(FOG, 1);
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.45;

  const scene = new THREE.Scene();
  scene.fog = new THREE.FogExp2(FOG, 0.038);

  const camera = new THREE.PerspectiveCamera(46, 1, 0.1, 120);
  camera.position.set(0, 3.25, 9.6);

  // ---------------------------------------------------------------- lights
  scene.add(new THREE.AmbientLight(0x4d3a6a, 1.7));

  const moon = new THREE.DirectionalLight(0xc2b0f5, 3.0);
  moon.position.set(-8, 9, 9);
  scene.add(moon);

  const pitLight = new THREE.PointLight(0xd8455c, 55, 30, 2);
  pitLight.position.set(0, 1.1, 0);
  scene.add(pitLight);

  const beam = new THREE.SpotLight(0xcdb9ff, 60, 26, 0.55, 0.7, 1.6);
  beam.position.set(0, 13, 3.5);
  beam.target.position.set(0, 0, 0);
  scene.add(beam, beam.target);

  const rimLight = new THREE.PointLight(0x7a4fbb, 40, 34, 2);
  rimLight.position.set(0, 4.5, -9);
  scene.add(rimLight);


  // a painted arena floor: concentric rings, moss, scattered pebbles
  function groundTexture() {
    const size = 512;
    const c = document.createElement("canvas");
    c.width = c.height = size;
    const g = c.getContext("2d");
    g.fillStyle = "#140d1c";
    g.fillRect(0, 0, size, size);
    for (let i = 0; i < 2600; i++) {
      const x = Math.random() * size;
      const y = Math.random() * size;
      const a = 0.02 + Math.random() * 0.06;
      g.fillStyle = Math.random() > 0.7 ? `rgba(120,90,150,${a})` : `rgba(30,20,44,${a * 2})`;
      g.fillRect(x, y, 1 + Math.random() * 2, 1 + Math.random() * 2);
    }
    g.strokeStyle = "rgba(168,126,210,0.34)";
    for (let r = 60; r < size / 2; r += 46) {
      g.beginPath();
      g.arc(size / 2, size / 2, r, 0, Math.PI * 2);
      g.lineWidth = 1.2;
      g.stroke();
    }
    g.strokeStyle = "rgba(216,69,92,0.22)";
    g.beginPath();
    g.arc(size / 2, size / 2, size * 0.5 - 2, 0, Math.PI * 2);
    g.lineWidth = 6;
    g.stroke();
    const tex = new THREE.CanvasTexture(c);
    tex.colorSpace = THREE.SRGBColorSpace;
    return tex;
  }

  // ----------------------------------------------------------------- floor
  const floor = new THREE.Mesh(
    new THREE.CircleGeometry(34, 64),
    new THREE.MeshStandardMaterial({
      color: 0x2a2036,
      map: groundTexture(),
      roughness: 0.94,
      metalness: 0.04,
    })
  );
  floor.rotation.x = -Math.PI / 2;
  scene.add(floor);

  // a warm pool of light under the figure, drawn as a soft canvas gradient
  function glowTexture(inner, outer) {
    const size = 256;
    const c = document.createElement("canvas");
    c.width = c.height = size;
    const g = c.getContext("2d");
    const grad = g.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
    grad.addColorStop(0, inner);
    grad.addColorStop(1, outer);
    g.fillStyle = grad;
    g.fillRect(0, 0, size, size);
    const tex = new THREE.CanvasTexture(c);
    tex.colorSpace = THREE.SRGBColorSpace;
    return tex;
  }

  const pool = new THREE.Mesh(
    new THREE.PlaneGeometry(16, 16),
    new THREE.MeshBasicMaterial({
      map: glowTexture("rgba(216,69,92,0.38)", "rgba(216,69,92,0)"),
      transparent: true,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
    })
  );
  pool.rotation.x = -Math.PI / 2;
  pool.position.y = 0.02;
  scene.add(pool);

  // ------------------------------------------------------------- the figure
  const figure = new THREE.Group();
  figure.position.y = 0.05;
  scene.add(figure);

  const cloakMat = new THREE.MeshStandardMaterial({
    color: 0x1b1029,
    roughness: 0.82,
    metalness: 0.08,
    emissive: 0x120a1e,
  });

  const cloak = new THREE.Mesh(new THREE.ConeGeometry(0.95, 2.35, 14, 1, true), cloakMat);
  cloak.position.y = 1.18;
  cloak.material.side = THREE.DoubleSide;
  figure.add(cloak);

  const hood = new THREE.Mesh(new THREE.SphereGeometry(0.62, 18, 14), cloakMat);
  hood.scale.set(1, 1.05, 0.95);
  hood.position.y = 2.12;
  figure.add(hood);

  // the void where a face should be
  const faceVoid = new THREE.Mesh(
    new THREE.SphereGeometry(0.36, 14, 12),
    new THREE.MeshBasicMaterial({ color: 0x05030a })
  );
  faceVoid.position.set(0, 2.06, 0.34);
  figure.add(faceVoid);

  const eyeMat = new THREE.MeshBasicMaterial({ color: 0xff3e48 });
  const eyeGeo = new THREE.SphereGeometry(0.098, 12, 10);
  const eyeL = new THREE.Mesh(eyeGeo, eyeMat);
  const eyeR = new THREE.Mesh(eyeGeo, eyeMat);
  eyeL.position.set(-0.15, 2.09, 0.63);
  eyeR.position.set(0.15, 2.09, 0.63);
  figure.add(eyeL, eyeR);

  // a pin of red light inside the hood so the eyes light the face
  const eyeLight = new THREE.PointLight(0xff3242, 2.2, 2.4, 2);
  eyeLight.position.set(0, 2.05, 0.7);
  figure.add(eyeLight);

  const eyeGlowMap = glowTexture("rgba(255,70,80,0.95)", "rgba(255,70,80,0)");
  const eyeGlows = [];
  for (const sx of [-1, 1]) {
    const g = new THREE.Sprite(
      new THREE.SpriteMaterial({
        map: eyeGlowMap,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
        transparent: true,
        opacity: 0.85,
      })
    );
    g.scale.set(0.85, 0.85, 1);
    g.position.set(sx * 0.15, 2.09, 0.66);
    eyeGlows.push(g);
    figure.add(g);
  }

  // a faint aura that keeps the silhouette from sinking into the background
  const aura = new THREE.Sprite(
    new THREE.SpriteMaterial({
      map: glowTexture("rgba(150,90,210,0.35)", "rgba(150,90,210,0)"),
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      transparent: true,
    })
  );
  aura.scale.set(6.5, 7.5, 1);
  aura.position.set(0, 1.6, -0.6);
  figure.add(aura);

  // ---------------------------------------------------------------- the ring
  const ringGroup = new THREE.Group();
  scene.add(ringGroup);

  const stoneGeo = new THREE.BoxGeometry(0.62, 1.0, 0.34);
  const stoneMat = new THREE.MeshStandardMaterial({
    color: 0x3b3149,
    roughness: 0.86,
    metalness: 0.06,
    emissive: 0x34101c,
    emissiveIntensity: 0.9,
  });
  const crossMat = new THREE.MeshStandardMaterial({ color: 0x463a56, roughness: 0.85 });
  const stoneTones = [
    stoneMat,
    new THREE.MeshStandardMaterial({ color: 0x4a3c5c, roughness: 0.8, metalness: 0.08, emissive: 0x2a0e18 }),
    new THREE.MeshStandardMaterial({ color: 0x332838, roughness: 0.92, emissive: 0x3c1220 }),
  ];

  const stones = [];
  const angleStep = (Math.PI * 2) / RING_MEMBERS;
  for (let i = 0; i < RING_MEMBERS; i++) {
    const stone = new THREE.Mesh(stoneGeo, stoneTones[i % stoneTones.length]);
    const height = 0.75 + Math.random() * 1.15;
    stone.scale.set(0.85 + Math.random() * 0.5, height, 0.85 + Math.random() * 0.4);
    stone.userData.angle = i * angleStep + (Math.random() - 0.5) * 0.05;
    stone.userData.height = height;
    if (i % 4 === 1) {
      // a lopsided crossbar here and there, so the ring reads as grave stones
      const bar = new THREE.Mesh(new THREE.BoxGeometry(0.62, 0.12, 0.14), crossMat);
      bar.position.set(0, 0.66, 0.19);
      bar.scale.set(1.5 / (0.85 + 0.5), 1, 1);
      stone.add(bar);
    }
    stones.push(stone);
    ringGroup.add(stone);
  }

  // a ground mark that only shows while the ring is closing
  const markMat = new THREE.MeshBasicMaterial({
    color: 0xd8455c,
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    side: THREE.DoubleSide,
    depthWrite: false,
  });
  const mark = new THREE.Mesh(new THREE.RingGeometry(0.98, 1, 96, 1, 0, Math.PI * 2), markMat);
  mark.rotation.x = -Math.PI / 2;
  mark.position.y = 0.03;
  scene.add(mark);

  // --------------------------------------------------------------- embers
  const EMBER_COUNT = 520;
  const emberPos = new Float32Array(EMBER_COUNT * 3);
  const emberSeed = new Float32Array(EMBER_COUNT * 2);
  for (let i = 0; i < EMBER_COUNT; i++) {
    const r = 2 + Math.random() * 13;
    const a = Math.random() * Math.PI * 2;
    emberPos[i * 3] = Math.cos(a) * r;
    emberPos[i * 3 + 1] = Math.random() * 11;
    emberPos[i * 3 + 2] = Math.sin(a) * r;
    emberSeed[i * 2] = 0.25 + Math.random() * 0.85;
    emberSeed[i * 2 + 1] = Math.random() * Math.PI * 2;
  }
  const emberGeo = new THREE.BufferGeometry();
  emberGeo.setAttribute("position", new THREE.BufferAttribute(emberPos, 3));
  const emberMat = new THREE.PointsMaterial({
    color: 0xffa060,
    size: 0.15,
    map: glowTexture("rgba(255,255,255,1)", "rgba(255,200,150,0)"),
    transparent: true,
    opacity: 0.95,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    sizeAttenuation: true,
  });
  const embers = new THREE.Points(emberGeo, emberMat);
  scene.add(embers);

  // ------------------------------------------------------------- animation
  const state = {
    closeT: 0,
    phase: "close",   // close → burst → open
    timer: 0,
    pointer: new THREE.Vector2(0, 0),
    targetPointer: new THREE.Vector2(0, 0),
    visible: true,
    running: false,
  };

  const CLOSE_TIME = 11.0;
  const HOLD_TIME = 1.6;
  const OPEN_TIME = 4.2;
  const START_RADIUS = 6.4;
  const END_RADIUS = 1.95;

  function smoothstep(x) {
    return x * x * (3 - 2 * x);
  }

  function radiusAt(t) {
    return START_RADIUS + (END_RADIUS - START_RADIUS) * smoothstep(t);
  }

  function placeStones(radius) {
    for (const stone of stones) {
      const a = stone.userData.angle;
      stone.position.set(Math.cos(a) * radius, (stone.userData.height * 0.5), Math.sin(a) * radius);
      // the closer the wall, the more they lean in
      const lean = THREE.MathUtils.clamp(1 - radius / START_RADIUS, 0, 1) * 0.5;
      stone.rotation.set(lean * 0.5, -a + Math.PI / 2, 0);
    }
  }

  function resize() {
    const w = stage.clientWidth;
    const h = stage.clientHeight;
    if (!w || !h) return;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  }

  resize();
  placeStones(START_RADIUS);

  window.addEventListener("resize", resize);

  stage.addEventListener("pointermove", (e) => {
    const rect = stage.getBoundingClientRect();
    state.targetPointer.set(
      ((e.clientX - rect.left) / rect.width) * 2 - 1,
      ((e.clientY - rect.top) / rect.height) * 2 - 1
    );
  });

  const io = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      state.visible = entry.isIntersecting;
      if (state.visible) start();
    }
  }, { threshold: 0.05 });
  io.observe(stage);

  function start() {
    if (state.running) return;
    state.running = true;
    renderer.setAnimationLoop(tick);
  }

  const clock = new THREE.Clock();
  let burst = null;

  function tick() {
    const dt = Math.min(clock.getDelta(), 0.05);
    const t = clock.elapsedTime;

    if (!state.visible || document.hidden) return;

    // the ring breathes: closes, holds, snaps open
    state.timer += dt;
    if (state.phase === "close") {
      state.closeT = Math.min(1, state.timer / CLOSE_TIME);
      if (state.timer >= CLOSE_TIME) {
        state.phase = "hold";
        state.timer = 0;
      }
    } else if (state.phase === "hold") {
      state.closeT = 1;
      if (state.timer >= HOLD_TIME) {
        state.phase = "open";
        state.timer = 0;
        burst = { life: 0, max: 0.9 };
      }
    } else {
      const k = Math.min(1, state.timer / OPEN_TIME);
      state.closeT = 1 - smoothstep(k);
      if (state.timer >= OPEN_TIME) {
        state.phase = "close";
        state.closeT = 0;
        state.timer = 0;
      }
    }

    const radius = radiusAt(state.closeT);
    placeStones(radius);

    const closeness = 1 - (radius - END_RADIUS) / (START_RADIUS - END_RADIUS);
    for (const tone of stoneTones) {
      tone.emissiveIntensity = 0.6 + closeness * 2.2;
      tone.emissive.setHex(closeness > 0.55 ? 0x6a1420 : 0x2a0f18);
    }
    pitLight.intensity = 22 + closeness * 60;
    mark.scale.setScalar(radius);
    markMat.opacity = 0.05 + closeness * 0.32;
    pushBurst(dt);

    // the figure breathes and turns toward the pointer a little
    figure.position.y = 0.05 + Math.sin(t * 1.15) * 0.045;
    for (const glow of eyeGlows) glow.material.opacity = 0.72 + Math.sin(t * 2.4) * 0.14;

    // embers rise, sway, and wrap around
    const pos = emberGeo.attributes.position.array;
    for (let i = 0; i < EMBER_COUNT; i++) {
      pos[i * 3 + 1] += dt * emberSeed[i * 2] * 0.85;
      pos[i * 3] += Math.sin(t * 0.6 + emberSeed[i * 2 + 1]) * dt * 0.16;
      if (pos[i * 3 + 1] > 12) {
        pos[i * 3 + 1] = -0.2;
      }
    }
    emberGeo.attributes.position.needsUpdate = true;

    // camera: slow drift plus damped pointer parallax
    state.pointer.lerp(state.targetPointer, 1 - Math.pow(0.001, dt));
    camera.position.x = Math.sin(t * 0.11) * 0.9 + state.pointer.x * 1.3;
    camera.position.y = 3.25 + Math.sin(t * 0.17) * 0.18 - state.pointer.y * 0.5;
    camera.lookAt(0, 1.75, 0);

    renderer.render(scene, camera);
  }

  function pushBurst(dt) {
    if (!burst) return;
    burst.life += dt;
    const k = burst.life / burst.max;
    if (k >= 1) {
      if (burst.mesh) scene.remove(burst.mesh);
      burst = null;
      return;
    }
    if (!burst.mesh) {
      burst.mesh = new THREE.Mesh(
        new THREE.RingGeometry(0.9, 1, 96),
        new THREE.MeshBasicMaterial({
          color: 0xffd9a0,
          transparent: true,
          blending: THREE.AdditiveBlending,
          side: THREE.DoubleSide,
          depthWrite: false,
        })
      );
      burst.mesh.rotation.x = -Math.PI / 2;
      burst.mesh.position.y = 0.06;
      scene.add(burst.mesh);
    }
    burst.mesh.scale.setScalar(1 + k * 11);
    burst.mesh.material.opacity = (1 - k) * 0.55;
  }

  if (reduce) {
    // one still frame, ring half closed — still needs to be visible
    state.closeT = 0.62;
    placeStones(radiusAt(0.62));
    camera.position.set(0, 3.25, 9.6);
    camera.lookAt(0, 1.55, 0);
    resize();
    renderer.render(scene, camera);
    canvas.classList.add("live");
    // a second pass once fonts and layout settle
    setTimeout(() => {
      resize();
      renderer.render(scene, camera);
      canvas.classList.add("live");
    }, 400);
  } else {
    canvas.classList.add("live");
    start();
  }

  document.addEventListener("visibilitychange", () => {
    if (document.hidden) {
      renderer.setAnimationLoop(null);
      state.running = false;
    } else if (state.visible) {
      start();
    }
  });

  // Tell the page WebGL is alive so it can drop the static fallback image.
  document.body.classList.add("has-webgl");

  // Debug hook: ?shot dumps the first rendered frame as a data URL so the scene
  // can be inspected without a visible window.
  if (wantShot) {
    // Headless browsers do not tick requestAnimationFrame, so a still frame is
    // drawn on purpose, then handed back as a data URL.
    state.closeT = 0.55;
    placeStones(radiusAt(0.55));
    figure.position.y = 0.05;
    camera.position.set(0, 3.25, 9.6);
    camera.lookAt(0, 2.0, 0);
    resize();
    renderer.render(scene, camera);
    setTimeout(() => {
      const url = renderer.domElement.toDataURL("image/png");
      try { fetch("/shot/" + "ring", { method: "POST", body: url }); } catch (e) {}
      const box = document.createElement("textarea");
      box.id = "shotRing";
      try {
        box.value = url;
      } catch (err) {
        box.value = "ERR " + err.message;
      }
      document.body.appendChild(box);
    }, 300);
  }
}
