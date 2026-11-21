# Feedback log

Append-only. Newest entries at the bottom. Each entry: ID, date, video/version, what Nathan said, what was wrong, and the rule it produced (PLAYBOOK section). The weekly consolidation agent adds a "Consolidated" note when it merges entries.

## Session 1: "3 ways to double your close rate" (2026-11-21)

**F1** (v1). "Take care to order the clips properly, cutting deadspace as close as possible."
- Wrong: nothing yet. This set the bar.
- Rule: H1. Tight cuts; Nathan's preference overrides the research's "leave 0.5-0.9 s beats".

**F2** (v1). "The caption shouldn't be on my mouth. It looks bad. Put them under my mouth."
- Wrong: captions were centered at y=1344 (70% down), which landed over his mouth on punched-in shots.
- Rule: H2. Measure the face per shot and place captions below the chin (y≈1610).

**F3** (v1). "At the start, I want just my face. I don't want the cutaway immediately… I don't want the software over you."
- Wrong: v1 opened on 0.7 s of the app map (following the research rule "open without a face").
- Rule: H3. Talking-head hooks are face-only. Nathan's preference beats the research.

**F4** (v1). "Create custom animated designs that show what we're trying to demonstrate. Like a gift card… represent points of the video where we don't have B-roll… keep cutting back and forth."
- Wrong: v1 had almost no visual change in the body.
- Rule: H4 plus section 4. Built questions, re-knock, referrals, gift card and reciprocity inserts.

**F5** (v3). "For 2, just start with the graphic, don't have the millisecond cut to my face."
- Wrong: the insert started 0.15 s after the section cut, causing a flash of his face.
- Rule: H5. A section-opening insert starts on the cut.

**F6** (v2). "At the start of the video when I say 1 there's slight deadspace."
- Wrong: the segment started 0.3 s before "One", because the cut point was taken from Whisper's early word time instead of the waveform.
- Rule: H1. Cut points come from the waveform; check every segment start, not only the first.

**F7** (v3). "Complete the animation for the referrals."
- Wrong: the 2.3 s animation was given a 1.35 s window and got cut mid-draw.
- Rule: H6. Window must be at least the animation length; widen or retime.

**F8** (v5, found in QA before delivery). One face frame between two back-to-back graphics at a section boundary; the label switched a frame off from the graphic.
- Wrong: boundaries weren't on the frame grid, and the insert clip ran out a frame early.
- Rule: H5. Snap to the frame grid; pad insert clips; check ±3 frames at every boundary.

**F9** (v4). "There's a bit of dead time right at the beginning of the original video."
- Wrong: frame 0 had 0.2 s of silence before "3". The very first segment was never checked.
- Rule: H1. Frame 0 is checked explicitly; qa_check.py `deadair` covers it.

**F10** (v4). "Rebuild this video and have the giving them something as the starting bit of information. I thought that was actually great."
- Rule: H7. The strongest story leads. Cut "One is" so numbering doesn't contradict the new order.

**F11** (v1). Nathan accepted the order hook → qualifying (he says "One") → re-knock → give first → CTA as correct for the 1-2-3 version.
- Rule: H7. Follow the spoken numbering.

**F12**. Post-caption goal: "My goal is to drive followers… leading with the $1,000 in local gift cards… put a follow for more at the bottom."
- Rule: H8.

**F13**. "Redo the caption around what happens after we give the $1000 gift card, not just going through all three."
- Rule: H8. Story plus outcome, not a list of the tips.

**F14** (system). "Feed the context of the session back into the skill… continue to learn whenever it is invoked… it's important to emphasize that the dead space is not there. The captions are not over my mouth. Elements are properly aligned and animations show up for their full duration. But these pieces alone aren't all that matters."
- Rule: the playbook moved to GitHub with this log and the learning protocol, and the QA gate is automated. The four named items are the minimum bar, not the goal. Keep raising taste and quality.

**F15** (found by the new QA, before delivery). Section starts had 0.2-0.46 s of apparent dead air, growing later in the video.
- Wrong: joining AAC segments drifted the audio about 21 ms per cut. The dead air at "Give", "Re-knock" and "If" in earlier versions was partly this drift.
- Rule: H1, PCM segment audio.

**F16** (found by visual QA review). Black single frames before some inserts, and inserts starting 1-2 frames late.
- Wrong: input offsets plus black padding on the insert pre-renders.
- Rule: H5, full-timeline pre-renders padded with the first frame; qa_check `black`.

**F17** (found by visual QA review). Frame 0 showed his hand in front of the lens for 4 frames.
- Rule: H1, hold the first clean frame over the hand and keep the audio.

**F18** (FINAL versions). "Both versions, but with the contrast not changed on the video."
- Wrong: the grade added contrast 1.06, saturation 1.04 and gamma 0.97.
- Rule: H9. No contrast, saturation or gamma changes. Only the HDR→SDR color-space conversion, which is needed so HLG footage doesn't look washed out.

**F19** (FINAL versions). "The initial text banner… the headline needs to be larger, cover more of the screen, and have black font so that it actually shows up and jars the user… almost covering the top third of the screen… as long as it fits the margins."
- Wrong: the hook pill was 70 px text in an 880 px box, roughly the top 13% of the screen, with one green word.
- Rule: H10. The hook headline is big: black text on white, filling up to the top third (bottom edge ≤ y 640) inside 60 px side margins, starting below the platform's top UI (y ≥ 180).

**F20**. "Move the old videos in my Google Drive… into their own folder within the drive. I'm gonna add some more now."
- Rule: section 5 Drive convention. Edited raws go to `01 Raw footage/<date> · <title> (edited)`, and the top level holds new footage only.

**F21**. Asked about the temporary share for raw clips over 10 MB, Nathan answered: "Yes, and always for raw clips."
- Rule: section 5 step 1. Don't ask again; still remind him to set the files back to Restricted.

**F22** (spouse objection v1). "I'm looking for realistic things that could appear in a real software, not obviously AI generated… the messages… look like it's on an iPhone, sending blue messages. The bars on the top look like they should be normal captions, not these Claude generated things… step one, those boxes should be bigger. The font… should have some distinct typography… I want a version with captions and without."
- Wrong: the inserts read as generic AI motion graphics (beige cards, soft pills, Nunito). The chat wasn't a real iMessage look. The section labels looked like custom pills, not native captions. The number badges were too small. The typography had no character.
- Clarified (Q&A 2026-11-21): visuals are a MIX, native iPhone UI (iMessage with blue bubbles, Notes, Reminders, Wallet) for conversations and everyday things, and the real SalesMapper app for doors, re-knocks and results. Top section labels use TikTok native text style (TikTok font, white background box or white text with black outline), with much bigger step numbers. Typography is TikTok's native font. Every edit ships two versions: captioned and clean.
- Rule: H11, H12, H13.

**Process notes (session 1)**
- Nathan doesn't want to wait on long batch jobs. Ship the first pass fast, then refine. Use the faster Whisper model if transcription is the bottleneck.
- He iterates in small, specific notes. Apply each one exactly, re-check the whole video for side effects, and say what else changed.
- Upload limits: Drive uploads from a session are capped at about 3.1 MB per file, and downloads at 10 MB. Send full quality through chat.

**F23** (spouse v2, approved). "I like it. These videos look good. Just make sure that the animations have full runtime. Nothing is oddly cropped."
- Found in review: the iMessage send landed 0.2 s before the cut ("Delivered" never showed), and the app clip was a zoomed punch-in (sheet cropped at the left) and 0.5 s too short for tap → green pin.
- Rule: H6 is now enforced in code. make_edit computes each animation's done time from its cues and fails the build unless done + 0.4 s fits the window. Real-app clips use unzoomed footage (mockup.html `tap&nozoom=1`), sped up when needed so the full action fits. Never crop UI.

**F24** (spouse v3). "I need something to make the initial couple seconds a little more enticing. I also want to add a couple of subtle sound effects like swooshes, pops, and whishes when certain elements show up on the screen."
- Clarified (Q&A): opening = slow punch-in on his face plus stronger hook text. SFX on headline and labels, cuts to screens, UI actions and typing. Sounds synthesized in-house (no licensing). Level: subtle.
- Rule: H14, H15.

**F25** (found by QA, spouse SFX build). After adding SFX, the audio ended 2.9 s early: the CTA was gone.
- Wrong: loudnorm works at 192 kHz internally; amix(duration=first) with an unresampled loudnorm output truncated the mix.
- Rule: always `aresample=48000` after loudnorm before mixing, mix with duration=longest, then atrim to the video length. qa_check now fails if audio is shorter than video, and measures dead air on a voice-only track (QA_VOICE) so SFX can't mask or fake it.

**F26** (spouse SFX v4). "There's a few too many wishes [whooshes]… I don't hear that iMessage cue." Asked which to cut: screen-to-screen and in and out of the app. Send sound: clear iPhone-style.
- Wrong: 7 whooshes (one per cut, including screen→screen and app overlays). The send swoosh was 2 dB under his speech, so it was masked.
- Rule: H15 updated. Whoosh only on face↔screen cuts. Signature moments (iMessage send) must be audible: bright 1.1-3.2 kHz glide, verified ≥ +6 dB above speech in the 2-7 kHz band (it measured +8.3).

**F27** (spouse v5). "Reduce the saturation on these. I don't want it brighter. Keep it standard lighting."
- Wrong: the HLG→SDR conversion also converted bt2020→bt709 primaries, which pushed skin red. Face saturation measured 74 vs 57 for neutral (+30%).
- Rule: H9 updated. Grade = matrix conversion only (`scale=in_color_matrix=bt2020:out_color_matrix=bt709,format=yuv420p`). No primaries or gamut expansion, no eq, no tonemap. Same brightness as the source.

**F28** (spouse v6). "I want all of the lighting to be the same as the video… I look pale. It looks like I don't have a face."
- Wrong: the F27 matrix-only grade left bt2020 primaries uninterpreted, which washed out the skin (face saturation 60 vs 77-81 accurate).
- Process: built a side-by-side of 4 grades on 2 frames and Nathan compared them to the original in Photos. He picked option 1, the accurate zscale bt2020→bt709 conversion with no eq. (libplacebo with Dolby Vision was tried, but software Vulkan renders stripe artifacts here, so it's unusable.)
- Rule: H9 final. Grade = accurate conversion, no saturation or contrast changes. When color is disputed, don't guess again: show a labeled lineup and let him match it to his phone.

**F29** (not-interested v1, found in review before delivery). The borrowed hook clip opened with the other creator's "Hey!", and the Notes screen held 3.1 s after typing finished.
- Wrong: the hook's lo was 0.0, so "Hey" leaked in. Then the fix skipped "We're not interested" entirely, because the screen-recorded voice peaks around +15-19 dB over its floor and the onset gate needed +20, and Whisper had merged "Hey" into "We're" (s=0.0), so the word filter dropped it.
- Rule: section 3 pipeline. For third-party or screen-recorded audio, check the onset against that clip's own energy curve (use about +6 dB) and correct merged word starts by hand. Re-transcribe the first 4 s of the final and confirm the first word. Inserts end about 0.15 s after the last word they illustrate, with a hold under 2 s, then cut back to the face.

## Shipped
- d2d_3_ways_close_rate_v4b.mp4 (1-2-3 order). Shipped 2026-11-21. Superseded: it had A/V drift (F15).
- d2d_3_ways_123_order_FINAL.mp4 and d2d_3_ways_giftcard_first_FINAL.mp4. Shipped 2026-11-21, both QA PASS. Open: the qualifying questions and gift card business names are placeholders.

- d2d_spouse_objection_v1_final.mp4 ("I need to talk to my spouse"). Shipped 2026-11-21, 19.3 s, QA PASS. Built from playbook v8 with no corrections yet. New inserts: notspouse, theline, branch (cue-timed to word times). Retakes cut in IMG_9748 and IMG_9749. QA dead-air check made plosive-aware (the "k" in "Close" was misread as silence; found by QA).

- d2d_spouse_objection_v1_captions.mp4 and d2d_spouse_objection_v1_clean.mp4: rebuilt with H11-H13 (iOS Notes, iMessage, Reminders; real app Sale tap; TikTok Sans labels, hook and captions). QA PASS on both. Found in review: labels covered the phone title bars, so labels are now hidden over screens.

- d2d_spouse_objection_v3_captions.mp4 and d2d_spouse_objection_v3_clean.mp4: runtime and crop fixes (F23). QA PASS, runtime gate PASS. Nathan approved the look.

- d2d_spouse_objection_v1_sfx_captions.mp4 and d2d_spouse_objection_v1_sfx_clean.mp4: push-in hook, two-tier headline, 77 subtle synthesized SFX. QA PASS on both, runtime gate PASS.

- d2d_not_interested_captions.mp4 and d2d_not_interested_clean.mp4 ("We're not interested" objection, stitched hook from @claytonnelson_ with a credit tag). Shipped 2026-11-21, 24.7 s, QA PASS on both, runtime gate PASS (Notes hold 1.5 s). Edit script: content_kit/edits/not_interested/make_edit5.py.

## Performance
(Log 48 h stats per posted video here.)
