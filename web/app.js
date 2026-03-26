const hud = document.getElementById('hud');
const vehicle = document.getElementById('vehicle');

const dots = {
  health: document.getElementById('healthBar'),
  armor: document.getElementById('armorBar'),
  stamina: document.getElementById('staminaBar'),
  hunger: document.getElementById('hungerBar'),
  thirst: document.getElementById('thirstBar'),
  stress: document.getElementById('stressBar')
};

const vals = {
  health: document.getElementById('healthValue'),
  armor: document.getElementById('armorValue'),
  stamina: document.getElementById('staminaValue'),
  hunger: document.getElementById('hungerValue'),
  thirst: document.getElementById('thirstValue'),
  stress: document.getElementById('stressValue'),
  fuel: document.getElementById('fuelValue')
};

const txt = {
  speed: document.getElementById('speed'),
  fuelBar: document.getElementById('fuelBar'),
  direction: document.getElementById('direction'),
  street: document.getElementById('street'),
  time: document.getElementById('time'),
  voice: document.getElementById('voice'),
  voiceRange: document.getElementById('voiceRange'),
  cash: document.getElementById('cash'),
  bank: document.getElementById('bank'),
  job: document.getElementById('job'),
  playerId: document.getElementById('playerId'),
  ping: document.getElementById('ping')
};

const speedStroke = document.getElementById('speedStroke');
const needle = document.getElementById('needle');
const needleGlow = document.getElementById('needleGlow');
const ticksGroup = document.getElementById('ticks');
const CIRC = 678;
const SPEED_MAX = 260;

const svgNS = 'http://www.w3.org/2000/svg';

function createGaugeTicks() {
  for (let i = 0; i <= 13; i += 1) {
    const angle = -135 + i * (270 / 13);
    const rad = (angle * Math.PI) / 180;

    const isMajor = i % 1 === 0;
    const inner = isMajor ? 94 : 100;
    const outer = 108;

    const x1 = 150 + Math.cos(rad) * inner;
    const y1 = 150 + Math.sin(rad) * inner;
    const x2 = 150 + Math.cos(rad) * outer;
    const y2 = 150 + Math.sin(rad) * outer;

    const line = document.createElementNS(svgNS, 'line');
    line.setAttribute('x1', x1.toFixed(2));
    line.setAttribute('y1', y1.toFixed(2));
    line.setAttribute('x2', x2.toFixed(2));
    line.setAttribute('y2', y2.toFixed(2));
    line.setAttribute('class', isMajor ? 'tick' : 'tick minor');
    ticksGroup.appendChild(line);

    if (isMajor) {
      const label = document.createElementNS(svgNS, 'text');
      const lx = 150 + Math.cos(rad) * 82;
      const ly = 150 + Math.sin(rad) * 82;
      label.setAttribute('x', lx.toFixed(2));
      label.setAttribute('y', ly.toFixed(2));
      label.setAttribute('class', 'tickText');
      label.textContent = String(i * 20);
      ticksGroup.appendChild(label);
    }
  }
}

createGaugeTicks();

const money = (n) =>
  new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(Number(n || 0));

function setDot(name, value) {
  const v = Math.max(0, Math.min(100, Number(value || 0)));
  dots[name].style.setProperty('--p', v);
  vals[name].textContent = String(v);
}

window.addEventListener('message', ({ data }) => {
  const { type, payload } = data || {};

  if (type === 'hud:update') {
    hud.classList.toggle('hidden', !payload.display);

    setDot('health', payload.health);
    setDot('armor', payload.armor);
    setDot('stamina', payload.stamina);
    setDot('hunger', payload.hunger);
    setDot('thirst', payload.thirst);
    setDot('stress', payload.stress);

    const fuel = Math.max(0, Math.min(100, Number(payload.fuel || 0)));
    txt.fuelBar.style.width = `${fuel}%`;
    vals.fuel.textContent = `${fuel}%`;

    const speed = Math.max(0, Number(payload.speed || 0));
    const speedPct = Math.max(0, Math.min(1, speed / SPEED_MAX));
    speedStroke.style.strokeDashoffset = String(CIRC - CIRC * speedPct);

    const angle = -135 + speedPct * 270;
    needle.style.transform = `rotate(${angle}deg)`;
    needleGlow.style.transform = `rotate(${angle}deg)`;

    txt.speed.textContent = String(Math.round(speed));
    txt.direction.textContent = payload.direction || 'N';
    txt.street.textContent = payload.street || '-';
    txt.time.textContent = payload.time || '--:--';

    txt.job.textContent = payload.job || 'Bürger';
    txt.cash.textContent = money(payload.cash);
    txt.bank.textContent = money(payload.bank);
    txt.playerId.textContent = String(payload.id ?? 0);
    txt.ping.textContent = `${payload.ping ?? 0}ms`;

    txt.voice.textContent = payload.talking ? 'REDEN' : 'STUMM';
    txt.voice.classList.toggle('talking', !!payload.talking);
    txt.voiceRange.textContent = `${payload.voiceRange ?? 0}m`;

    vehicle.classList.toggle('hidden', !payload.inVehicle);
  }

  if (type === 'hud:toggle') {
    hud.classList.toggle('hidden', !payload.visible);
  }
});
