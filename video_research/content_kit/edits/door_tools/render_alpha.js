// node render_alpha.js <scene> <start> <end> <out.mov>  -> 30fps PNG-in-MOV with alpha, absolute time t from start..end
const { chromium } = require('playwright'); const { spawn } = require('child_process'); const path = require('path'); const fs = require('fs');
(async () => { const [sc, a, b, out] = process.argv.slice(2); const C = JSON.parse(fs.readFileSync('cues.json'))[sc];
  const br = await chromium.launch(); const p = await br.newPage({ viewport: { width: 1080, height: 1920 } });
  await p.goto('file://' + path.resolve('anim.html') + '?scene=' + sc + '&c=' + encodeURIComponent(JSON.stringify(C))); await p.evaluate(() => document.fonts.ready);
  const enc = spawn('ffmpeg', ['-v', 'error', '-y', '-f', 'image2pipe', '-framerate', '30', '-c:v', 'png', '-i', '-', '-c:v', 'png', '-pix_fmt', 'rgba', out], { stdio: ['pipe', 'inherit', 'inherit'] });
  const n = Math.round((+b - +a) * 30);
  for (let i = 0; i < n; i++) { await p.evaluate(`renderAt(${+a + i / 30})`); const buf = await p.screenshot({ type: 'png', omitBackground: true }); if (!enc.stdin.write(buf)) await new Promise(r => enc.stdin.once('drain', r)); }
  enc.stdin.end(); await new Promise(r => enc.on('close', r)); await br.close(); console.log(out, n); })();
