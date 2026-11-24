# Short-form video edit playbook (living)

Version: 18 (2026-11-24)
Owner: Nathan. This file is the source of truth for the `short-form-video-edit` skill. The skill loads it at the start of every run and updates it whenever Nathan gives feedback (see "Learning protocol" at the bottom). Never treat it as frozen.

Rule priority, highest first:
1. Hard rules (Nathan's explicit feedback). These override everything below.
2. Nathan's stated preferences.
3. Research defaults (from the 216-video scrape, 2026-11-20). Use these only where 1 and 2 are silent.

---

## 1. Hard rules (from Nathan's feedback, never break these)

Each rule links to its entry in FEEDBACK_LOG.md.

H0. NEVER change the brightness, saturation, exposure, contrast or color of Nathan's footage without asking him first. [F18, F27, F28, F34, F35, F42]
- His words: "never, ever increase the saturation or brightness of my overall lighting without asking me first. I don't appreciate that."
- Default = the original picture, untouched (see H9). Any change to the look of his footage is a question for him (H16 pop-up), never a silent choice.
- Check before every delivery: compare the mean 10-bit luma of a face crop in the output against the same frame in the source. They must match within ~1%.

H16. Ask formatting questions with pop-ups, not walls of text. [F42]
- Whenever a decision about how the content will look or read is his to make (layout, text style, caption choice, which take, where elements go, what a graphic should show), ask with the AskUserQuestion pop-up: 2-4 short multiple-choice options, recommended first, previews where they help.
- Captions: always offer 3-4 options as a pop-up and let him pick (he asked for "multiple choice").
- Don't ask what the playbook already answers, and don't block on trivia: pick the default, say so in one line, keep moving.

H1. No dead space. Talk instantly, keep it flowing. [F1, F6, F9, F36, F40]
- Speech starts within 0.05 s of frame 0. Keep 20-30 ms before speech and 40-60 ms after.
- Inside a take, cut out every silence longer than 0.08-0.15 s, splitting the take as many times as needed ("don't be afraid to cut up one clip"). Target: no gap > 0.3 s, total dead air < 5% of runtime. Run content_kit/deadair_audit.py on the output and report before/after.
- Never cut through a word: shrink a cut to Whisper's word edges, but guard only the middle ~40% of each word (in fast lists Whisper spans touch end to end and would block every cut). Re-transcribe and confirm every word survives.
- What remains at ~0.08-0.15 s is normal word spacing; cutting further sounds chopped. Next lever, only if he asks: 1.08-1.1x speed with pitch kept.
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
- Enforced in code: the edit script computes each animation's "done" time from its cues and asserts done + 0.4 s ≤ window before rendering (see make_edit3.py). Includes sends, "Delivered" and final check marks. [F23]
- Never show cropped or zoomed UI. App clips come from unzoomed renders (`tap&nozoom=1`); speed them up (up to about 1.8x) rather than cutting the action short. [F23]

H7. Order follows the content, and the strongest story is the payoff or the lead. [F10, F11]
- Keep the spoken numbering consistent ("One is…"). If clips are reordered, cut the spoken number so it still makes sense ("One is simply asking" becomes "Simply asking").
- Nathan picked the $1,000 gift card story as the strongest point and wants it leading in the "give first" version.

H8. Post caption: lead with the most concrete story and its outcome, and end with a follow CTA. [F12, F13]
- The goal is followers. The first line is the strongest concrete moment (for example, "We handed every homeowner $1,000 in local gift cards before we pitched."). The next line is what happened after (the outcome). The last line is "Follow for more D2D tips".
- Don't just list all the tips in the caption.

H9. Keep the original HDR picture. Never convert his footage's color. [F35, supersedes F27/F28]
- His iPhone films HLG HDR (bt2020, 10-bit). Every SDR conversion we tried (F27, F28) made it look "bright" on his phone. Output HDR as-is: libx265 10-bit yuv420p10le, `colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited`, tag hvc1, plus the matching -color_* flags.
- Cuts, scale and crop in yuv420p10 don't change color. No eq, no tonemap, no grade (H0).
- Graphics go INTO the HDR space, never the footage out of it: sRGB → linear → BT.2020 → SDR white at 75-88% HLG signal (88% when he wants graphics brighter, F38) → HLG OETF → 16-bit PNG → overlay=format=yuv420p10 (build2.py `to_hlg`). Wide-gamut trick for vivid reds: treat the sRGB values as BT.2020 primaries (F40).
- Previews I make for myself are tonemapped and look washed out. Never judge his picture from them, and say so if I show one.

H10. The hook headline is big and black. [F19]
- White card, black (#000) text in Nunito Sans Black, no colored words. It fills up to the top third: box top at y≥180 (below the TikTok/Reels top bar), bottom at y≤640, side margins ≥60 px (box width about 960 px), text about 110-125 px, 2-3 lines.
- It should jolt the viewer. Size up rather than down, but never past the margins or the top third.

H11. Graphics must look like real software, never "AI motion graphics". [F22]
- Conversations: a real iMessage look. Status bar, contact header with an initials avatar, grey received bubbles (#E9E9EA), blue sent bubbles (#0A84FF), tails, "Delivered", and the typing indicator. Everyday notes and lists: an iOS Notes or Reminders look. Gift cards: an Apple Wallet pass look. Doors, re-knocks, results: the SalesMapper app UI (mockup.html scenes or real recordings).
- No beige cards, soft pills or "kicker" headings. If a frame wouldn't plausibly appear on a real phone or in a real app, don't use it.
- Use an SF-like UI font (Inter) inside phone UIs.
- Library: content_kit/ios.html, with scenes `imessage` (your line types into the field, then sends; `say=` and `send=` cues), `notes` (strike plus typed line; `strike=` and `type=`), and `reminders` (items check on spoken cues; `get=`, `close=`, `no=`, `fig=`). For results, cut to real SalesMapper app footage (for example, app_tap at about 3.05 s: Sale tapped, pin turns green).
- Section labels never cover a full-screen phone or app screen. They show over the face only. If a section opens on a screen, the screen's own title names the step (for example, a Reminders list titled "Then do this").

H12. On-screen text uses TikTok's native style. [F22]
- Font: TikTok Sans (or the closest native equivalent). Section labels look typed in TikTok's text tool: a white background box with black text or white text with a black outline, sized large. Step numbers are big ("1." at the same size as the title, or larger), not tiny badges.
- The hook headline (H10) also uses TikTok Sans.

H13. Ship two versions of every edit: captioned and clean. [F22]
- Clean = no burned-in word captions (labels and the hook stay), so Nathan can use the platform's auto-captions.
- When he says "just splice it", deliver ONLY the cut: no text, zoom, captions or graphics. [F35]
- Instagram version only. No TikTok layout unless he asks for one (F48).

H14. The opening has energy. [F24]
- Hook shot: smooth push-in on his face, 100%→110% across the hook, using subpixel warpAffine (no ffmpeg zoompan, which jitters). Later jump cuts alternate 100%/112%, starting at 100% after the hook.
- Hook text frames the problem instead of restating the topic: a two-tier card, a smaller lead line ("Stop losing deals to") over the big quote, still inside H10's bounds.

H15. Subtle sound design. [F24]
- Synthesized in-house only (content_kit/sfx/make_sfx.py): whoosh (ONLY on face↔screen cuts, never screen→screen or app overlays in and out; peak on the cut, softer on cut-backs) [F26], imsg_send (iPhone-style swoop-up, gain about 0.7, must measure ≥ +6 dB over speech in 2-7 kHz) [F26], pop (hook card), pop_hi (labels shown over the face), strike (Notes strike-through), key clicks (typing, about 85% of characters, randomized), swoosh_send (iMessage send), check (Reminders), tap and drop (app tap and pin landing).
- Level: subtle. Peaks around -18 dBFS against voice at -14 LUFS. Felt, not heard.
- Place every sound from the same word-timed cues as the animation it belongs to.
- Mix: loudnorm → aresample 48k → amix(normalize=0, longest) → atrim to video length → alimiter. [F25]

H17. Graphics: solid, readable, never on his face. [F30, F31, F37, F38, F39, F41]
- 100% opaque. No translucent cards or boxes.
- Measure his chin across the video (Haar face box bottom) and place cards and captions below the lowest chin position. If there's no room, zoom the footage 1.2x bottom-anchored (scale 1296x2304, crop y 384) so his face moves up ~150 px.
- Keep something moving: an insert or card about every 5-8 s; typing screens type 3-4 lines, each starting on the spoken word it matches.
- No credit tags on borrowed clips unless he asks.
- Text on screen is black on white by default (F34), except when copying a reference's look.

H18. Copying a reference creator's format. [F37-F40]
- Pull frames at every beat of the reference, crop the graphics at full resolution, and copy the system (layout, fonts, label style, colors, CTA style), not the content.
- Adapt placement to Nathan's framing (his face sits lower than most references).
- Fonts: install full TTFs (Google Fonts CSS requested with no browser user agent); woff2 subsets fall back to serif in headless Chromium.
- Pick takes from the same room as the rest of the clips.
- TikTok layout: headers and titles at y ≥ 250 (below the Following/For You tabs), cards scaled ~0.88 and shifted left clear of the right action rail (x ≤ ~800), nothing important below y ~1600.
- Map B-roll: never use his raw pinch-zoom screen recordings as moving footage (jitter). Pull stills at several zoom levels, register them (SIFT + estimateAffinePartial2D chain), and render one slow eased zoom toward a fixed point, then glide between called-out features on their words (door_tools/sv.py). [F48]
- Data maps (income, demographics): trace the real blocks of the neighborhood on the screenshot, show the plain map first, then the same blocks over the Google Maps still. Sequential white → dark red (more = darker), legend very small, highest and lowest called out on their words. Numbers are illustrative unless he gives real ones (door_tools/inc.py). [F48]
- Library: content_kit/edits/d2d_iq/ (spec-sheet term cards: cards.html + terms.json, header/caption/red CTA overlay: overlay.html, *_tt.html TikTok variants, build.py cut + build2.py HDR composite).

---

## 2. Nathan's preferences (soft, but default to these)
- **Captions:** word-by-word, 2 words per chunk, uppercase Nunito Sans Black 96 px, white with a dark outline, active word green #34C759.
- **Section labels:** a white rounded pill at the top (y≈250), with a green number circle and 3-5 words.
- **Hook text:** see H10 (big, black, top third). 6-8 words.
- **Jump cuts:** alternate 100% and 112% punch-ins on every cut inside a take.
- **Color:** iPhone footage is HLG HDR. Use only the accurate conversion in H9.
- **Audio:** highpass at 70 Hz, loudnorm to I=-14, TP=-1.5. Use a 10-15 ms fade at every cut.
- **Music:** never bake music into the file. Nathan adds a trending sound in the TikTok or Instagram app at 5-10% volume, instrumental, without lyrics.
- **Ending:** his spoken CTA plus a text pill ("Follow for more D2D tips"). No outro card, no logo sting. In the reference style: solid red box, white serif "follow for more", held to the end.
- **Role-plays:** end on the last line of the pitch, not on filler like "So all good?" [F31]
- **Every clip counts:** list and transcribe EVERY new file in the raw folder before cutting. A closing "follow for more" clip always goes last. [F30]
- **Post captions:** a comment trigger works best ("Comment 'GUIDE' / 'IQ' and I'll send you…"). The last line before hashtags is "Follow for more door-to-door tips 🚪". Max 5 hashtags. Offer options as a pop-up (H16).
- **Scripts and hooks:** the knowledge must be real and counterintuitive to the D2D community (not the standard playbook with new labels). Hooks combine clarity with on-topic curiosity and avoid delay, comprehension loss, irrelevance and disinterest. Flag unbackable stats (e.g. "112%") and suggest safer wording.
- **Speed:** default to one render, one QA pass, then send. No preview loops or long multi-step workflows unless he asks; when he says "move fast", skip questions too. [F40, F44]
- **Audio on IQ-style videos:** optional. He often mutes and adds a sound in-app, so never hold a delivery for an audio fix. [F44]
- **IQ-format captions:** one word at a time, Instrument Serif 140 px. [F44]
- **Platform tips he uses:** Creator account (not Business) for the full music library; added music at 5-10% under his voice at 100%.

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
  - `notspouse`: the objection bubble gets struck through, then "No reason to say yes… yet" appears with an empty "reason to buy" meter
  - `theline`: chat bubbles, the homeowner's objection then your line in green (`say=` cue)
  - `branch`: a YES/NO tree whose steps land on spoken cues (`get=`, `close=`, `no=`, `fig=`)
- Cue-timed inserts: pass word times from the cut output as URL params (`scene&dur=…&cue=…`). The animation then matches his speech wherever the cuts land.
- The kicker line must not repeat the section label. It adds information (for example, label "Ask this" with kicker "THE LINE").
- **Word sync:** every element of a screen (counter, toggle, highlight, badge) starts on its own spoken word, not on the shot start. Stagger only inside a word's 0.2 s window. One continuous screen per topic, highlight jumps card to card (F48).
- **Timing:** start 0.05 s before the key word and end 0.1 s after the phrase. If the insert opens a section, it starts on the cut (H5).
- **Look:** background #F7F4EC, Nunito Sans, ink #1C1C1A, pin colors (green = win, orange = re-knock, indigo = not home, red = no), and a small uppercase kicker line at about y=450 px. Animations use spring or ease curves driven by one clock.
- **Layout:** keep content between y≈420 and y≈1540 px. The section label sits above that band and captions below it.
- **Placeholders:** example content he didn't say (sample questions, business names) is a placeholder. Say so when delivering and ask for the real version.
- **Real footage first:** use real or stock B-roll only when it matches the words (for example, a handshake on "partnered with local businesses").

---

## 5. Pipeline (scripts in video_research/content_kit/)
One command does the cut, captions and composite: `python make_edit.py <variant>`. A variant is a clip order. Copy the script and edit CLIPS and ORDERS for new footage. Then run `python qa_check.py <final> <timeline> <inserts> <captions> <dir>`.
1. Pull the clips. Drive files over 10 MB: share them temporarily as "anyone with link" WITHOUT asking (Nathan pre-approved this for raw clips, F21), download them directly (drive.usercontent.google.com), then tell him which files to set back to Restricted. The connector can't remove a share.
2. Transcribe with Whisper (small for hooks and captions, base is fine for bulk), with word timestamps.
3. Plan the order (H7) and cut points (H1). Write `edit.py` with ORDER and OVERRIDE_START.
4. Render segments (grade, punch-ins, audio fades) and concat them into main.mp4.
5. Render inserts at 60 fps (inserts.html + render2.js). Composite with build_final.py, using frame-grid-snapped boundaries.
6. Run `qa_check.py`. It must pass before anything is sent.
7. Deliver the full-quality file through chat. Put a preview of 3 MB or less in Drive under 06 Final renders (the upload limit).

Drive convention [F20]: files at the top level of `01 Raw footage` are unedited, new footage. When a video ships, move its raw clips into a subfolder `01 Raw footage/<YYYY-MM-DD> · <video title> (edited)`. Only edit what's at the top level unless Nathan says otherwise.

## 6. QA gate (run before every delivery; any failure blocks it)
- [ ] H0: face luma in the output matches the source within ~1%, and the output is still HLG bt2020 10-bit
- [ ] deadair_audit.py: speech ≤ 0.05 s from frame 0, no gap > 0.3 s
- [ ] Frame 0 and every clip start: speech within 0.10 s; inner cuts within 0.25 s (qa_check.py `deadair`)
- [ ] No black frames anywhere (qa_check.py `black`)
- [ ] Frame 0 is a clean shot of the face: no hand or phone covering it
- [ ] Re-transcribe the output: word-for-word match with the intended script
- [ ] Captions sit below the chin on every face shot (qa_check.py `captions`)
- [ ] ±3 frames around every cut, insert and label boundary: no face flash, label and graphic in sync (qa_check.py `boundaries` contact sheet, then look at it)
- [ ] Each insert's on-screen time is at least its animation length plus 0.4 s
- [ ] Contact sheet of the whole video reviewed (one frame every 1.5 s)
- [ ] delivery_check.py PASS on every file sent: full decode with zero errors, still HLG bt2020 10-bit, audio and video the same length [F44]
- [ ] Renders run one at a time, never in parallel (parallel builds corrupted audio and card sizes) [F44]
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
- v18.1 (2026-11-24): app/graphic backdrops use the 0.88 white LUT so they are not dimmed next to text boxes (F49).
- v18 (2026-11-24): Instagram only, no TikTok version; still-based smooth map zooms; word-synced screen elements; real-neighborhood heat maps with red-white scale (F48).
- v17 (2026-11-23): delivery_check.py full-decode gate, one render at a time, one-render-then-send speed rule, optional audio on IQ videos, 140 px IQ captions (F44).
- v16 (2026-11-23): H0 never change brightness/saturation without asking (F42); H16 formatting questions as pop-ups (F42); H9 keep original HDR, graphics converted into HLG (F35, F38, F40); H1 tight splice + dead-air audit + core-only word guard (F36, F40); H17 opaque graphics placed below the measured chin, 1.2x up-shift (F37-F41); H18 reference-format workflow + TikTok layout (F37-F40); preferences: role-play endings, every clip, comment-trigger captions, real counterintuitive scripts, move fast.
- v15 (2026-11-21): H9 final, accurate conversion, confirmed by Nathan against his phone (F28); lineup method for color disputes.
- v14 (2026-11-21): neutral grade, matrix-only conversion, no added saturation (F27).
- v13 (2026-11-21): fewer whooshes (face↔screen only), audible iMessage send (F26).
- v12 (2026-11-21): H14 hook push-in plus two-tier hook text; H15 synthesized subtle SFX; audio-length QA, QA_VOICE (F24, F25).
- v11 (2026-11-21): runtime gate in code, no cropped UI (F23). Look approved by Nathan.
- v10 (2026-11-21): iOS screen library (iMessage, Notes, Reminders); labels hidden over screens; two-version output in make_edit3.
- v9 (2026-11-21): H11 real-software graphics, H12 TikTok native text, H13 captioned plus clean versions (F22).
- v8 (2026-11-21): temporary link share for big raw clips is pre-approved (F21).
- v7 (2026-11-21): Drive convention, edited raw clips go to a dated subfolder (F20).
- v6 (2026-11-21): H9 no contrast grade (F18). H10 big black hook headline filling the top third (F19).
- v5 (2026-11-21): QA gate automated (dead air, black frames, flashes, caption-chin, completion). Fixed A/V drift from AAC segment concat (PCM segments). Inserts are full-timeline pre-renders with first-frame padding. Frame 0 hand fix. Added make_edit.py.
- v4 (2026-11-21): moved to the living playbook on GitHub. Backfilled 13 feedback items from the first editing session. Added the hard rules, QA gate and learning protocol.
- v3 (2026-11-21): face-first hooks, captions below the chin, custom animated inserts.
- v2 (2026-11-20): targets from the 216-video scrape.
- v1: published retention heuristics.
