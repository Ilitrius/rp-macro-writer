// Erzeugt das Addon-Icon ohne externe Abhaengigkeiten:
//   icon.tga        64x64  -> im Spiel (TOC: IconTexture), WoW liest nur TGA/BLP mit Zweierpotenz-Groesse
//   media/icon.png  400x400 -> CurseForge-Projektbild
// Aufruf: node tools/make-icon.js
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const root = path.join(__dirname, '..');
const hex = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16) / 255);
const mix = (a, b, t) => a.map((v, i) => v + (b[i] - v) * t);
const clamp = (v) => Math.max(0, Math.min(1, v));

const BG_TOP = hex('#43206b'), BG_BOTTOM = hex('#150924'), GLOW = hex('#7d4bc0');
const GOLD = hex('#d4a94e'), FEL = hex('#a6f03a'), FEL_DARK = hex('#3f7a12');

function segDist(px, py, ax, ay, bx, by) {
  const dx = bx - ax, dy = by - ay;
  const t = clamp(((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy));
  return Math.hypot(px - (ax + dx * t), py - (ay + dy * t));
}

const M = [[0.25, 0.70], [0.25, 0.24], [0.50, 0.52], [0.75, 0.24], [0.75, 0.70]];
const DOTS = [[0.36, 0.845], [0.50, 0.845], [0.64, 0.845]];

// Kleines "RP" zwischen den Beinen des M: Buchstaben als Linienzuege
function letter(x0, y0, w, h, withLeg) {
  const bowl = [[x0, y0], [x0 + 0.62 * w, y0], [x0 + w, y0 + 0.13 * h], [x0 + w, y0 + 0.39 * h], [x0 + 0.62 * w, y0 + 0.52 * h], [x0, y0 + 0.52 * h]];
  const segs = [[[x0, y0], [x0, y0 + h]]];
  for (let i = 0; i < bowl.length - 1; i++) segs.push([bowl[i], bowl[i + 1]]);
  if (withLeg) segs.push([[x0 + 0.45 * w, y0 + 0.52 * h], [x0 + w, y0 + h]]);
  return segs;
}
const RP = [...letter(0.385, 0.605, 0.09, 0.125, true), ...letter(0.525, 0.605, 0.09, 0.125, false)];
const RP_COLOR = hex('#ffe9a8'), RP_OUTLINE = hex('#2a1245');

// Farbe + Deckkraft an Position (x, y) im Einheitsquadrat
function sample(x, y) {
  const r = 0.17;
  const qx = Math.max(Math.abs(x - 0.5) - (0.5 - r), 0), qy = Math.max(Math.abs(y - 0.5) - (0.5 - r), 0);
  const edge = Math.hypot(qx, qy) - r; // < 0 innen
  if (edge > 0) return [0, 0, 0, 0];

  let c = mix(BG_TOP, BG_BOTTOM, y);
  c = mix(c, GLOW, 0.55 * clamp(1 - Math.hypot(x - 0.5, y - 0.42) / 0.5));

  let d = Infinity;
  for (let i = 0; i < M.length - 1; i++) d = Math.min(d, segDist(x, y, ...M[i], ...M[i + 1]));
  const half = 0.048;
  if (d < half + 0.07) c = mix(c, FEL, 0.45 * clamp(1 - (d - half) / 0.07)); // Leuchten
  if (d < half + 0.014) c = mix(c, FEL_DARK, 0.9);                            // Kontur
  if (d < half) c = mix(FEL, hex('#e4ffb0'), clamp(1 - d / half) * 0.5);      // Strich

  for (const [cx, cy] of DOTS) if (Math.hypot(x - cx, y - cy) < 0.032) c = GOLD; // Sequenz-Punkte

  let rp = Infinity;
  for (const [a, b] of RP) rp = Math.min(rp, segDist(x, y, ...a, ...b));
  if (rp < 0.03) c = mix(c, RP_OUTLINE, 0.85);
  if (rp < 0.016) c = RP_COLOR;

  if (edge > -0.04) c = mix(GOLD, hex('#7a5a1c'), clamp((edge + 0.04) / 0.04) * 0.6); // Rahmen
  return [...c, 1];
}

function render(size, ss = 4) {
  const out = Buffer.alloc(size * size * 4); // RGBA, oben links zuerst
  for (let py = 0; py < size; py++) for (let px = 0; px < size; px++) {
    const acc = [0, 0, 0, 0];
    for (let sy = 0; sy < ss; sy++) for (let sx = 0; sx < ss; sx++) {
      const s = sample((px + (sx + 0.5) / ss) / size, (py + (sy + 0.5) / ss) / size);
      acc[0] += s[0] * s[3]; acc[1] += s[1] * s[3]; acc[2] += s[2] * s[3]; acc[3] += s[3];
    }
    const o = (py * size + px) * 4, a = acc[3] / (ss * ss);
    for (let i = 0; i < 3; i++) out[o + i] = acc[3] ? Math.round(255 * acc[i] / acc[3]) : 0;
    out[o + 3] = Math.round(255 * a);
  }
  return out;
}

function writeTga(file, size, rgba) {
  const header = Buffer.alloc(18);
  header[2] = 2;                      // unkomprimiert, Echtfarbe
  header.writeUInt16LE(size, 12);
  header.writeUInt16LE(size, 14);
  header[16] = 32;                    // Bits pro Pixel
  header[17] = 8;                     // 8 Bit Alpha, Ursprung unten links
  const body = Buffer.alloc(size * size * 4);
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    const src = ((size - 1 - y) * size + x) * 4, dst = (y * size + x) * 4;
    body[dst] = rgba[src + 2]; body[dst + 1] = rgba[src + 1]; body[dst + 2] = rgba[src]; body[dst + 3] = rgba[src + 3];
  }
  fs.writeFileSync(file, Buffer.concat([header, body]));
}

const CRC = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc32(buf) {
  let c = 0xffffffff;
  for (const b of buf) c = CRC[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function writePng(file, size, rgba) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0); ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; ihdr[9] = 6;           // 8 Bit, RGBA
  const raw = Buffer.alloc(size * (size * 4 + 1));
  for (let y = 0; y < size; y++) rgba.copy(raw, y * (size * 4 + 1) + 1, y * size * 4, (y + 1) * size * 4);
  fs.writeFileSync(file, Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0)),
  ]));
}

fs.mkdirSync(path.join(root, 'media'), { recursive: true });
writeTga(path.join(root, 'icon.tga'), 64, render(64));
writePng(path.join(root, 'media', 'icon.png'), 400, render(400));
console.log('icon.tga (64x64) und media/icon.png (400x400) geschrieben');
