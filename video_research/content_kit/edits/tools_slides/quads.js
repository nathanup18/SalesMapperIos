const { chromium } = require('playwright'); const path = require('path');
const S = [
 ['slide2', '1. Google Street View', ['q/sv1.png', 'q/sv2.png', 'q/sv3.png', 'q/sv4.png'], ['Scout it first', 'Pools', 'Decks', 'Driveways']],
 ['slide3', '2. PropStream', ['q/ps1.png', 'q/ps2.png', 'q/ps3.png', 'q/ps4.png'], ['Lead lists', '165+ filters', 'Years owned', 'Mortgage + equity'], ['50% 40%', '50% 30%', '50% 45%', '50% 40%']],
 ['slide4', '3. Income Heat Map', ['q/in1.png', 'q/in2.png', 'q/in3.png', 'q/in4.png'], ['Income by block', 'On the real map', 'Highest earners', 'Lowest earners']],
 ['slide5', '4. SalesMapper', ['q/sm1.png', 'q/sm2.png', 'q/sm3.png', 'q/sm4.png'], ['Lock screen knocks', 'Instant pin drop', 'Team-wide map', '+50% sales']],
];
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1440 } });
  const shot = async (q, out) => { await p.goto('file://' + path.resolve('quad.html') + '?' + q); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(300); await p.screenshot({ path: out }); };
  for (const [n, t, im, cap, pos] of S) { const q = new URLSearchParams({ t }); im.forEach(x => q.append('i', x)); cap.forEach(x => q.append('c', x)); (pos || []).forEach(x => q.append('p', x)); await shot(q, n + '.png'); }
  const q = new URLSearchParams({ cta: 'comment MAP', ctas: 'for free lifetime access to SalesMapper', fol: 'Follow for more' });
  ['q/bank.png', 'q/celsius.png', 'q/map.png', 'q/rep.png'].forEach(x => q.append('i', x)); ['50% 35%', '50% 70%', '50% 40%', '50% 50%'].forEach(x => q.append('p', x));
  await shot(q, 'slide6.png'); await b.close(); })();
