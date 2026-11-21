---
name: "short-form-video-edit"
description: "Edit Nathan's raw short-form footage (SalesMapper / D2D sales Reels, TikToks, Shorts) into a cut list, caption spec and overlay plan using retention heuristics."
---

# Short-form video edit playbook (v3)

Targets and the first-3-seconds checklist were updated 2026-11-20 from a scrape of 216 short-form videos posted in the previous 6 months (122 D2D-niche TikToks and Reels, 94 general TikToks), ranked by views divided by followers. Only one difference between the top and bottom quartiles was statistically significant: winners leave longer natural pauses (niche p = 0.04, general p = 0.06). The rest describe what working videos in this niche do, not proven causes. Details: video_research/summary.md in the SalesMapperIos repo.

## Inputs
- Raw clip(s) and, if possible, a transcript with word timestamps (run Whisper if none).
- The one point of the video and the conversion action (default: free trial, link in bio).

## Targets (scrape-based, 2026-11-20)
| Element | Target |
|---|---|
| Length | D2D: 40-50 s (niche top quartile median 47 s vs 57 s bottom, p = 0.08). Broad-reach: 15-25 s (general top 21 s vs 29 s). Avoid going past 60 s. |
| Hook | Hook text carries the open. Speech within the first second, about 9 words in the first 3 s. Don't rush: top niche videos spoke slower (2.9 vs 3.3 words/s, p = 0.08), and general winners talked far less (0.65 vs 2.0 words/s). |
| First visual change | First cut or visual change by 3-5 s (general top 3.0 s vs 6.5 s bottom; niche 5.0 s vs 8.3 s). |
| Visual change after that | Niche shots average about 12 s (0.04-0.06 cuts per second) in both quartiles. Cut rate doesn't separate winners, so don't force a cut every 2-4 s. Keep the shot moving instead: walk-ups, gestures, punch-ins. |
| Dead air | Remove filler words, but leave natural beats of 0.5-0.9 s. Winners had longer pauses in both sets (niche 0.55 s vs 0.39 s, p = 0.04; general 0.89 s vs 0.40 s, p = 0.06). Over-tightened, breathless audio did worse. |
| Captions | Optional. 53% of niche videos and 16% of general use them, and top niche videos used them slightly less than bottom ones (42% vs 55%, not significant). When used: word-by-word, 2-3 words per chunk, one line. |
| Caption position | Below the chin, never over the mouth. Measure the face per shot and center captions about 90 px under the lowest chin position (about 84% down on 1080x1920, y≈1610). On inserts/B-roll keep the same y so captions don't jump. Old research default was 70% down (lower-middle), clear of the bottom UI and right-side buttons. Never over the face. |
| Banner bar | Rare (3-10% of videos). Use only for list/explainer formats, not as a default. |

## First 3 seconds checklist (scrape-based, 2026-11-20)
1. Talking-head videos (Nathan's preference, overrides the research below): open on the face, with no cutaway, software or B-roll over the first ~2 s hook line. Cutaways start after the hook. For non-talking-head videos: open on motion or the scene, not a talking head. Top niche videos showed a face at 0 s in 29% of cases vs 55% for bottom ones (p = 0.07), and at 1 s in 23% vs 48% (p = 0.06). Bring the face in after the first second.
2. Frame 1 has motion or a cut (86-94% of videos do).
3. Hook text on screen from frame 0 (77-88% of videos), 6-8 words (niche winners median 6), at the top of the screen (the most common spot in niche winners). Keep it clear of the caption line.
4. Speech starts within the first second, about 9 words in the first 3 s, at an unhurried pace. Starting at exactly 0.0 s doesn't separate winners (bottom videos did it more often).
5. Hook is specific: a number, a result, or a contrarian claim aimed at D2D owners/reps (e.g. "My reps log a door in 1 tap from the lock screen").
6. If the strongest visual is the app (map full of pins, lock screen pin drop), show it in second 0-2. This fits point 1.

## Visual aids (custom animated inserts)
Wherever the speaker names something concrete and there's no real B-roll for it, build a custom animated insert that shows it, and cut back and forth between it and the face.
- What to show: the literal noun or action. Examples used: a $1,000 gift card bundle mockup (count-up, card fan, business tags), a "before you pitch" card with 2-3 question bubbles ticking off, a street of houses where not-home pins flip to "Re-knock" as a service truck drives by, a referral loop between local businesses, a give-first/get-back loop.
- Timing: start about 0.05 s before the key word, end about 0.1 s after the phrase ends (use Whisper word timestamps). Inserts run 1.3-4 s. Audio keeps playing underneath (L-cut).
- Cadence: return to the face between inserts; aim for a visual change every 3-6 s across the body. Never in the first ~2 s hook.
- Look: brand background #F7F4EC, Nunito Sans (900 for numbers/titles), ink #1C1C1A, pin colors for status (green = win, orange = re-knock, indigo = not home, red = no). Spring/ease animations driven by one clock, no jitter. Small uppercase kicker line on top that restates the point in 3-5 words.
- Layout: keep the top ~450 px clear for the section label and keep content above y≈1540 so captions stay readable.
- Real B-roll wins when it exists (e.g. handshake for "partnered with local businesses"); use stock only when it actually matches the words.
- Build with video_research/content_kit/inserts.html + render.js (60 fps PNG frames to ffmpeg); add a new scene per visual.

## Pop-ups and overlays
- When a number, tool name or result is spoken, show it on screen within the same beat (text pop, screenshot, or screen recording).
- Product footage appears once the problem is set up, unless the product shot is the hook.
- For list or explainer videos, use a persistent top banner bar with the title (e.g. "3 reasons reps skip doors") for the whole video.
- One overlay at a time. Don't stack text on top of captions.

## Ending
- Last 2 s: CTA as text ("Free trial, link in bio") plus spoken line, or cut so the end loops back into the hook.
- No outro card, no logo sting.

## Procedure
1. Transcribe; mark the hook line, the payoff line and the CTA.
2. Produce a cut list: keep/remove with timestamps; move the strongest line to the start if the opener is weak.
3. Produce the visual-change plan: alternate 100%/112% punch-ins on every jump cut, then list each spoken point that gets real B-roll or a custom animated insert (see Visual aids), with word-timed in/out points.
4. Produce the overlay list: timestamp, text, position, duration.
5. Produce the caption spec (style above) or burn captions with ffmpeg if rendering here.
6. Output either a CapCut step list Nathan can follow, or a rendered MP4 if the footage is in the workspace.
7. Check against the targets table before delivering and list any target the footage can't meet.

## After posting
At 48 h, log for each video: views, 3-second hold %, average % watched, profile visits/link clicks. After 10+ videos, compare against the defaults above and update them.