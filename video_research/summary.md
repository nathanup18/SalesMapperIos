# Short-form video editing patterns: D2D niche vs general

Scraped 2026-11-20 with Apify ($4.82 spent). 216 videos posted in the last 6 months were analyzed:

- Niche: 122 videos (99 TikToks, 23 Instagram Reels) from #doortodoorsales, #d2dsales, #doorknocking, #solarsales, #pestcontrolsales, #salestips and matching searches.
- General: 94 TikToks from #fyp, #viral, #foryoupage, #trending and broad searches.

Virality is views divided by followers, with followers floored at 100. Each set was split into a top 25% (31 niche, 24 general) and a bottom 25%. Per-video data is in `short_form_videos.csv`, and the full table with p-values is in `comparison_table.md`.

## What separates top from bottom

1. **Winners keep natural pauses.** This is the only significant result. In the first 10 s, the longest pause was 0.57 s in top niche videos vs 0.28 s in bottom ones (p = 0.02). Top videos also spoke slightly slower (3.0 vs 3.4 words/s). Cutting every breath appears to hurt.
2. **Winners open without a face.** A face appeared at 0 s in 29% of top niche videos vs 55% of bottom ones (p = 0.07), and at 1 s in 23% vs 48% (p = 0.06). Top videos also had more motion at 0 s (pixel difference 18.8 vs 12.7, not significant).
3. **Winners are a bit shorter.** Niche: 47 s vs 57 s (p = 0.08). General: 21 s vs 29 s (p = 0.31).
4. **Winners cut earlier.** The first cut came at 3.0 s vs 6.5 s in general videos (p = 0.05) and 5.0 s vs 8.3 s in niche videos (not significant).

## What doesn't separate them (baseline practice)

- **Cut rate.** Niche videos make 0.04-0.06 cuts per second, about 12 s per shot, in both quartiles. A cut every 2-4 s is not the norm here.
- **Opening.** About 82-88% have text on screen at 0 s (8-9 words, at the top in niche winners). About 86-94% have motion or a cut at 0 s. Speech starts at 0.0 s, with about 9 words in the first 3 s.
- **Captions.** About half of niche videos use them, with the same rate in top and bottom (44% vs 43%). They are mostly word-by-word, 2 words per chunk, about 70% down the screen.
- **Banner bars.** They are rare, at 3-10%.

## Niche vs general

- **Length.** Niche videos run about twice as long (50 s vs 27 s median).
- **Shot length.** Niche shots are longer (12.5 s vs 8.3 s, p < 0.01).
- **Hook text position.** It sits at the top in niche videos and lower-middle in general ones.
- **Openings.** Both sets share the same patterns: text at 0 s, motion at 0 s, about 8-word hook text.

## Recommended changes

Applied in `SKILL.md`:

1. Open on motion, the doorstep or the app, and bring your face in after 1 s.
2. Put 8 words or fewer of hook text at the top from frame 0.
3. Start speaking at 0.0 s, but don't strip natural pauses. Leave beats up to about 0.6 s.
4. Get the first cut in by 3-5 s, then let shots run.
5. Aim for 40-50 s in D2D and 15-25 s for broad reach.
6. Captions are optional. If you use them, go word-by-word, 2 words at a time, lower-middle of the screen.

## Gaps and caveats

- **Transcripts.** Transcription was still running when this was written, so speech and caption numbers come from about 77 niche videos (25 top, 14 bottom) and none from general. Videos without a transcript are marked `not transcribed` in the CSV.
- **Sample size.** 216 videos, below the 250 target. Half the hashtag results were older than 6 months, and Instagram downloads used about half the budget.
- **Detection error.** On-screen text uses Tesseract OCR, which misses some stylized captions. Face detection uses Haar cascades and misses profiles.
- **Statistical power.** With 24-31 videos per quartile, only large effects show as significant, and several of the results above are borderline (p = 0.05-0.08).
- **Metric bias.** Views divided by followers favors breakouts from tiny accounts.
