// Frame-accurate capture of salesmapper.ca's "On a shift" lock-screen demo: we drive the video clock and CSS animations ourselves.
const { chromium } = require('playwright'); const fs = require('fs');
(async () => { const [out, t0, n] = [process.argv[2], +process.argv[3], +process.argv[4]];   // video time of frame 0, frame count (30 fps)
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 560, height: 900 }, deviceScaleFactor: 3 });
  await p.addInitScript(() => { HTMLMediaElement.prototype.play = function () { return Promise.resolve(); }; });
  await p.goto('https://salesmapper.ca/', { waitUntil: 'networkidle' });
  await p.addStyleTag({ content: 'header,nav,.nav,.site-header{display:none !important}' });
  await p.evaluate(() => { const e = document.querySelector('.shift-anim'); window.scrollBy(0, e.getBoundingClientRect().top - 200); });
  await p.waitForTimeout(1500);
  const el = p.locator('.shift-anim');
  for (let i = 0; i < n; i++) {
    const t = Math.max(0, t0 + i / 30);
    await p.evaluate(async (t) => {
      const v = document.querySelector('.shift-anim video'), s = document.querySelector('.shift-anim');
      if (Math.abs(v.currentTime - t) > 1e-3) { await new Promise(r => { v.addEventListener('seeked', r, { once: true }); v.currentTime = t; }); }
      await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));      // site's onTime runs: tap at 1.95, "Sale placed" at 2.3
      s.classList.toggle('s-press', t >= 1.95 && t < 2.15);
      for (const a of document.getAnimations()) if (s.contains(a.effect && a.effect.target)) { a.pause(); a.currentTime = Math.max(0, (t - 1.95) * 1000); }
    }, t);
    await el.screenshot({ path: `${out}/${String(i).padStart(5, '0')}.png` });
  }
  await b.close(); console.log('frames', n); })();
