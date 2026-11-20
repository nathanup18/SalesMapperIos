# Short-form video editing patterns: D2D niche vs general

Scraped 2026-11-20 with Apify ($4.82 spent). 190 videos posted in the last 6 months were analyzed:

- Niche: 98 videos (TikTok plus 23 Instagram Reels) from #doortodoorsales, #d2dsales, #doorknocking, #solarsales, #pestcontrolsales, #salestips and matching searches.
- General: 92 TikToks from #fyp, #viral, #foryoupage, #trending and broad searches.

Virality is views divided by followers, with followers floored at 100. Each set was split into a top 25% and a bottom 25%. Per-video data is in `short_form_videos.csv`, and the full table with p-values is in `comparison_table.md`.

## What the data says

1. **No editing metric clearly separates winners from losers.** Every top-vs-bottom difference had p > 0.05 except one: the first cut in general videos (2.2 s vs 6.0 s, p = 0.05). Editing choices are table stakes. The hook topic and the account getting pushed to non-followers probably matter more.

2. **Winners are small accounts breaking out.** The niche top quartile had a median of 131,800 views against small followings. The bottom quartile had a median of 6,540 views, mostly from bigger accounts.

3. **Length.** General winners are short: a median of 18 s, against 29 s for the bottom quartile. Niche videos run about 50 s in both quartiles, so in D2D, length doesn't hurt up to around 60 s.

4. **The first cut comes earlier in winners.** The first cut lands at 2.2 s vs 6.0 s (general) and 4.4 s vs 7.7 s (niche). But overall cut rate is low and the same in both groups: 0.06-0.07 cuts per second, with average shots of 8-12 s. A cut every 2-4 s is not what this niche does.

5. **Universal openers.** About 87-92% have motion or a cut at 0 s, 80-88% have text on screen at 0 s (8-10 words), and the median first spoken word is at 0.0 s. Most videos say 8-10 words in the first 3 s.

6. **Faces are optional.** Top niche videos showed a face at 0 s less often than bottom ones (36% vs 56%) and had more motion at 0 s (pixel difference 18.9 vs 12.1). The difference isn't significant, but the direction favors motion over a talking head.

7. **Captions are less common than expected.** Only about 30% of transcribed niche videos had burned-in captions detected. When present, they show 1-3 words per chunk (median 2), placed about 65-70% down the screen.

8. **Banner bars are rare.** They appear in 4-8% of videos.

## Gaps and caveats

- **Transcripts.** Only 41 of 190 videos (all niche) were transcribed before the run was stopped. Speech and caption figures are niche-only: 14 top and 8 bottom videos. Videos without a transcript are marked `not transcribed` in the CSV, and their pop-up counts are blank.
- **Missing videos.** 26 of the 216 downloaded videos were not analyzed. Both runs were stopped early, the visual pass at 190 of 216.
- **Sample size.** The sample is below the 150 niche / 100 general target. Half the hashtag results were older than 6 months, and Instagram downloads used about half the budget.
- **Detection error.** On-screen text uses Tesseract OCR, which misses some stylized captions, so caption usage is likely undercounted. Face detection uses Haar cascades and misses profiles and small faces.
- **Statistical power.** With about 25 videos per quartile, only large effects would show up as significant.
- **Metric bias.** Views divided by followers favors one-off breakouts from tiny accounts.
