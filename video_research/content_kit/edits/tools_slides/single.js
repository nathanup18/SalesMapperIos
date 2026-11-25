// single full-bleed picture per tool, 3 bullets at the top in TikTok classic text (white, black outline, no box)
const { chromium } = require('playwright'); const path = require('path');
const S = [
 ['slide2', 'c_inc.png', '1. Income Heat Map', ['Income, block by block', 'Darker red = more money', 'Knock the rich blocks first']],
 ['slide3', 'c_sv.png', '2. Google Street View', ['Scout before you knock', 'Pools + decks = money', "Skip streets that won't buy"]],
 ['slide4', 'c_ps.png', '3. PropStream', ['165+ filters per home', "How long they've owned it", "What's left on the mortgage"]],
 ['slide5', 'c_lock.png', '4. SalesMapper', ['Knock from your lock screen', 'Whole team on one map', '43% more doors, 50% more sales']],
];
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1440 } });
  for (const [n, img, h, bs] of S) { const q = new URLSearchParams({ img, h }); bs.forEach(x => q.append('b', x));
    await p.goto('file://' + path.resolve('tool2.html') + '?' + q); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(250); await p.screenshot({ path: n + '.png' }); }
  const q = new URLSearchParams({ img: 'c_fill.png', cta: 'comment MAP', ctas: 'for free lifetime access to SalesMapper', fol: 'Follow for more' });
  await p.goto('file://' + path.resolve('tool2.html') + '?' + q); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(250); await p.screenshot({ path: 'slide6.png' });
  await b.close(); })();
