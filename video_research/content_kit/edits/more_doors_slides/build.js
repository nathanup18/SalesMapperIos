const { chromium } = require('playwright'); const path = require('path');
const S = [['p0.png', 'My top rep knocks the fewest doors', ["Here's what he does instead"]],
           ['p1.png', 'He skips the 1 pm grind', ['Big door count,', 'nobody home']],
           ['p2.png', 'He never rushes a pitch', ['A rushed maybe is a no', 'for months']],
           ['p3.png', 'He always goes back', ['Come-back-laters are', 'his easiest sales']],
           ['p4.png', 'He knocks 5 to 8 pm', ["That's when people", 'actually answer']]];
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1440 } });
  const go = async (f, q, o) => { await p.goto('file://' + path.resolve(f) + (q ? '?' + q : '')); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(250); await p.screenshot({ path: o }); };
  await go('hook.html', '', 'slide1.png');
  for (let i = 0; i < S.length; i++) { const q = new URLSearchParams({ img: S[i][0], h: S[i][1] }); if (i === 0) q.set('em', 'fewest'); S[i][2].forEach(x => q.append('b', x)); await go('tool2.html', q, `slide${i + 2}.png`); }
  await go('close.html', '', 'slide7.png'); await b.close(); })();
