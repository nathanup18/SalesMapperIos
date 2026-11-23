# Handoff: Nathan's short-form video editing (continue here)

Start by loading the skill/playbook: `video_research/SKILL.md` → `video_research/edit_playbook/PLAYBOOK.md` (v16) and the latest entries in `edit_playbook/FEEDBACK_LOG.md` (F29-F42). Repo `nathanup18/SalesMapperIos`, branch `claude/zen-cori-hyds6x`. Hard rules override everything. The two newest and most important:
- **H0:** never change brightness, saturation or the look of Nathan's footage without asking. Keep his iPhone HDR (HLG, bt2020, 10-bit x265) untouched; graphics are converted INTO HLG.
- **H16:** ask formatting questions with AskUserQuestion pop-ups (multiple choice). He wants speed: ship, then refine. Keep messages short.

## Where things are (2026-11-23)
- Drive root: "01 Raw footage" folder id `1cDn_s_B8QtmA_NjNe3a4RDy-mh3BL_9O`; previews go to "06 Final renders" `1SCjyI2hP7uj2l-mg8ZeHlgfy6qOZCo4N`.
- Edited raw footage lives in dated "(edited)" subfolders. Latest: `2026-11-23 · Business IQ (edited)` (id `1-XAJOGErEG_mGizTE4dufNJ4cehpIvpE`, IMG_9866-9875, every file uploaded twice, copies identical) and `2026-11-23 · D2D Sales IQ (edited)`.
- The Bryson Bowman reference screen recording stays at the top of Raw footage (`ScreenRecording_11-23-2026 00-17-25_1.mp4`, id `1ouIfJtV7JjeddMZUPs1TAwTP1kUGgPuw`). Nathan is about to add a new subfolder.
- Downloading big clips: temp-share "anyone with link" (pre-approved, F21), then `curl -sL "https://drive.usercontent.google.com/download?id=<ID>&export=download&confirm=t"`. Remind him to set shares back to Restricted (the connector can't remove them).

## Last shipped: Business IQ (Instagram + TikTok), 20.5 s
Code: `video_research/content_kit/edits/business_iq/`
- `build.py`: tight cut (F36/F40) of hook IMG_9870, batches 9871-9874, outro = complete 2nd take of 9875 from 6.6 s (1st take stops at "run a real busi-"); drops <0.2 s breath slivers; writes `seg/main.mov` (HDR) + `seg/cards.json` (card windows per spoken term).
- `build2.py`: 1.2x bottom-anchored zoom (face moves up), header "Business IQ (owner edition)", one-word Instrument Serif captions (140 px) on hook/outro, red "follow for more" box held to end, 16 spec-sheet cards converted to HLG (white at 88% signal) and overlaid. TikTok variant via env: `PFX=card_tt_ OVL=overlay_tt.html CAP=cap_tt HL=hlg_tt OUTF=business_IQ_tiktok.mp4 python3 build2.py`.
- Cards: `cards.html` (Instagram, scale 1.2, x 60-1019, y 1222-1749), `cards_tt.html` (TikTok, scale 1.08, x 34-897, clear of right rail), `terms.json` (16 terms in spoken order), `render.js` (`PAGE=... PFX=... node render.js`). Needs a `cards` symlink to `.` in the working dir, plus fonts Instrument Serif, IBM Plex Mono and Inter as full TTFs in ~/.fonts.
- Words: `words.json` (Whisper, with the 9875 second-take words patched in).
- **Gotcha:** never run two renders at once. Overlapping build2 runs corrupted the AAC audio and overwrote card sizes. Run Instagram, then TikTok, sequentially, then check `ffmpeg -v error -i out.mp4 -f null -` prints nothing.

## DONE (F43, F45): card shape variety. Shipped v2: wide, wide, square (reference proportions), card tops track the chin via chin.py. Pipeline: build.py, chin.py (YUNET=model path), render.js (IG then TikTok), build2.py IG then TikTok, delivery_check.py.

## (old) NEXT TASK 1: card shape variety (Nathan's request)
"I just want some variance: some square, some rectangle long side down, some rectangle short side down."
- Give the 16 cards a mix of three shapes, so consecutive cards don't share a shape:
  - Wide (current, landscape, long side down)
  - Square (~620x620 at Instagram scale)
  - Tall (portrait, ~520x700, short side down)
- Each shape needs its own internal layout (the left/right label columns stack above or below the diagram on square and tall cards).
- Keep everything else the same: opaque, below the chin (top ≥ ~1220 after the zoom), clear of the TikTok right rail in `cards_tt.html`.
- Suggested rotation: wide, square, tall, wide, ... or pick shapes per diagram (tall for funnels/arcs, square for pies/gauges).
- Re-render the cards, then run build2 for Instagram, then TikTok (sequentially), check the audio decodes cleanly, and send both.

## Other open items
- Post caption chosen for D2D Sales IQ: comment "IQ" for the cheat sheet. Offer to build the 16-term cheat-sheet PDF (definitions are in the terms.json files).
- A business-terms cheat sheet could reuse the same comment-trigger caption.
- Shared files still on "anyone with link": all the raw clips from 2026-11-21 to 23 (in the "(edited)" folders). Remind Nathan to restrict them.
- The Higgsfield file host (d8j0ntlcm91z4.cloudfront.net) is allowed in the environment; 86 credits left.
- Card numbers are illustrative ($4,800 LTV, $310 CAC, etc.); swap in real numbers if he sends them.
