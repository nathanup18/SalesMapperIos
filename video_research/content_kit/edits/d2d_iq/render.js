const { chromium } = require('playwright'); const fs = require('fs'); const path = require('path');
(async () => { const T = JSON.parse(fs.readFileSync('terms.json')); const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  for (const t of T) { await p.goto('file://' + path.resolve('cards.html') + '?k=' + t.key + '#' + encodeURIComponent(JSON.stringify(t)));
    await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(120); await p.screenshot({ path: `card_${t.key}.png`, omitBackground: true }); }
  await b.close(); })();
