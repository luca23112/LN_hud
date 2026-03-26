const hud = document.getElementById('hud');
const vehicle = document.getElementById('vehicle');

const rings = {
  health: document.getElementById('healthRing'),
  armor: document.getElementById('armorRing'),
  stamina: document.getElementById('staminaRing'),
  hunger: document.getElementById('hungerRing'),
  thirst: document.getElementById('thirstRing'),
  stress: document.getElementById('stressRing')
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
const CIRC = 578;

const money = (n) =>
  new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(Number(n || 0));

function setRing(name, value) {
  const v = Math.max(0, Math.min(100, Number(value || 0)));
  rings[name].style.setProperty('--p', v);
  vals[name].textContent = `${v}%`;
}

window.addEventListener('message', ({ data }) => {
  const { type, payload } = data || {};

  if (type === 'hud:update') {
    hud.classList.toggle('hidden', !payload.display);

    setRing('health', payload.health);
    setRing('armor', payload.armor);
    setRing('stamina', payload.stamina);
    setRing('hunger', payload.hunger);
    setRing('thirst', payload.thirst);
    setRing('stress', payload.stress);

    const fuel = Math.max(0, Math.min(100, Number(payload.fuel || 0)));
    txt.fuelBar.style.width = `${fuel}%`;
    vals.fuel.textContent = `${fuel}%`;

    const speed = Math.max(0, Number(payload.speed || 0));
    const speedPct = Math.max(0, Math.min(1, speed / 260));
    speedStroke.style.strokeDashoffset = String(CIRC - CIRC * speedPct);

    const needleAngle = -135 + speedPct * 270;
    needle.style.transform = `rotate(${needleAngle}deg)`;

    txt.speed.textContent = String(Math.round(speed));
    txt.direction.textContent = payload.direction || 'N';
    txt.street.textContent = payload.street || '-';
    txt.time.textContent = payload.time || '--:--';

    txt.job.textContent = payload.job || 'Bürger';
    txt.cash.textContent = money(payload.cash);
    txt.bank.textContent = `Bank: ${money(payload.bank)}`;
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
