/* Four survivors, built out of primitives. A tab picks one, the scene swaps
   models with a short scale fade, and dragging spins the figure. */

import * as THREE from "three";

const canvas = document.getElementById("heroes3d");
const stage = canvas ? canvas.parentElement : null;
const tabs = Array.from(document.querySelectorAll("[data-hero]"));


/* Panel copy for the four survivors. Kept here so switching tabs never touches
   the DOM structure, and so a language toggle can re-render the same block. */
const HERO_DATA = {
  hexblade: {
    en: {
      role: "mage · ranged",
      name: "Hexblade",
      badge: "unlocked",
      text: "Starts with orbiting orbs. Damage scales faster per level than anyone else, and kills sometimes tear loose a spectral clone that keeps firing for three seconds while you run.",
      chips: ["Arcane Orbs", "Void Requiem", "Shadow Daggers"],
      stats: [["+15%", "damage per level"], ["10%", "spectral clone"], ["3 s", "clone lifetime"]],
    },
    ru: {
      role: "маг · дальний бой",
      name: "Клинок Скверны",
      badge: "открыт сразу",
      text: "Начинает с орбитами чар. С каждым уровнем урон растёт быстрее, чем у остальных, а с убийств иногда срывается призрачная копия — три секунды стреляет за тебя, пока ты бежишь.",
      chips: ["Орбиты чар", "Реквием пустоты", "Клинки тени"],
      stats: [["+15%", "урона за уровень"], ["10%", "шанс копии"], ["3 с", "живёт копия"]],
    },
  },
  ironclad: {
    en: {
      role: "tank · melee",
      name: "Ironclad",
      badge: "450 souls",
      text: "Takes the hits nobody else survives: more health every level and ten percent armour on top. Once a minute Last Stand switches on — five seconds in which dying is simply not allowed.",
      chips: ["Bloodreaver", "Bulwark Eclipse", "Blade Aura"],
      stats: [["+20", "HP per level"], ["+10%", "armour"], ["5 s", "Last Stand"]],
    },
    ru: {
      role: "танк · ближний бой",
      name: "Железный",
      badge: "450 душ",
      text: "Держит удар, которого не держит никто: больше здоровья за уровень и десять процентов брони сверху. Раз в минуту включается «Последний рубеж» — пять секунд, когда умереть нельзя.",
      chips: ["Кровопуск", "Затмение бастиона", "Клинковая аура"],
      stats: [["+20", "HP за уровень"], ["+10%", "брони"], ["5 с", "Последний рубеж"]],
    },
  },
  wraithborn: {
    en: {
      role: "shadow · speed and crits",
      name: "Wraithborn",
      badge: "600 souls",
      text: "Does not tank and does not hit hard — simply refuses to be caught. Speed and crit chance grow every level, and every eight seconds the shadow drags you out of the crowd, never further than 260 pixels.",
      chips: ["Shadow Daggers", "Crimson Waltz", "Blade Aura"],
      stats: [["+10%", "speed per level"], ["+5%", "crit chance"], ["8 s", "blink cooldown"]],
    },
    ru: {
      role: "тень · скорость и криты",
      name: "Дитя Тени",
      badge: "600 душ",
      text: "Не танкует и не бьёт больно — просто не даёт себя поймать. Скорость и шанс крита растут каждый уровень, а раз в восемь секунд тень сама уводит тебя из толпы, не дальше 260 пикселей.",
      chips: ["Клинки тени", "Алый вальс", "Клинковая аура"],
      stats: [["+10%", "скорости за уровень"], ["+5%", "шанс крита"], ["8 с", "откат блинка"]],
    },
  },
  stormcaller: {
    en: {
      role: "shaman · crowd damage",
      name: "Stormcaller",
      badge: "750 souls",
      text: "Chain lightning finds the next body by itself. Attack speed climbs every level, and every fiftieth kill breaks into Surge — a burst that makes the crowd stop existing for a moment.",
      chips: ["Lightning Chain", "Absolute Zero", "Arcane Orbs"],
      stats: [["+10%", "attack speed"], ["50", "kills to Surge"], ["∞", "chain targets"]],
    },
    ru: {
      role: "шаман · массовый урон",
      name: "Зов Бури",
      badge: "750 душ",
      text: "Цепная молния сама находит следующего. Скорость атаки растёт каждый уровень, а каждый пятидесятый килл срывается во «Всплеск» — и толпа на секунду перестаёт существовать.",
      chips: ["Цепная молния", "Абсолютный ноль", "Орбиты чар"],
      stats: [["+10%", "скорость атаки"], ["50", "киллов до всплеска"], ["∞", "целей в цепи"]],
    },
  },
};

function renderHeroPanel(key, lang) {
  const panel = document.querySelector("[data-hero-panel]");
  const data = HERO_DATA[key];
  if (!panel || !data) return;
  const d = data[lang === "ru" ? "ru" : "en"];
  panel.setAttribute("data-hero-active", key);
  panel.innerHTML =
    '<div class="hp-head"><div><p class="hp-role"></p><h3></h3></div>' +
    '<span class="hp-badge"></span></div>' +
    '<p class="hp-text"></p><ul class="chips"></ul><div class="hp-stats"></div>';

  panel.querySelector(".hp-role").textContent = d.role;
  panel.querySelector("h3").textContent = d.name;
  panel.querySelector(".hp-badge").textContent = d.badge;
  panel.querySelector(".hp-text").textContent = d.text;

  const chips = panel.querySelector(".chips");
  d.chips.forEach((chip) => {
    const li = document.createElement("li");
    li.textContent = chip;
    chips.appendChild(li);
  });

  const stats = panel.querySelector(".hp-stats");
  d.stats.forEach((pair) => {
    const cell = document.createElement("div");
    const b = document.createElement("b");
    const span = document.createElement("span");
    b.textContent = pair[0];
    span.textContent = pair[1];
    cell.append(b, span);
    stats.appendChild(cell);
  });
}

window.renderHeroPanel = (lang) => renderHeroPanel(activeKey || "hexblade", lang);

const CLASS_COLORS = {
  hexblade: 0xb06bff,
  ironclad: 0xd98a3a,
  wraithborn: 0x3fe0c8,
  stormcaller: 0x6fc4ff,
};

if (canvas && stage && tabs.length) {
  const wantShot = new URLSearchParams(location.search).has("shot");
  const renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: true,
    alpha: true,
    preserveDrawingBuffer: wantShot,
  });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setClearColor(0x000000, 0);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(38, 1, 0.1, 60);
  camera.position.set(0, 1.8, 4.35);
  camera.lookAt(0, 1.02, 0);

  scene.add(new THREE.AmbientLight(0x6a5a86, 0.9));

  const keyLight = new THREE.DirectionalLight(0xd8c8ff, 1.0);
  keyLight.position.set(3, 6, 4);
  scene.add(keyLight);

  const rimLight = new THREE.PointLight(0xb06bff, 22, 14, 2);
  rimLight.position.set(-2.6, 2.4, -2.4);
  scene.add(rimLight);

  const classLight = new THREE.PointLight(0xffffff, 16, 10, 2);
  classLight.position.set(0, 1.4, 2.6);
  scene.add(classLight);

  // soft shadow under whoever is on show
  // a rune circle so the model is standing on something
  const runeMat = new THREE.MeshBasicMaterial({
    color: 0x8e6bc0,
    transparent: true,
    opacity: 0.34,
    blending: THREE.AdditiveBlending,
    side: THREE.DoubleSide,
    depthWrite: false,
  });
  const runeOuter = new THREE.Mesh(new THREE.RingGeometry(0.92, 0.96, 64), runeMat);
  runeOuter.rotation.x = -Math.PI / 2;
  runeOuter.position.y = 0.004;
  scene.add(runeOuter);
  const runeInner = new THREE.Mesh(new THREE.RingGeometry(0.62, 0.64, 48), runeMat);
  runeInner.rotation.x = -Math.PI / 2;
  runeInner.position.y = 0.004;
  scene.add(runeInner);

  const shadow = new THREE.Mesh(
    new THREE.CircleGeometry(1.15, 48),
    new THREE.MeshBasicMaterial({
      color: 0x000000,
      transparent: true,
      opacity: 0.45,
      depthWrite: false,
    })
  );
  shadow.rotation.x = -Math.PI / 2;
  shadow.position.y = 0.001;
  scene.add(shadow);

  function mat(color, opts) {
    return new THREE.MeshStandardMaterial(
      Object.assign({ color, roughness: 0.62, metalness: 0.22 }, opts || {})
    );
  }

  function eyes(group, color, y, z, gap) {
    const m = new THREE.MeshBasicMaterial({ color });
    const g = new THREE.SphereGeometry(0.035, 8, 6);
    const l = new THREE.Mesh(g, m);
    const r = new THREE.Mesh(g, m);
    l.position.set(-gap, y, z);
    r.position.set(gap, y, z);
    group.add(l, r);
    return [l, r];
  }

  // --------------------------------------------------------------- Hexblade
  function buildHexblade() {
    const g = new THREE.Group();
    const robeMat = mat(0x2a1a3f, { roughness: 0.78, emissive: 0x160b26 });
    const robe = new THREE.Mesh(new THREE.ConeGeometry(0.62, 1.75, 12, 1, true), robeMat);
    robe.material.side = THREE.DoubleSide;
    robe.position.y = 0.88;
    g.add(robe);

    const hood = new THREE.Mesh(new THREE.SphereGeometry(0.38, 16, 12), robeMat);
    hood.position.y = 1.78;
    g.add(hood);

    const voidFace = new THREE.Mesh(
      new THREE.SphereGeometry(0.22, 12, 10),
      new THREE.MeshBasicMaterial({ color: 0x06030c })
    );
    voidFace.position.set(0, 1.74, 0.2);
    g.add(voidFace);
    eyes(g, 0xc07bff, 1.775, 0.33, 0.075);

    // three orbiting orbs — the signature weapon
    const orbs = new THREE.Group();
    const orbMat = new THREE.MeshBasicMaterial({ color: 0xc99bff });
    const glowSpr = new THREE.SpriteMaterial({
      color: 0xb06bff,
      transparent: true,
      opacity: 0.55,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
    });
    for (let i = 0; i < 3; i++) {
      const orb = new THREE.Mesh(new THREE.SphereGeometry(0.075, 12, 10), orbMat);
      orb.userData.phase = (i / 3) * Math.PI * 2;
      const halo = new THREE.Sprite(glowSpr.clone());
      halo.scale.set(0.42, 0.42, 1);
      orb.add(halo);
      orbs.add(orb);
    }
    orbs.position.y = 1.15;
    g.add(orbs);
    g.userData.animate = (t) => {
      for (const orb of orbs.children) {
        const a = t * 1.5 + orb.userData.phase;
        orb.position.set(Math.cos(a) * 0.74, Math.sin(t * 2 + orb.userData.phase) * 0.12, Math.sin(a) * 0.74);
      }
      rimLight.color.setHex(0xb06bff);
    };
    return g;
  }

  // --------------------------------------------------------------- Ironclad
  function buildIronclad() {
    const g = new THREE.Group();
    const steel = mat(0x7d8494, { metalness: 0.72, roughness: 0.36 });
    const darkSteel = mat(0x4a4f5c, { metalness: 0.7, roughness: 0.42 });
    const cloth = mat(0x5b1f2b, { roughness: 0.85, metalness: 0.05 });

    const legs = new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.36, 0.55, 10), cloth);
    legs.position.y = 0.28;
    g.add(legs);

    const torso = new THREE.Mesh(new THREE.BoxGeometry(0.82, 0.86, 0.5), steel);
    torso.position.y = 1.0;
    g.add(torso);

    const belt = new THREE.Mesh(new THREE.BoxGeometry(0.84, 0.12, 0.52), darkSteel);
    belt.position.y = 0.62;
    g.add(belt);

    for (const sx of [-1, 1]) {
      const pauldron = new THREE.Mesh(new THREE.SphereGeometry(0.25, 14, 10), steel);
      pauldron.position.set(sx * 0.47, 1.36, 0);
      g.add(pauldron);
    }

    const helmet = new THREE.Mesh(new THREE.BoxGeometry(0.44, 0.38, 0.42), steel);
    helmet.position.y = 1.66;
    g.add(helmet);
    const crest = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.16, 0.44), cloth);
    crest.position.y = 1.88;
    g.add(crest);

    // burning visor slit
    const visor = new THREE.Mesh(
      new THREE.BoxGeometry(0.34, 0.05, 0.02),
      new THREE.MeshBasicMaterial({ color: 0xff8a3c })
    );
    visor.position.set(0, 1.66, 0.22);
    g.add(visor);

    // shield and blade
    const shield = new THREE.Mesh(new THREE.CylinderGeometry(0.42, 0.42, 0.07, 8), darkSteel);
    shield.rotation.z = Math.PI / 2;
    shield.rotation.y = Math.PI / 2;
    shield.position.set(-0.62, 0.95, 0.16);
    g.add(shield);

    const blade = new THREE.Mesh(new THREE.BoxGeometry(0.09, 1.05, 0.03), mat(0xc9c2b0, { metalness: 0.85, roughness: 0.25 }));
    blade.position.set(0.64, 1.15, 0.1);
    blade.rotation.z = 0.16;
    g.add(blade);
    const hilt = new THREE.Mesh(new THREE.BoxGeometry(0.24, 0.06, 0.07), darkSteel);
    hilt.position.set(0.66, 0.63, 0.1);
    g.add(hilt);

    g.userData.animate = (t) => {
      blade.rotation.z = 0.16 + Math.sin(t * 1.4) * 0.05;
      visor.material.color.setHex(Math.sin(t * 3) > 0.2 ? 0xff8a3c : 0xd8502a);
      rimLight.color.setHex(0xffa44e);
    };
    return g;
  }

  // ------------------------------------------------------------- Wraithborn
  function buildWraithborn() {
    const g = new THREE.Group();
    // a lathe profile makes the ghost taper into a wisp instead of a cone
    const profile = [];
    for (let i = 0; i <= 10; i++) {
      const t = i / 10;
      profile.push(new THREE.Vector2(Math.sin(t * Math.PI * 0.92) * 0.5 * (1 - t * 0.35) + 0.02, t * 1.9));
    }
    const bodyMat = new THREE.MeshStandardMaterial({
      color: 0x1d6b62,
      emissive: 0x1fa895,
      emissiveIntensity: 0.55,
      transparent: true,
      opacity: 0.62,
      roughness: 0.4,
      metalness: 0.1,
      side: THREE.DoubleSide,
    });
    const body = new THREE.Mesh(new THREE.LatheGeometry(profile, 22), bodyMat);
    g.add(body);

    const hood = new THREE.Mesh(new THREE.SphereGeometry(0.36, 16, 12), bodyMat);
    hood.position.y = 1.74;
    g.add(hood);
    const face = new THREE.Mesh(
      new THREE.SphereGeometry(0.2, 12, 10),
      new THREE.MeshBasicMaterial({ color: 0x04120f, transparent: true, opacity: 0.9 })
    );
    face.position.set(0, 1.72, 0.18);
    g.add(face);
    eyes(g, 0x64fff0, 1.755, 0.31, 0.07);

    // two daggers, crossed behind the shoulders
    for (const s of [-1, 1]) {
      const dagger = new THREE.Mesh(
        new THREE.BoxGeometry(0.055, 0.62, 0.02),
        mat(0xbfd8d2, { metalness: 0.8, roughness: 0.3 })
      );
      dagger.position.set(s * 0.34, 1.36, -0.18);
      dagger.rotation.z = s * 0.62;
      g.add(dagger);
    }

    // trailing wisps
    const wisps = new THREE.Group();
    for (let i = 0; i < 5; i++) {
      const w = new THREE.Mesh(
        new THREE.SphereGeometry(0.05 + Math.random() * 0.03, 8, 6),
        new THREE.MeshBasicMaterial({ color: 0x64fff0, transparent: true, opacity: 0.55 })
      );
      w.userData.phase = Math.random() * Math.PI * 2;
      w.userData.radius = 0.35 + Math.random() * 0.4;
      wisps.add(w);
    }
    g.add(wisps);

    g.userData.animate = (t) => {
      for (const w of wisps.children) {
        const a = t * 0.9 + w.userData.phase;
        w.position.set(
          Math.cos(a) * w.userData.radius,
          0.35 + Math.sin(t * 0.8 + w.userData.phase) * 0.25 + 0.2,
          Math.sin(a) * w.userData.radius
        );
      }
      bodyMat.opacity = 0.55 + Math.sin(t * 1.7) * 0.07;
      rimLight.color.setHex(0x3fe0c8);
    };
    return g;
  }

  // ------------------------------------------------------------ Stormcaller
  function buildStormcaller() {
    const g = new THREE.Group();
    const robeMat = mat(0x26314f, { roughness: 0.8, emissive: 0x101a30 });
    const robe = new THREE.Mesh(new THREE.ConeGeometry(0.6, 1.8, 12, 1, true), robeMat);
    robe.material.side = THREE.DoubleSide;
    robe.position.y = 0.9;
    g.add(robe);

    const hood = new THREE.Mesh(new THREE.SphereGeometry(0.37, 16, 12), robeMat);
    hood.position.y = 1.8;
    g.add(hood);
    const voidFace = new THREE.Mesh(
      new THREE.SphereGeometry(0.21, 12, 10),
      new THREE.MeshBasicMaterial({ color: 0x040610 })
    );
    voidFace.position.set(0, 1.77, 0.19);
    g.add(voidFace);
    eyes(g, 0x8fdcff, 1.79, 0.32, 0.07);

    // staff with a live arc at the tip
    const staff = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.045, 2.05, 8),
      mat(0x3a2f22, { roughness: 0.9, metalness: 0.1 })
    );
    staff.position.set(0.72, 1.02, 0.12);
    staff.rotation.z = -0.1;
    g.add(staff);

    const gem = new THREE.Mesh(
      new THREE.OctahedronGeometry(0.13),
      new THREE.MeshBasicMaterial({ color: 0x9fe4ff })
    );
    gem.position.set(0.79, 2.06, 0.12);
    g.add(gem);

    const arcMat = new THREE.LineBasicMaterial({ color: 0x9fe4ff, transparent: true, opacity: 0.9 });
    const arcGeo = new THREE.BufferGeometry();
    const arc = new THREE.Line(arcGeo, arcMat);
    g.add(arc);
    let arcTimer = 0;

    const buildArc = () => {
      const pts = [];
      let x = 0.79;
      let y = 2.06;
      for (let i = 0; i < 9; i++) {
        pts.push(new THREE.Vector3(x, y, 0.12));
        x += (Math.random() - 0.55) * 0.34;
        y -= 0.16 + Math.random() * 0.12;
      }
      arcGeo.setFromPoints(pts);
    };
    buildArc();

    g.userData.animate = (t, dt) => {
      arcTimer += dt;
      if (arcTimer > 0.09) {
        arcTimer = 0;
        buildArc();
      }
      gem.material.color.setHex(Math.sin(t * 6) > 0 ? 0xc7f0ff : 0x6fc4ff);
      staff.rotation.z = -0.1 + Math.sin(t * 0.8) * 0.03;
      rimLight.color.setHex(0x6fc4ff);
    };
    return g;
  }

  const builds = {
    hexblade: buildHexblade,
    ironclad: buildIronclad,
    wraithborn: buildWraithborn,
    stormcaller: buildStormcaller,
  };

  const models = {};
  for (const key of Object.keys(builds)) {
    const m = builds[key]();
    m.visible = false;
    m.scale.setScalar(0.001);
    models[key] = m;
    scene.add(m);
  }

  let active = null;
  let activeKey = "";
  let spin = 0;
  let spinTarget = 0;
  let dragging = false;
  let lastX = 0;

  function select(key) {
    if (activeKey === key) return;
    if (active) {
      active.visible = false;
      active.scale.setScalar(0.001);
    }
    active = models[key];
    activeKey = key;
    if (active) {
      active.visible = true;
      active.scale.setScalar(0.001);
      classLight.color.setHex(CLASS_COLORS[key] || 0xffffff);
      active.userData.grow = 0;
    }
  }

  // One delegated listener: a stale element or a click on the inner <img> both work.
  function choose(key) {
    if (!key || !models[key]) return;
    const lang = document.documentElement.lang === "ru" ? "ru" : "en";
    tabs.forEach((b) => {
      const on = b.dataset.hero === key;
      b.classList.toggle("active", on);
      b.setAttribute("aria-selected", on ? "true" : "false");
    });
    select(key);
    renderHeroPanel(key, lang);
    const panel = document.querySelector("[data-hero-panel]");
    if (panel) {
      panel.dataset.heroActive = key;
      panel.classList.remove("swap");
      void panel.offsetWidth;
      panel.classList.add("swap");
    }
  }
  document.addEventListener("click", (e) => {
    const btn = e.target && e.target.closest ? e.target.closest("[data-hero]") : null;
    if (btn) choose(btn.dataset.hero);
  });
  document.addEventListener("keydown", (e) => {
    if (!document.getElementById("heroes").contains(document.activeElement)) return;
    const i = tabs.findIndex((b) => b.dataset.hero === activeKey);
    if (e.key === "ArrowRight" || e.key === "ArrowDown") { e.preventDefault(); choose(tabs[(i + 1) % tabs.length].dataset.hero); tabs[(i + 1) % tabs.length].focus(); }
    if (e.key === "ArrowLeft" || e.key === "ArrowUp") { e.preventDefault(); const n = (i - 1 + tabs.length) % tabs.length; choose(tabs[n].dataset.hero); tabs[n].focus(); }
  });

  canvas.addEventListener("pointerdown", (e) => {
    dragging = true;
    lastX = e.clientX;
    canvas.setPointerCapture(e.pointerId);
  });
  canvas.addEventListener("pointermove", (e) => {
    if (!dragging) return;
    spinTarget += (e.clientX - lastX) * 0.012;
    lastX = e.clientX;
  });
  canvas.addEventListener("pointerup", () => { dragging = false; });
  canvas.addEventListener("pointercancel", () => { dragging = false; });

  function resize() {
    const w = stage.clientWidth;
    const h = stage.clientHeight;
    if (!w || !h) return;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  }
  resize();
  window.addEventListener("resize", resize);

  // ?hero=stormcaller deep-links straight into one survivor
  const wanted = new URLSearchParams(location.search).get("hero");
  const startKey = wanted && Object.prototype.hasOwnProperty.call(models, wanted) ? wanted : "hexblade";
  select(startKey);
  renderHeroPanel(startKey, document.documentElement.lang === "ru" ? "ru" : "en");
  tabs.forEach((b) => {
    const on = b.dataset.hero === startKey;
    b.classList.toggle("active", on);
    b.setAttribute("aria-selected", on ? "true" : "false");
  });

  const forceMotion = new URLSearchParams(location.search).has("motion");
  const reduce = !forceMotion && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const clock = new THREE.Clock();
  let visible = true;

  const io = new IntersectionObserver((entries) => {
    for (const e of entries) visible = e.isIntersecting;
  }, { threshold: 0.05 });
  io.observe(stage);

  function tick() {
    const dt = Math.min(clock.getDelta(), 0.05);
    const t = clock.elapsedTime;
    if (!visible || document.hidden) return;

    if (!dragging) spinTarget += dt * 0.35;
    spin += (spinTarget - spin) * 0.12;

    for (const key of Object.keys(models)) {
      const m = models[key];
      if (m === active) {
        m.userData.grow = Math.min(1, (m.userData.grow || 0) + dt * 4.2);
        const s = 1 - Math.pow(1 - m.userData.grow, 3);
        m.scale.setScalar(0.85 + s * 0.15);
        m.position.y = Math.sin(t * 1.1) * 0.03;
        m.rotation.y = spin;
        if (m.userData.animate) m.userData.animate(t, dt);
      }
    }
    shadow.scale.setScalar(1 + Math.sin(t * 1.1) * 0.02);
    runeMat.color.setHex(CLASS_COLORS[activeKey] || 0x8e6bc0);
    runeOuter.rotation.z = t * 0.25;
    runeInner.rotation.z = -t * 0.4;

    renderer.render(scene, camera);
  }

  if (reduce) {
    resize();
    active.scale.setScalar(1);
    active.userData.animate(1.2, 0.016);
    renderer.render(scene, camera);
    setTimeout(() => {
      resize();
      renderer.render(scene, camera);
    }, 400);
  } else {
    renderer.setAnimationLoop(tick);
    document.body.classList.add("has-3d-heroes");
    if (wantShot) {
      resize();
      active.scale.setScalar(1);
      active.rotation.y = 0.6;
      active.userData.animate(1.2, 0.016);
      renderer.render(scene, camera);
      setTimeout(() => {
        const url = renderer.domElement.toDataURL("image/png");
      try { fetch("/shot/" + "heroes", { method: "POST", body: url }); } catch (e) {}
      const box = document.createElement("textarea");
        box.id = "shotHeroes";
        try {
          box.value = url;
        } catch (err) {
          box.value = "ERR " + err.message;
        }
        document.body.appendChild(box);
      }, 2400);
    }
  }
}
