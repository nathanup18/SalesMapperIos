const { chromium } = require('playwright'); const path = require('path');
const M = 'Manager';
const S = [
 { img: 's_cel.png', time: '10:46 AM', tag: 'Saturday', line: 'Celsius down the hatch.', made: 0, doors: 0 },
 { img: 's_noon.png', time: '11:42 AM', line: 'Behind schedule.', made: 1131, doors: 51, texts: [{ who: M, t: "easiest $500 I'll ever make 😂" }] },
 { img: 's_rep.png', time: '12:14 PM', line: "It's going good.", made: 2174, doors: 83, chat: [{ who: 'Jordan', t: '$20 says he quits by 3' }, { who: 'Tyler', t: 'free money for the boss lol' }] },
 { img: 's5.png', time: '2:34 PM', line: 'Celsius #2. Hot streak.', made: 4673, doors: 136, chat: [{ who: 'Tyler', t: 'wait 4.6k already??' }] },
 { img: 's6.png', dark: 1, time: '5:11 PM', line: 'Everyone\'s home. Cold streak.', made: 4922, doors: 158, ly: 440,
   lb: [{ i: 'TM', n: 'Tyler M.', v: 6180 }, { i: 'YOU', n: 'You', v: 4922, me: 1 }, { i: 'JK', n: 'Jordan K.', v: 3450 }, { i: 'SR', n: 'Sam R.', v: 2210 }],
   texts: [{ who: M, t: 'tick tock ⏰' }], ty: 940 },
 { img: 's7.png', dark: 1, time: '6:35 PM', line: 'Moving again.', made: 7233, doors: 205, chat: [{ who: 'Jordan', t: 'he might actually do it 👀' }, { who: 'Sam', t: 'no shot' }] },
 { img: 's8.png', dark: 1, time: '8:11 PM', line: 'Frozen. 49 minutes left.', made: 7233, doors: 240, texts: [{ who: M, t: 'pay up tomorrow 💸' }] },
 { img: 's12.png', dark: 1, time: '8:13 PM', line: 'Opened Lead Hunter.', made: 7233, doors: 240, hy: 390,
   lh: [['12 Birchwood Cres', 'moved in 6 days ago'], ['48 Oakridge Dr', '9 days ago'], ['7 Linden Ct', '2 weeks ago'], ['31 Oakridge Dr', '2 weeks ago']] },
 { img: 's10.png', dark: 1, time: '8:15 PM', line: '2 back-to-back. Neighbours NOT happy.', made: 9135, doors: 244, texts: [{ who: M, t: 'wait what' }] },
 { img: 's11.png', dark: 1, time: '8:53 PM', line: 'Last door…', madeText: '$?,???', pct: 96, doors: 262 },
 { img: 's12.png', dark: 1, time: '8:53 PM', line: 'Closed out.', made: 10735, doors: 263, sy: 380,
   sum: [['Made', '$10,735', 'goal hit ✓'], ['Doors', '263', ''], ['Hours', '10h 07m', ''], ['vs team avg', '2.7x', '']], texts: [{ who: M, t: '…' }], ty: 900 },
];
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1440 } });
  const go = async (f, q, o) => { await p.goto('file://' + path.resolve(f) + (q ? '?' + q : '')); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(300); await p.screenshot({ path: o }); };
  await go('hook.html', '', 'slide01.png');
  for (let i = 0; i < S.length; i++) await go('story.html', 'j=' + encodeURIComponent(JSON.stringify(S[i])), `slide${String(i + 2).padStart(2, '0')}.png`);
  await go('close.html', '', `slide${String(S.length + 2).padStart(2, '0')}.png`); await b.close(); })();
