const { chromium } = require('playwright'); const { spawn } = require('child_process'); const path = require('path');
(async () => { const [page, dur, out] = process.argv.slice(2); const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1920 } });
  await p.goto('file://' + path.resolve(page) + '?dur=' + dur); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(300);
  const enc = spawn('ffmpeg', ['-v', 'error', '-y', '-f', 'image2pipe', '-framerate', '30', '-c:v', 'png', '-i', '-', '-c:v', 'libx264', '-crf', '15', '-pix_fmt', 'yuv420p', out], { stdio: ['pipe', 'inherit', 'inherit'] });
  const n = Math.round(+dur * 30); for (let i = 0; i < n; i++) { await p.evaluate(`renderAt(${i / 30})`); const buf = await p.screenshot({ type: 'png' }); if (!enc.stdin.write(buf)) await new Promise(r => enc.stdin.once('drain', r)); }
  enc.stdin.end(); await new Promise(r => enc.on('close', r)); await b.close(); console.log(out, n); })();
