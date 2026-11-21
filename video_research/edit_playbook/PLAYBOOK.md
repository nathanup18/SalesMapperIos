# Short-form video edit playbook (living)

Version: 7 (2026-11-21)
Owner: Nathan. This file is the source of truth for the `short-form-video-edit` skill. The skill loads it at the start of every run and updates it whenever Nathan gives feedback (see "Learning protocol" at the bottom). Never treat it as frozen.

Rule priority, highest first:
1. Hard rules (Nathan's explicit feedback). These override everything below.
2. Nathan's stated preferences.
3. Research defaults (from the 216-video scrape, 2026-11-20). Use these only where 1 and 2 are silent.

---

## 1. Hard rules (from Nathan's feedback, never break these)

Each rule links to its entry in FEEDBACK_LOG.md.

H1. No dead space. [F1, F6, F9]
- Every segment starts no more than 0.07 s before the first audible phoneme and ends no more than 0.15 s after the last one. This includes the very first frame of the video, which is the one most often missed.
- Inside a take, shorten every pause longer than 0.3 s to about 0.2 s. Nathan prefers tight cuts over the research's "leave 0.5-0.9 s beats".
- Remove false starts and retakes, keeping the last clean take.
- Find cut points from the audio waveform (10 ms RMS), not from Whisper word times alone. Whisper starts words 0.1-0.4 s early.
- Keep segment audio as PCM (WAV in MKV) until the one final AAC encode. Joining AAC segments adds about 21 ms of encoder delay per cut, so by the end of a 10-cut video the audio sits 0.2 s behind the picture. That reads as dead air at section starts and slightly out-of-sync lips. [F15]
- If frame 0 shows a hand or the phone being set down, hold the first clean frame over those frames and keep the audio. Never delay the speech to hide it. [F17]
- Verify on the rendered file, not the plan. Re-transcribe the output to prove no word was clipped, and run qa_check.py (dead-air check at frame 0 and at every segment start).

H2. Captions never cover the mouth. [F2]
- Measure the face on every shot. Center captions about 90 px below the lowest chin position: y≈1610 on 1080x1920 for Nathan's usual framing. Punch-ins push the chin lower, so measure those shots too.
- Keep the same caption y on inserts and B-roll so captions don't jump.

H3. Talking-head videos open on Nathan's face. [F3]
- No app, software, B-roll or graphic over the hook line, roughly the first 2 s.
- Don't put software or app UI over him unless the video is about the app.

H4. Use custom animated visuals where there's no B-roll, and cut back and forth. [F4]
- Wherever he names something concrete (a gift card, questions, re-knocking, referrals, a give-and-get exchange), build an animated insert that shows it.
- Return to his face between inserts. See section 4.

H5. No flashes. [F5, F8]
- When a section opens with a graphic, the graphic starts on the section's first frame, with zero face frames before it.
- Two graphics in a row cut directly from one to the other, with no face frame between them.
- Snap every cut, insert and label boundary to the 30 fps frame grid. Labels and graphics switch on the same frame.
- Check every boundary frame-by-frame (±3 frames) before delivering.
- Pre-render each insert as a full-timeline clip starting at t=0, padded by repeating its first frame (never black), and overlay it without input offsets. Offsets and black padding caused late starts and black frames. [F16]

H6. Animations play to completion. [F7]
- An insert stays on screen at least as long as its animation, with every element finished and held for about 0.4 s.
- If the spoken window is too short, widen it to the surrounding phrase or retime the animation to fit. Never cut a graphic mid-draw.

H7. Order follows the content, and the strongest story is the payoff or the lead. [F10, F11]
- Keep the spoken numbering consistent ("One is…"). If clips are reordered, cut the spoken number so it still makes sense ("One is simply asking" becomes "Simply asking").
- Nathan picked the $1,000 gift card story as the strongest point and wants it leading in the "give first" version.

H8. Post caption: lead with the most concrete story and its outcome, and end with a follow CTA. [F12, F13]
- The goal is followers. The first line is the strongest concrete moment (for example, "We handed every homeowner $1,000 in local gift cards before we pitched."). The next line is what happened after (the outcome). The last line is "Follow for more D2D tips".
- Don't just list all the tips in the caption.

H9. Don't touch contrast. [F18]
- No eq or contrast, saturation or gamma grade. Only convert HDR (HLG/bt2020) to SDR bt709 color space: `zscale=tin=bt709:t=bt709:min=bt2020nc:m=bt709:pin=bt2020:p=bt709:rin=tv:r=tv,format=yuv420p`.

H10. The hook headline is big and black. [F19]
- White card, black (#000) text in Nunito Sans Black, no colored words. It fills up to the top third: box top at y≥180 (below the TikTok/Reels top bar), bottom at y≤640, side margins ≥60 px (box width about 960 px), text about 110-125 px, 2-3 lines.
- It should jolt the viewer. Size up rather than down, but never past the margins or the top third.

---

## 2. Nathan's preferences (soft, but default to these)
- **Captions:** word-by-word, 2 words per chunk, uppercase Nunito Sans Black 96 px, white with a dark outline, active word green #34C759.
- **Section labels:** a white rounded pill at the top (y≈250), with a green number circle and 3-5 words.
- **Hook text:** see H10 (big, black, top third). 6-8 words.
- **Jump cuts:** alternate 100% and 112% punch-ins on every cut inside a take.
- **Color:** iPhone footage is HLG HDR. Use only the color-space conversion in H9. No contrast grade. Don't use hable or mobius tonemapping; they push skin red.
- **Audio:** highpass at 70 Hz, loudnorm to I=-14, TP=-1.5. Use a 10-15 ms fade at every cut.
- **Music:** never bake music into the file. Nathan adds a trending sound in the TikTok or Instagram app at 5-10% volume, instrumental, without lyrics.
- **Ending:** his spoken CTA plus a text pill ("Follow for more D2D tips"). No outro card, no logo sting.

---

## 3. Research defaults (216-video scrape, 2026-11-20; use when sections 1-2 are silent)
| Element | Default |
|---|---|
| Length | D2D 35-50 s. Broad reach 15-25 s. Avoid going past 60 s. |
| Hook | About 9 spoken words in the first 3 s, unhurried (about 3 words/s). |
| First visual change | Within 3-5 s, which is after the face-first hook. |
| Visual change after that | Every 3-6 s through the body, using punch-ins, inserts and B-roll. |
| Banner bar | Rare (3-10%). Only for list formats. |
Full data: video_research/summary.md and comparison_table.md.

---

## 4. Visual aids (custom animated inserts)
- **What to show:** the literal noun or action. Library so far, in content_kit/inserts.html:
  - `questions`: a "before you pitch" card with 3 question bubbles that tick off, then "Then pitch →"
  - `reknock`: a street of houses where not-home pins flip to orange "Re-knock" as a service truck drives by
  - `referrals`: a loop between a coffee shop, an auto shop and "Your team", with arrowheads and moving dots (2.25 s)
  - `giftcard`: a $1,000 local gift card bundle that flies in, counts up and fans into more cards, with business tags
  - `reciprocity`: a You → Homeowner loop, "Value" out and "Trust + the sale" back
- **Timing:** start 0.05 s before the key word and end 0.1 s after the phrase. If the insert opens a section, it starts on the cut (H5).
- **Look:** background #F7F4EC, Nunito Sans, ink #1C1C1A, pin colors (green = win, orange = re-knock, indigo = not home, red = no), and a small uppercase kicker line at about y=450 px. Animations use spring or ease curves driven by one clock.
- **Layout:** keep content between y≈420 and y≈1540 px. The section label sits above that band and captions below it.
- **Placeholders:** example content he didn't say (sample questions, business names) is a placeholder. Say so when delivering and ask for the real version.
- **Real footage first:** use real or stock B-roll only when it matches the words (for example, a handshake on "partnered with local businesses").

---

## 5. Pipeline (scripts in video_research/content_kit/)
One command does the cut, captions and composite: `python make_edit.py <variant>`. A variant is a clip order. Copy the script and edit CLIPS and ORDERS for new footage. Then run `python qa_check.py <final> <timeline> <inserts> <captions> <dir>`.
1. Pull the clips. Drive files over 10 MB need a temporary "anyone with link" share plus a direct download. The Drive connector can't undo that share, so tell Nathan to set the files back to Restricted.
2. Transcribe with Whisper (small for hooks and captions, base is fine for bulk), with word timestamps.
3. Plan the order (H7) and cut points (H1). Write `edit.py` with ORDER and OVERRIDE_START.
4. Render segments (grade, punch-ins, audio fades) and concat them into main.mp4.
5. Render inserts at 60 fps (inserts.html + render2.js). Composite with build_final.py, using frame-grid-snapped boundaries.
6. Run `qa_check.py`. It must pass before anything is sent.
7. Deliver the full-quality file through chat. Put a preview of 3 MB or less in Drive under 06 Final renders (the upload limit).

Drive convention [F20]: files at the top level of `01 Raw footage` are unedited, new footage. When a video ships, move its raw clips into a subfolder `01 Raw footage/<YYYY-MM-DD> · <video title> (edited)`. Only edit what's at the top level unless Nathan says otherwise.

## 6. QA gate (run before every delivery; any failure blocks it)
- [ ] Frame 0 and every clip start: speech within 0.10 s; inner cuts within 0.25 s (qa_check.py `deadair`)
- [ ] No black frames anywhere (qa_check.py `black`)
- [ ] Frame 0 is a clean shot of the face: no hand or phone covering it
- [ ] Re-transcribe the output: word-for-word match with the intended script
- [ ] Captions sit below the chin on every face shot (qa_check.py `captions`)
- [ ] ±3 frames around every cut, insert and label boundary: no face flash, label and graphic in sync (qa_check.py `boundaries` contact sheet, then look at it)
- [ ] Each insert's on-screen time is at least its animation length plus 0.4 s
- [ ] Contact sheet of the whole video reviewed (one frame every 1.5 s)
- [ ] Placeholders and judgment calls listed in the delivery message

---

## 7. Learning protocol (this is how the skill gets better)
Run this in the same turn, every time Nathan reacts to an edit:
1. Log it in FEEDBACK_LOG.md: the date, the video or version, what he said (near verbatim), what was wrong, and the rule change.
2. If the feedback generalizes beyond this one video, add or edit a rule here in PLAYBOOK.md. Hard-rule material goes in section 1, taste goes in section 2. Bump the version, add a CHANGELOG line, and add an automated check to qa_check.py where possible.
3. Commit and push with the message `playbook: <short rule>`.
4. Then fix the video.

When a video ships, add a "Shipped" entry with the final version and any open issues. After posting, log 48 h stats (views, 3-second hold %, average % watched, follows) in FEEDBACK_LOG.md under "Performance". A weekly consolidation agent merges duplicate feedback into hard rules and flags stale defaults.

---

## CHANGELOG
- v7 (2026-11-21): Drive convention, edited raw clips go to a dated subfolder (F20).
- v6 (2026-11-21): H9 no contrast grade (F18). H10 big black hook headline filling the top third (F19).
- v5 (2026-11-21): QA gate automated (dead air, black frames, flashes, caption-chin, completion). Fixed A/V drift from AAC segment concat (PCM segments). Inserts are full-timeline pre-renders with first-frame padding. Frame 0 hand fix. Added make_edit.py.
- v4 (2026-11-21): moved to the living playbook on GitHub. Backfilled 13 feedback items from the first editing session. Added the hard rules, QA gate and learning protocol.
- v3 (2026-11-21): face-first hooks, captions below the chin, custom animated inserts.
- v2 (2026-11-20): targets from the 216-video scrape.
- v1: published retention heuristics.
