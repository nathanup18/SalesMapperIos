const { chromium } = require('playwright'); const fs = require('fs'); const path = require('path');
(async () => { const T = JSON.parse(fs.readFileSync('terms.json')); const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 }); p.on('console', m => console.log(process.env.PFX || 'card_', m.text()));
  for (const t of T) { await p.goto('file://' + path.resolve(process.env.PAGE||'cards.html') + '?k=' + t.key + '#' + encodeURIComponent(JSON.stringify(t)));
    await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(120); await p.screenshot({ path: `${process.env.PFX||'card_'}${t.key}.png`, omitBackground: true }); }
  await b.close(); })();
