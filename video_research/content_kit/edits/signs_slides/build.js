const { chromium } = require('playwright'); const path = require('path');
const SIGNS = [
 ['1. Fresh landscaping', ['They spend money on the outside']],
 ['2. Kids\' bikes out', ['Home after 5, and they care', 'about the house']],
 ['3. Two newer cars', ['There\'s room in the budget']],
 ['4. A contractor sign', ['They already pay for', 'home services']],
 ['5. Doorbell camera', ['Usually an owner who', 'invests in the house']],
 ['6. Something worn out', ['Old roof, faded fence,', 'cracked driveway = a need']],
 ['7. Garage door open', ['They\'re home and already', 'in project mode']],
];
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1440 } });
  const go = async (file, q, out) => { await p.goto('file://' + path.resolve(file) + '?' + q); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(250); await p.screenshot({ path: out }); };
  await go('textslide.html', new URLSearchParams({ html: '<div class="h">7 signs a house will say <b>YES</b> before you even knock</div>' }), 'slide1.png');
  for (let i = 0; i < 7; i++) { const q = new URLSearchParams({ img: `p${i + 1}.png`, h: SIGNS[i][0] }); SIGNS[i][1].forEach(x => q.append('b', x)); await go('tool2.html', q, `slide${i + 2}.png`); }
  await go('textslide.html', new URLSearchParams({ html: '<div class="h">Which sign did I miss?</div><div class="s">Save this for your next shift</div><div class="s2">Follow for more door-to-door tips</div>' }), 'slide9.png');
  await b.close(); })();
