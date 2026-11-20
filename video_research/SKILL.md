---
name: "short-form-video-edit"
description: "Edit Nathan's raw short-form footage (SalesMapper / D2D sales Reels, TikToks, Shorts) into a cut list, caption spec and overlay plan using retention heuristics."
---

# Short-form video edit playbook (v2)

Targets and the first-3-seconds checklist were updated 2026-11-20 from a scrape of 216 short-form videos posted in the previous 6 months (122 D2D-niche TikToks and Reels, 94 general TikToks), ranked by views divided by followers. Only one difference between the top and bottom quartiles was statistically significant (pause length, p = 0.02). The rest describe what working videos in this niche do, not proven causes. Details: video_research/summary.md in the SalesMapperIos repo.

## Inputs
- Raw clip(s) and, if possible, a transcript with word timestamps (run Whisper if none).
- The one point of the video and the conversion action (default: free trial, link in bio).

## Targets (scrape-based, 2026-11-20)
| Element | Target |
|---|---|
| Length | D2D: 40-50 s (niche top quartile median 47 s vs 57 s bottom, p = 0.08). Broad-reach: 15-25 s (general top 21 s vs 29 s). Avoid going past 60 s. |
| Hook | Spoken from 0.0 s. About 9 spoken words in the first 3 s, roughly 3 words per second. Don't rush: top videos spoke slightly slower (3.0 vs 3.4 words/s). |
| First visual change | First cut or visual change by 3-5 s (general top 3.0 s vs 6.5 s bottom; niche 5.0 s vs 8.3 s). |
| Visual change after that | Niche shots average about 12 s (0.04-0.06 cuts per second) in both quartiles. Cut rate doesn't separate winners, so don't force a cut every 2-4 s. Keep the shot moving instead: walk-ups, gestures, punch-ins. |
| Dead air | Remove filler words, but leave natural beats of up to ~0.6 s. Top niche videos had a longer longest pause than bottom ones (0.57 s vs 0.28 s, p = 0.02). Over-tightened, breathless audio did worse. |
| Captions | Optional. About half of niche videos use them, with no difference between top and bottom. When used: word-by-word, 2 words per chunk, one line. |
| Caption position | About 70% of the way down the screen (lower-middle), clear of the bottom UI and right-side buttons. Never over the face. |
| Banner bar | Rare (3-10% of videos). Use only for list/explainer formats, not as a default. |

## First 3 seconds checklist (scrape-based, 2026-11-20)
1. Open on motion or the scene, not a talking head. Top niche videos showed a face at 0 s in 29% of cases vs 55% for bottom ones (p = 0.07), and at 1 s in 23% vs 48% (p = 0.06). Bring the face in after the first second.
2. Frame 1 has motion or a cut (86-94% of videos do).
3. Hook text on screen from frame 0 (82-88% of videos), 8 words or fewer, at the top of the screen (the most common spot in niche winners). Keep it clear of the caption line.
4. Talking starts at 0.0 s, about 9 words in the first 3 s.
5. Hook is specific: a number, a result, or a contrarian claim aimed at D2D owners/reps (e.g. "My reps log a door in 1 tap from the lock screen").
6. If the strongest visual is the app (map full of pins, lock screen pin drop), show it in second 0-2. This fits point 1.

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
3. Produce the visual-change plan: for each 2-4 s window, what changes (cut, punch-in, b-roll, screen recording).
4. Produce the overlay list: timestamp, text, position, duration.
5. Produce the caption spec (style above) or burn captions with ffmpeg if rendering here.
6. Output either a CapCut step list Nathan can follow, or a rendered MP4 if the footage is in the workspace.
7. Check against the targets table before delivering and list any target the footage can't meet.

## After posting
At 48 h, log for each video: views, 3-second hold %, average % watched, profile visits/link clicks. After 10+ videos, compare against the defaults above and update them.