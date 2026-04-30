// Generates brand PNGs from the updated SVGs.
// Usage: node tools/regen_brand_pngs.mjs
// Requires: npm i sharp (or run with `npx --yes -p sharp@0.33 node tools/regen_brand_pngs.mjs`)

import { readFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const fromRoot = (p) => resolve(repoRoot, p);

const targets = [
  {
    svg: 'assets/icons/app_icon_navy.svg',
    out: 'assets/icons/app_icon_navy_1024.png',
    size: 1024,
  },
  {
    svg: 'assets/icons/app_icon_navy.svg',
    out: 'assets/icons/app_icon_navy.png',
    size: 512,
  },
  {
    svg: 'assets/logo_lp_navy_orange.svg',
    out: 'assets/icons/logo_lp_navy_orange_1024.png',
    size: 1024,
  },
  {
    svg: 'assets/logo_lp_navy_orange.svg',
    out: 'assets/icons/logo_lp_navy_orange.png',
    size: 512,
  },
];

for (const t of targets) {
  const svg = readFileSync(fromRoot(t.svg));
  mkdirSync(dirname(fromRoot(t.out)), { recursive: true });
  await sharp(svg, { density: 384 })
    .resize(t.size, t.size, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png({ compressionLevel: 9 })
    .toFile(fromRoot(t.out));
  console.log(`✓ ${t.out} (${t.size}x${t.size})`);
}
