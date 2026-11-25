const { chromium } = require('playwright'); const path = require('path');
const S = [
 ['slide2', 'c_sv.png', '1. Google Street View', ['Scout the street before you knock', 'Pools, decks + driveways = money', 'Skip the streets that won\'t buy']],
 ['slide3', 'c_ps.png', '2. PropStream', ['165+ filters on every home', 'See who owns it and for how long', 'Know what\'s left on the mortgage']],
 ['slide4', 'c_inc.png', '3. Income Map', ['Census income, block by block', 'Darker red = more money', 'Start where the money is']],
 ['slide5', 'c_lock.png', '4. SalesMapper', ['Log every knock from your lock screen', 'Your whole team on one live map', '43% more doors, 50% more sales']],
];
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1440 } });
  for (const [n, img, h, bs] of S) { const q = new URLSearchParams({ img, h }); bs.forEach(x => q.append('b', x));
    await p.goto('file://' + path.resolve('tool.html') + '?' + q); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(250); await p.screenshot({ path: n + '.png' }); }
  const q = new URLSearchParams({ img: 'c_fill.png', cta: 'comment MAP', ctas: 'for free lifetime access to SalesMapper', fol: 'Follow for more door-to-door tips' });
  await p.goto('file://' + path.resolve('tool.html') + '?' + q); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(250); await p.screenshot({ path: 'slide6.png' });
  await b.close(); })();
