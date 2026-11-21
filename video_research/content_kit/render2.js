// Render a mockup scene frame-by-frame and encode with ffmpeg.
// Usage: node render.js <scene> <out.mp4> [fps] | node render.js <scene> <prefix> --still 0.5,2,4
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const path = require('path');
(async () => {
  const [scene, out] = process.argv.slice(2, 4);
  const si = process.argv.indexOf('--still');
  const fps = si < 0 && process.argv[4] ? parseInt(process.argv[4]) : 60;
  const b = await chromium.launch();
  const pg = await b.newPage({ viewport: { width: 360, height: 640 }, deviceScaleFactor: 3 });
  await pg.goto('file://' + path.join(__dirname, (process.env.PAGE||'mockup.html')) + '?scene=' + scene);
  await pg.waitForTimeout(500);
  const dur = await pg.evaluate('window.DURATION');
  if (si >= 0) {
    for (const t of process.argv[si + 1].split(',').map(Number)) {
      await pg.evaluate(`window.renderAt(${t})`);
      await pg.screenshot({ path: `${out}_${t}.png` });
    }
  } else {
    const n = Math.round(dur * fps);
    const enc = spawn('ffmpeg', ['-v', 'error', '-y', '-f', 'image2pipe', '-framerate', String(fps), '-c:v', 'png', '-i', '-',
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '14', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out], { stdio: ['pipe', 'inherit', 'inherit'] });
    for (let i = 0; i < n; i++) {
      await pg.evaluate(`window.renderAt(${i / fps})`);
      const buf = await pg.screenshot({ type: 'png' });
      if (!enc.stdin.write(buf)) await new Promise(r => enc.stdin.once('drain', r));
    }
    enc.stdin.end();
    await new Promise(r => enc.on('close', r));
    console.log(out, n, 'frames');
  }
  await b.close();
})();
