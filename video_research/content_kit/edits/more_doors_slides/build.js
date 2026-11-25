const { chromium } = require('playwright'); const path = require('path');
const S = [['p1.png', 'My top rep knocks the fewest doors', ["Here's what he does instead"]],
           ['p2.png', 'Rushing burns doors', ['A maybe turns into a no', 'for months']],
           ['p3.png', 'You never go back', ["The come-back-laters are", 'your easiest sales']],
           ['p4.png', 'Knock 5 to 8 pm', ["That's when people", 'actually answer']]];
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1440 } });
  const go = async (f, q, o) => { await p.goto('file://' + path.resolve(f) + (q ? '?' + q : '')); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(250); await p.screenshot({ path: o }); };
  await go('hook.html', '', 'slide1.png');
  for (let i = 0; i < S.length; i++) { const q = new URLSearchParams({ img: S[i][0], h: S[i][1] }); S[i][2].forEach(x => q.append('b', x)); await go('tool2.html', q, `slide${i + 2}.png`); }
  await go('close.html', '', 'slide6.png'); await b.close(); })();
