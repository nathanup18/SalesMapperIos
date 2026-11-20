---
name: "short-form-video-edit"
description: "Edit Nathan's raw short-form footage (SalesMapper / D2D sales Reels, TikToks, Shorts) into a cut list, caption spec and overlay plan using retention heuristics."
---

# Short-form video edit playbook (v2)

Targets and the first-3-seconds checklist were updated 2026-11-20 from a scrape of 190 short-form videos posted in the previous 6 months (98 D2D-niche TikToks and Reels, 92 general TikToks), ranked by views divided by followers. No single editing choice separated the top quartile from the bottom quartile with statistical confidence, so these numbers describe what working videos in this niche do, not guaranteed causes. Details: video_research/summary.md in the SalesMapperIos repo.

## Inputs
- Raw clip(s) and, if possible, a transcript with word timestamps (run Whisper if none).
- The one point of the video and the conversion action (default: free trial, link in bio).

## Targets (scrape-based, 2026-11-20)
| Element | Target |
|---|---|
| Length | 15-30 s for broad reach (general top quartile median 18 s vs 29 s bottom). D2D tips/stories can run 45-60 s (niche median 50 s in both quartiles). Avoid drifting past 90 s. |
| Hook | Spoken from 0.0 s (median first word at 0.0 s). 8-10 spoken words in the first 3 s, about 3 words per second. |
| First visual change | First cut or visual change by 2-4 s (general top quartile 2.2 s vs 6.0 s bottom; niche 4.4 s vs 7.7 s). |
| Visual change after that | Shots in this niche average 8-12 s (0.06 cuts per second). Don't force a cut every 2-4 s. Keep the shot moving instead: handheld walk-up, gestures, punch-ins. |
| Dead air | Remove filler words and pauses over ~0.7 s. Top niche videos kept short natural pauses (longest pause in first 10 s: median 0.7 s). |
| Captions | Optional. Only ~30% of niche videos had them. When used: 1-3 words per chunk (median 2), one line. |
| Caption position | 65-70% of the way down the screen (lower-middle), clear of the bottom UI and right-side buttons. Never over the face. |
| Banner bar | Rare (4-8% of videos). Use only for list/explainer formats, not as a default. |

## First 3 seconds checklist (scrape-based, 2026-11-20)
1. Frame 1 has motion or a cut (87-92% of videos do). A face is not required: top niche videos showed a face at 0 s less often than bottom ones (36% vs 56%).
2. Hook text on screen from frame 0 (83-88% of videos). 8-10 words. Top-of-screen in niche winners; lower-middle is common in general. Keep it clear of the caption line.
3. Talking starts at 0.0 s, with 8-10 words in the first 3 s. No intro, no breath.
4. Hook is specific: a number, a result, or a contrarian claim aimed at D2D owners/reps (e.g. "My reps log a door in 1 tap from the lock screen").
5. First cut or visual change lands by 2-4 s.
6. If the strongest visual is the app (map full of pins, lock screen pin drop), show it in second 0-2 instead of the talking head.

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