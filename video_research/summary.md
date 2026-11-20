# Short-form video editing patterns: D2D niche vs general

Scraped 2026-11-20 with Apify ($4.82 spent). All 216 videos posted in the last 6 months were fully analyzed, covering scenes, key frames, OCR and transcripts:

- Niche: 122 videos (99 TikToks, 23 Instagram Reels) from #doortodoorsales, #d2dsales, #doorknocking, #solarsales, #pestcontrolsales, #salestips and matching searches.
- General: 94 TikToks from #fyp, #viral, #foryoupage, #trending and broad searches.

Virality is views divided by followers, with followers floored at 100. Each set was split into a top 25% (31 niche, 24 general) and a bottom 25%. Per-video data is in `short_form_videos.csv`, and the full table with p-values is in `comparison_table.md`.

## What separates top from bottom

1. **Winners leave natural pauses.** This is the only significant result, and it shows up in both sets. In the first 10 s, the longest pause was 0.55 s vs 0.39 s in niche videos (p = 0.04) and 0.89 s vs 0.40 s in general videos (p = 0.06).
2. **Winners talk slower and less.** Niche top videos spoke 2.9 vs 3.3 words/s (p = 0.08) and said 9 vs 10 words in the first 3 s. General winners barely talk at all (0.65 vs 2.0 words/s, p = 0.06), so they are visual or music-led.
3. **Winners open without a face.** A face appeared at 0 s in 29% of top niche videos vs 55% of bottom ones (p = 0.07), and at 1 s in 23% vs 48% (p = 0.06).
4. **Winners are a bit shorter.** Niche: 47 s vs 57 s (p = 0.08). General: 21 s vs 29 s.
5. **Winners cut earlier.** The first cut came at 3.0 s vs 6.5 s in general videos (p = 0.05) and 5.0 s vs 8.3 s in niche videos.

## What doesn't separate them (baseline practice)

- **Cut rate.** Niche videos make about 0.04-0.06 cuts per second, about 12 s per shot.
- **Hook text at 0 s.** 77-88% of videos have it, 6-8 words. In niche winners it sits at the top.
- **Motion or a cut at 0 s.** 86-94% of videos have it.
- **Starting speech at 0.0 s.** The median first word is at 0.0 s in both groups. Bottom niche videos were actually speaking by 0.5 s more often (87% vs 71%).
- **Captions.** 53% of niche videos use them and 16% of general. Top niche videos used them slightly less than bottom ones (42% vs 55%, not significant). They are mostly word-by-word, 2-3 words per chunk. Niche captions sit about 70% down the screen and general ones mid-screen.
- **Banner bars.** They are rare, at 3-10%.

## Niche vs general

- **Length.** Niche videos run about twice as long (50 s vs 27 s).
- **Shot length.** Niche shots are longer (12.5 s vs 8.3 s).
- **Talking.** Niche videos are much more talk-driven (3.0 vs 1.4 words/s in the first 10 s).
- **Captions.** Niche videos are far more likely to be captioned (53% vs 16%).

## Recommended changes

Applied in `SKILL.md`:

1. Open on motion, the doorstep or the app, and bring your face in after 1 s.
2. Put 6-8 words of hook text at the top from frame 0.
3. Start speaking within the first second at an unhurried pace. Cut filler words, but keep natural beats of 0.5-0.9 s.
4. Get the first cut in by 3-5 s, then let shots run.
5. Aim for 40-50 s in D2D and 15-25 s for broad reach.
6. Captions are optional. If you use them, go word-by-word, 2-3 words at a time, lower-middle of the screen.

## Gaps and caveats

- **Mixed transcript models.** The first 41 transcripts used Whisper "small" and the rest used "base" for speed. Word timing may differ slightly between the two.
- **Sample size.** 216 videos, below the 250 target. Half the hashtag results were older than 6 months, and Instagram downloads used about half the budget.
- **Detection error.** On-screen text uses Tesseract OCR, which misses some stylized captions. Face detection uses Haar cascades and misses profiles.
- **Statistical power.** With 24-31 videos per quartile, only large effects show as significant. Several results above are borderline (p = 0.05-0.08), so treat them as direction, not proof.
- **Metric bias.** Views divided by followers favors breakouts from tiny accounts.
