const { chromium } = require('playwright'); const path = require('path');
const M = 'Manager', T = 'Team 🏠';
const S = [
 { img: 's_am.png', big: '10 hours.<br>1 Celsius.<br>$500 on the line.', line: '(miss by $1 and he wins)' },
 { img: 's_cel.png', time: '10:46 AM', tag: 'Saturday', stakes: '$10,000 to go · 10h 14m left', line: 'Celsius down the hatch. Let\'s go.', made: 0, doors: 0 },
 { img: 's_noon.png', time: '11:42 AM', stakes: '$8,869 to go · 9h 18m left', line: 'Already behind. And he knows it.', made: 1131, doors: 51, texts: [{ who: M, t: "easiest $500 I'll ever make 😂" }], ty: 640 },
 { img: 's_rep.png', time: '12:14 PM', stakes: '$7,826 to go · 8h 46m left', line: 'Hot streak. Maybe I\'ve got this.', made: 2174, doors: 83, chat: [{ who: 'Jordan', t: '$20 says he quits by 3' }, { who: 'Tyler', t: 'free money for the boss lol' }], cy: 640 },
 { img: 's5.png', time: '2:34 PM', stakes: '$5,327 to go · 6h 26m left', line: 'Celsius #2. I can\'t miss right now.', made: 4673, doors: 136, chat: [{ who: 'Tyler', t: 'wait 4.6k already??' }], cy: 640 },
 { img: 's6.png', dark: 1, time: '5:11 PM', stakes: '$5,078 to go · 3h 49m left', line: 'Everyone\'s home. Nobody\'s buying.', made: 4922, doors: 158, ly: 395,
   lb: [{ i: 'TM', n: 'Tyler M.', v: 6180 }, { i: 'YOU', n: 'You', v: 4922, me: 1 }, { i: 'JK', n: 'Jordan K.', v: 3450 }, { i: 'SR', n: 'Sam R.', v: 2210 }],
   texts: [{ who: M, t: 'tick tock ⏰' }], ty: 895 },
 { img: 's7.png', dark: 1, time: '6:35 PM', stakes: '$2,767 to go · 2h 25m left', line: 'Second wind. Doors are opening.', made: 7233, doors: 205, chat: [{ who: 'Jordan', t: 'he might actually do it 👀' }, { who: 'Sam', t: 'no shot' }], cy: 640 },
 { img: 's8.png', dark: 1, time: '8:11 PM', stakes: '$2,767 to go · 49m left', line: 'Stuck on the same number for 90 minutes.', made: 7233, doors: 240, texts: [{ who: M, t: 'pay up tomorrow 💸' }], ty: 700 },
 { img: 's12.png', dark: 1, time: '8:13 PM', stakes: '$2,767 to go · 47m left', line: 'Last idea.', made: 7233, doors: 240, hy: 380,
   lh: [['12 Birchwood Cres', 'moved in 6 days ago'], ['48 Oakridge Dr', '9 days ago'], ['7 Linden Ct', '2 weeks ago'], ['31 Oakridge Dr', '2 weeks ago']] },
 { img: 's10.png', dark: 1, time: '8:15 PM', stakes: '$865 to go · 45m left', line: '2 back-to-back. The neighbours are NOT happy.', made: 9135, doors: 244, texts: [{ who: M, t: 'wait what' }], ty: 700 },
 { img: 's11.png', dark: 1, time: '8:53 PM', stakes: '7 minutes left', line: 'One door left.', madeText: '$?,???', pct: 96, doors: 262 },
 { img: 's12.png', dark: 1, time: '8:53 PM', line: 'Closed out. Beat it by $735.', made: 10735, doors: 263, sy: 420,
   sum: [['Made', '$10,735', 'goal hit ✓'], ['Doors', '263', ''], ['Hours', '10h 07m', ''], ['vs team avg', '2.7x', '']], texts: [{ who: M, t: '…' }], ty: 950 },
];
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1440 } });
  const go = async (f, q, o) => { await p.goto('file://' + path.resolve(f) + (q ? '?' + q : '')); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(300); await p.screenshot({ path: o }); };
  await go('hook.html', '', 'slide01.png');
  for (let i = 0; i < S.length; i++) await go('story.html', 'j=' + encodeURIComponent(JSON.stringify(S[i])), `slide${String(i + 2).padStart(2, '0')}.png`);
  await go('close.html', '', `slide${String(S.length + 2).padStart(2, '0')}.png`); await b.close(); })();
