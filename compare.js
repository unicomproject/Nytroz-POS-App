const { Jimp } = require('jimp');
const path = require('path');

async function main() {
  const refPath = path.resolve('docs/references/tenant_admin_outlets_1600x900.jpg');
  const curPath = path.resolve('artifacts/task4b_outlets_1600x900.png');

  console.log('Ref path:', refPath);
  console.log('Cur path:', curPath);

  const ref = await Jimp.read(refPath);
  const cur = await Jimp.read(curPath);

  const w = ref.bitmap.width;
  const h = ref.bitmap.height;

  // 1. Side-by-side
  const sideBySide = new Jimp({ width: w * 2, height: h });
  sideBySide.composite(ref, 0, 0);
  sideBySide.composite(cur, w, 0);
  await sideBySide.write('artifacts/task4d_outlets_side_by_side.png');

  // 2. 50% opacity overlay manually
  const overlay = new Jimp({ width: w, height: h });
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const p1 = Jimp.intToRGBA(ref.getPixelColor(x, y));
      const p2 = Jimp.intToRGBA(cur.getPixelColor(x, y));
      const r = Math.round((p1.r + p2.r) / 2);
      const g = Math.round((p1.g + p2.g) / 2);
      const b = Math.round((p1.b + p2.b) / 2);
      overlay.setPixelColor(Jimp.rgbaToInt(r, g, b, 255), x, y);
    }
  }
  await overlay.write('artifacts/task4d_outlets_overlay.png');

  // 3. Absolute difference
  const diff = new Jimp({ width: w, height: h });
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const p1 = Jimp.intToRGBA(ref.getPixelColor(x, y));
      const p2 = Jimp.intToRGBA(cur.getPixelColor(x, y));
      
      const r = Math.abs(p1.r - p2.r);
      const g = Math.abs(p1.g - p2.g);
      const b = Math.abs(p1.b - p2.b);
      const diffRgba = Jimp.rgbaToInt(r, g, b, 255);
      diff.setPixelColor(diffRgba, x, y);
    }
  }
  await diff.write('artifacts/task4d_outlets_difference.png');
  await diff.write('artifacts/task4d_outlets_final_1600x900.png'); // placeholder

  console.log('Done generating comparison images.');
}

main().catch(console.error);
