const { chromium } = require('playwright'); const path = require('path');
const M = 'Manager', T = 'Team 🏠';
const S = [
 { img: 's_am.png', big: '10 hours<br>1 celsius<br>$500 on the line', line: '(miss by $1 and he wins)' },
 { img: 's_cel.png', time: '10:46 AM', tag: 'Saturday', stakes: '$10,000 to go · 10h 14m left', line: 'celsius down the hatch let\'s go', made: 0, doors: 0 },
 { img: 's_noon.png', time: '11:42 AM', stakes: '$1,131 · 51 doors · 9h 18m left', line: 'already behind and he knows it', texts: [{ who: M, t: 'lol u good? 😂' }], ty: 640 },
 { img: 's_rep.png', time: '12:14 PM', stakes: '$2,174 · 83 doors · 8h 46m left', line: 'ok we might be cooking', chat: [{ who: 'Jordan', t: '$20 he quits by 3' }, { who: 'Tyler', t: 'bro is cooked 💀' }], cy: 640 },
 { img: 's5.png', time: '2:34 PM', stakes: '$4,673 · 136 doors · 6h 26m left', line: 'celsius #2 and I can\'t miss rn', chat: [{ who: 'Tyler', t: '4.6k?? who is he knocking' }], cy: 640 },
 { img: 's6.png', dark: 1, time: '5:11 PM', stakes: '$4,922 · 158 doors · 3h 49m left', line: 'everyone\'s home and nobody\'s buying', ly: 460,
   lb: [{ i: 'TM', n: 'Tyler M.', v: 6180 }, { i: 'YOU', n: 'You', v: 4922, me: 1 }, { i: 'JK', n: 'Jordan K.', v: 3450 }, { i: 'SR', n: 'Sam R.', v: 2210 }],
   texts: [{ who: M, t: 'tick tock ⏰' }], ty: 960 },
 { img: 's7.png', dark: 1, time: '6:35 PM', stakes: '$7,233 · 205 doors · 2h 25m left', line: 'second wind, doors are opening', chat: [{ who: 'Jordan', t: 'wait he might actually do it 👀' }, { who: 'Sam', t: 'no shot' }], cy: 640 },
 { img: 's8.png', dark: 1, time: '8:11 PM', stakes: '$2,767 to go · 49m left', line: 'same number for 90 minutes', made: 7233, doors: 240, texts: [{ who: M, t: 'venmo me tmrw 💸' }], ty: 700 },
 { img: 's12.png', dark: 1, time: '8:13 PM', stakes: '$7,233 · 240 doors · 47m left', line: 'last idea: lead hunter', sub: 'shows who just moved in nearby', hy: 500,
   lh: [['12 Birchwood Cres', 'moved in 6 days ago'], ['48 Oakridge Dr', '9 days ago'], ['7 Linden Ct', '2 weeks ago'], ['31 Oakridge Dr', '2 weeks ago']] },
 { img: 's_mov.png', dark: 1, time: '8:14 PM', stakes: '$7,233 · 241 doors · 46m left', line: 'first one still has boxes in the garage 👀' },
 { img: 's10.png', dark: 1, time: '8:15 PM', stakes: '$9,135 · 244 doors · 45m left', line: '2 back to back and the neighbours are NOT happy', texts: [{ who: M, t: 'wait what' }], ty: 700 },
 { img: 's11.png', dark: 1, time: '8:53 PM', stakes: '7 minutes left', line: 'one door left', madeText: '$?,???', pct: 96, doors: 262 },
 { img: 's12.png', dark: 1, time: '8:53 PM', line: 'closed out, beat it by $735', sy: 420,
   sum: [['Made', '$10,735', 'goal hit ✓'], ['Doors', '263', ''], ['Hours', '10h 07m', ''], ['vs team avg', '2.7x', '']], texts: [{ who: M, t: '…' }], ty: 950 },
];
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1440 } });
  const go = async (f, q, o) => { await p.goto('file://' + path.resolve(f) + (q ? '?' + q : '')); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(300); await p.screenshot({ path: o }); };
  await go('hook.html', '', 'slide01.png');
  for (let i = 0; i < S.length; i++) await go('story.html', 'j=' + encodeURIComponent(JSON.stringify(S[i])), `slide${String(i + 2).padStart(2, '0')}.png`);
  await go('close.html', '', `slide${String(S.length + 2).padStart(2, '0')}.png`); await b.close(); })();
