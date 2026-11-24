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

**F30** (not-interested v2). "Remove the fat watermark at the start, I will add it myself if necessary. I want the clip where I say semblance and the follow for more information like this to show up. Make sure that the animations complete. Add more of them. They don't all have to be Apple styled… just non-pure Clauded stuff… other animations that you can find that are clean."
- Wrong: no credit tag wanted. Two clips (IMG_9780 "semblance of interest", IMG_9781 spoken follow CTA) were never downloaded because only part of the Drive folder was pulled. Too few inserts (one in 25 s).
- Rule: list and transcribe EVERY new clip in the raw folder before cutting; a closing "follow for more" clip always goes last with the CTA text on it. Don't add credit tags to borrowed clips unless asked. Aim for an insert every 5-8 s, built as real software (SalesMapper app screens: outcomes breakdown, tap-to-mark pin; iOS apps) or clean data viz. Lottie/CDN libraries are blocked by this environment's network, so build scenes in mockup.html / ios.html. Never zoom a UI so far that values crop.

**F31** (not-interested v3). "Cut the last all good, but I'll give them the spiel… On the notepad, when you're typing into notes, I want there to be three things… three or four. So it's just constantly moving."
- Wrong: the role-play ended on a weak "So all good?". The Notes screen typed one line and then sat still.
- Rule: end role-plays on the last line of the pitch, not on filler. Typing inserts type 3-4 lines, each starting on the spoken word it matches (ios.html notes now takes l1-l5/t1-t5, spd), so something on screen moves every ~0.8 s for the whole window.

**F32** (day-one scene, autonomous). "Autonomously produce a video… some movie clip of a back and forth between two characters, rep first day knocking and then manager assuring them it's okay."
- Decision: generate an ORIGINAL cinematic scene instead of real movie footage (copyright, and this environment can't fetch film clips). Kling 3.0 in Higgsfield, 15 s, 9:16, sound on, 30 credits: one prompt with four numbered shots, each line in quotes with who says it, "no music, no on-screen text, no subtitles". All four lines came out correct and lip-synced on the first try.
- Pipeline: the Higgsfield file host (d8j0ntlcm91z4.cloudfront.net) was added to the environment allowlist. Cut silent gaps the same as talking heads (H1), fix Whisper's number/homophone errors in captions ("40"→"Forty", "nose"→"no's"), and freeze the last frame 1.6 s under the follow card instead of cutting the punchline short.

**F33** (2026-11-23, direction change). "Do I really need to be doing all this editing? … using default captions that users would see, and then having like basic headers with text that isn't too blown up makes sense." Then: "I put all the [takes] into the Google Drive. I want you to start editing that."
- Evidence: the niche scrape agrees. Cut rate, burned captions and banner graphics did not separate top from bottom videos; natural pauses did (the only significant result).
- Rule (LIGHT default): best take per line; trim real dead air only, keep ~0.15-0.3 s beats between thoughts (GAP_MAX 0.6, KEEP 0.16/0.12, TAIL 0.22); normal-size TikTok text header from frame 0 and numbered labels (no top-third block); jump-cut zoom alternation; no custom inserts or SFX unless a moment truly needs explaining; deliver the clean version as primary (platform auto-captions on) plus a simple captioned backup. Supersedes H10 size, H14 two-tier card, H15 SFX and the "insert every 5-8 s" note in F30 for default edits. First used on content_kit/edits/three_lines/make_edit6.py.

**F34** (3 lines, light-style cut). "Stop making it lighter. I don't want this to ever happen again. Also, I want the default. I want black on white for this text. Maybe I should just edit it in Instagram. Yeah, just don't do it. I'll do it."
- Outcome: Nathan is editing this video himself in Instagram. Stop work on it.
- Rule: on-screen text is black on white. "Lighter" is not yet clear (picture brightness vs. the lighter editing style from F33), so F33 is SUSPENDED until he says which. Don't ship another edit in either direction without confirming.

**F35** (3 lines). "The picture. So literally just take the original clips and keep the picture normal. I just want it spliced… Every single time I'm telling you, stop making it look so bright."
- Root cause: every edit converted the iPhone's HDR (HLG, bt2020, 10-bit) to SDR (F27/F28 grades). On his phone the result never matched the original, and read as brighter/washed. Lineups compared SDR candidates to each other, never to the untouched HDR.
- Rule (H9, replaces all earlier grades): NEVER convert color. Keep the source HDR as-is: libx265 10-bit (yuv420p10le), colorprim=bt2020, transfer=arib-std-b67, colormatrix=bt2020nc, tag hvc1. Verify mean 10-bit luma of a source frame vs the output frame (diff < 1%). Overlays/captions, if ever wanted again, must be composited without changing the picture's color space.
- Also: when he says "just splice", deliver ONLY the cut: no text, no zoom, no captions, no graphics. F33 light style is dropped; F34 resolved (lighter = picture).

**F36** (3 lines splice). "Do a dead air audit… don't be afraid to cut up one clip if it's got a bunch of sloppy air in it. You can split it and cut that out… I really need to be talking instantly. And after the first speech is done, keep it flowing."
- Audit (content_kit/deadair_audit.py): the first splice had 20 gaps >= 0.15 s, 5.5 s of dead air, mostly at take joins (LEAD+TAIL padding).
- Rule (replaces the "keep natural beats" part of F33 for good): speech in the first 0.05 s; keep 30 ms before speech and 60 ms after; cut any silence > 0.15 s inside a take, splitting the take; never cut through a word (shrink the cut to Whisper's word edges); re-transcribe the final and confirm every word. Target: no gap > 0.3 s, total dead air < 5% of runtime. Result: 12 breaths of 0.15-0.28 s, 2.4 s total in 51.3 s, all words intact. Script: content_kit/edits/three_lines/splice2.py.

**F37** (D2D IQ, reference: Bryson Bowman "Business IQ"). "Create the visuals that are in his clips for each of the terms that I provided and overlay them on the screen. I can do the rest of the editing… everything spliced together from the clips I provided."
- Built: 16 spec-sheet cards (light card, DETAIL VIEW / SIDE PROFILE / MATERIAL / SCALE STUDY / TOUCHPOINT labels in IBM Plex Mono, per-term diagram, formula pill, italic one-line definition, one accent per term) + white Instrument Serif term title with a dark shadow. content_kit/edits/d2d_iq/.
- Overlays on HDR footage: convert the graphic INTO HLG (sRGB -> linear -> BT.2020 -> SDR white at 75% HLG signal per BT.2408 -> HLG OETF, 16-bit PNG), overlay in yuv420p10, encode x265 HLG. The footage itself is never converted (face luma 637 vs source 640).
- Placement: his framing puts the face high; ours sits lower (chin y 1250-1340). Measure the chin and put cards below it (scale .78, y 1372-1715). White titles need a dark shadow on a light wall.
- Takes: match the room. 9843-9845 were shot in a different room from the term clips, so the hook came from 9848.
- Font gotcha: Google Fonts woff2 subsets fall back to serif in headless Chromium. Install full TTFs (request the CSS with no browser user-agent).

**F38** (D2D IQ v2). "I like this. Make the font and the image you've added brighter… zoom my video clip in and move it up… I want the photos to be popping up where captions normally are on Instagram Reels… mimic his text exactly… 'Door-to-Door Sales IQ' header, '(owner edition)' below… my captions popping up one word at a time in the middle of the screen… at the start below my chin, kind of my chest area."
- Rule: overlays on HDR are mapped brighter than reference white (white = 88% HLG signal, not 75%). Only the overlays; footage untouched.
- Rule: to make room for graphics, zoom the footage 1.2x bottom-anchored (scale 1296x2304, crop y 384): the face moves up about 150 px (chin ~1110, max 1203) and graphics go at y >= 1240, where Reels captions usually sit. A plain scale/crop in yuv420p10 doesn't change color.
- Header in his style: bold sans (Inter 800, 84 px, thin dark stroke) + "(owner edition)" regular below, top of frame, during the hook. Keep it inside ~90 px side margins.
- Captions: ONE word at a time, white Instrument Serif ~118 px with dark shadow, chest area (y 1240), hook and outro only (term titles carry the middle). Fix Whisper errors in captions ("fall for more" -> "follow for more").

**F39** (D2D IQ v3). "I want the follow for more to be that big pop-up that he had. Like red pop-up with the white text… the graphics should be bigger."
- Rule: the closing CTA is a solid red box (#E5202E) with white Instrument Serif "follow for more", in the caption spot, held to the end (replaces the one-word captions for that phrase).
- Rule: spec-sheet cards at full size (800x440, 74% of frame width), top just under the lowest chin position (y 1226 after the 1.2x up-shift).

**F40** (D2D IQ v4 + TikTok). "Make the red a little bit more vivacious… look for dead space… keep moving quick… prepare a version for TikTok… different places, the aspects and elements. Let's move quickly."
- Red CTA: #FF1430 with sRGB values treated as BT.2020 primaries in the HLG conversion (wide gamut = more saturated than any SDR red).
- Pace: pauses over 0.08 s squeezed (PRE 0.02 / POST 0.04). The word guard now protects only the middle 40% of each Whisper word, because in fast lists Whisper spans touch end to end and blocked every cut. What remains (0.08-0.15 s) is normal word spacing; going further sounds chopped. Next lever if asked: 1.08-1.1x atempo.
- TikTok layout (separate render, same content): header/titles down to y 250-262 (below the Following/For You tabs), card scaled .88 and shifted left (x 60-764) clear of the right action rail, captions centered in x 30-940. Files: cards_tt.html, overlay_tt.html; env PFX/OVL/CAP/HL/OUTF on build2.py.
- Move fast: when Nathan says so, skip extra previews and ship.

**F41** (D2D IQ v4). "I don't want the elements to be translucent." Rule: graphics (cards, boxes) are 100% opaque. No see-through backgrounds.

**F42** (2026-11-23, session wrap-up). "Take all the lessons from this session and record them into the skill. Never, ever increase the saturation or brightness of my overall lighting without asking me first. I don't appreciate that. From here, just keep getting better… in the future, do little pop-ups when you want to ask me certain questions on how the content's going to be formatted."
- Rules: PLAYBOOK H0 (no brightness/saturation/look changes without asking) and H16 (formatting questions as AskUserQuestion pop-ups, multiple choice). F29-F41 consolidated into PLAYBOOK v16 (H1, H9, H13, H17, H18, section 2, QA gate).

**F43** (2026-11-23, Business IQ cards). "I just want some variance: some square, some rectangle long side down, some rectangle short side down."
- Rule: in a run of term cards, rotate three shapes so no two consecutive cards match: wide (800x440 base), square (500x500), tall (400x570). Shape is a `shape` field per term in terms.json (default rotation wide, square, tall), so single cards can be swapped.
- Square/tall layout: diagram on top, formula pill (auto-shrinks to 12 px, then wraps), definition, then a label strip (Detail view glyph, Scale study, Touchpoint; tall adds the l3 row). Side profile, material and the scale circles are wide-only. The page logs OVERLAP/OVERFLOW if text collides.
- Process note: the auto-mode classifier blocked two "anyone with link" shares once; Nathan approved a retry and it went through.
- Placement unchanged: top at y 1222 (IG) / 1218 (TikTok), centered at x 540 (IG) or 465 (TikTok, clear of the right rail). IG scale 1.2/1.2/1.12 (tall bottom 1860), TikTok 1.08/1.08/1.0.

**F44** (Business IQ, 2026-11-23). "Dont worry about the audio. I can just mute it… can you just give it to me, this is crazy, your workflows have been so extended today… make my captions slightly larger… send it when it's done."
- Wrong: the first file delivered had ~3,000 AAC decode errors because two build2 renders ran at the same time and overwrote each other's files. QA never decoded the whole file, so it shipped. Then several extra render loops before he got a usable file.
- Rule: never run two renders at once. Every file passes content_kit/delivery_check.py (full decode with zero errors; HLG/bt2020/10-bit; audio/video length; optional face-luma vs source) before it is sent. Speed rule: one render, one QA pass, send. No preview loops unless he asks. IQ-format captions default to 140 px (was 118). Audio is optional on IQ-style videos.

**F45** (2026-11-23, Business IQ cards v2). "More squares and then rectangles, not the ones that are long up and down, because then the user can't see it. I also want these images shifted slightly farther up so they're right below my chin." Pop-up answers: 2 rectangles for every square, observe the reference video; track the chin; keep the size.
- Replaces F43's tall shape: no portrait cards. Rotation is wide, wide, square (terms.json `shape`).
- Rectangles follow the Bryson reference: about 1.45:1 (base 640x440, 768x528 on IG), not the flat 1.8:1. The reference cards are ~70% of frame width with the top right at the chin.
- Card top tracks the chin: chin.py runs YuNet on the zoomed frame every 0.1 s in each card's window. Box bottom = chin; top = lowest chin + 20 px (here y 1007-1144, was a fixed 1222). render.js reads seg/tops.json. Model: face_detection_yunet_2023mar.onnx from media.githubusercontent.com (opencv_zoo); OpenCV 5 has no Haar cascades.

**F46** (2026-11-23, Business IQ outro). "At the end, there's the 'if you know those', that kind of stutter, where I say 'if you know' first and then kind of fall over my words. That needs to be cropped out of both. Besides that, it's good."
- What went wrong: IMG_9875 has a false start "If you know" (6.80-7.45 s), a 2 s pause, then the restart "If you know those" at 9.45. Whisper merged them ("If you" from the false start, "know those" from the restart), so the cut kept both. The pause was cut but the repeat stayed in.
- Rule: when Whisper shows a long gap inside a phrase, check the waveform for two speech bursts. If the words before the gap repeat after it, it's a false start: keep only the restart. Whisper drops repeated words, so a clean-looking transcript can hide a stutter.
- Fix: the outro starts at 9.3 s; restart words patched into words.json for captions. Runtime 19.7 s, DELIVERY PASS both.

**F47** (2026-11-23, Business IQ post caption). "I want the caption to be more general business focused for this to get a wider audience."
- Rule: videos about general business concepts get a general-business caption (no D2D wording; "Follow for more business tips"; general hashtags like #businessowner #entrepreneur #smallbusiness). The D2D follow line and hashtags apply only to door-to-door content.
- Follow-up: "like aspirational stuff. I like the entrepreneur hashtag, the business owner hashtag." Tone for general-business captions is aspirational (owning a job vs owning a business, building something that runs without you). Always include #entrepreneur and #businessowner.
- Comment trigger kept but made unique per video ("OWNER" here, "IQ" for D2D Sales IQ) so one auto-DM keyword doesn't serve two different cheat sheets.

**F48** (2026-11-24, 4 door-to-door tools v3, Instagram). "No more Tech Talk version." "With the Google Street View, it's good. I just don't need the random zooms all the time. I want you to slowly zoom in, then show me a deck, show me a pool, show me a driveway, and don't jitter." "PropStream is great. It's just that the elements aren't showing up at the right time... you need to sync the animations to the words." "Income map is not good... it needs to show a heat map of a certain area... take a map, like a neighborhood, and look it up... at the end overlay it onto the Google Maps, without playing the video, just take a screenshot. Darker red is more money, closer to white is less money, with a legend on screen that's very small. And you highlight who's earning the most, who's earning the least." "SalesMapper is good though."
- Wrong: map B-roll used his raw screen-recorded pinch zooms (jittery). PropStream elements staggered from shot start, so they landed late. Income map was a generic green grid, not a real place.
- Rules: (1) TikTok versions stopped; Instagram only unless he asks. (2) Map moves are built from registered stills (SIFT similarity chain into one coordinate space, one eased fixed-point zoom), never his raw pinch footage. (3) Each animated element starts on its own word (cue - 0.04 s, 0.15-0.25 s ease), not on the shot start; one continuous screen per topic with the highlight jumping card to card. (4) Data maps: trace real blocks from the actual neighborhood screenshot, show the plain map first, then the same blocks over the Google Maps still; sequential white-to-dark-red scale, tiny legend, highest and lowest called out on their words. Figures are illustrative unless he supplies real ones; say so.
- Fix: door_tools v4 (sv.py street view, inc.py income map, screens.html cue-synced PropStream, compose4.py).


**F49** (2026-11-24, 4 door-to-door tools v4). "I want the initial backdrop for picture canvas view to be brighter because I feel like it's unnecessarily dimmed right now."
- Wrong: all B-roll went through the SDR to HLG LUT at white 0.75, so the opening 4-way split read grey next to the 0.88 title box.
- Rule: full-screen app/graphic backdrops (screens, galleries) use the 0.88 white LUT (sdr2hlg_bright.cube, made by door_tools/mkcube.py) so they match the text boxes. His footage stays untouched (face luma checked: 741.9 vs 741.8).


**F50** (2026-11-24, 4 door-to-door tools v5). "Just remove the shadow around that white box at the start, the header." "I don't know why PropStream, the income checker, and SalesMapper are all so much darker... I need them normal light."
- Wrong: drop shadow on the hook box; all backdrops converted at 0.75 white; app clips had a -0.15 dimmed blur behind them; the PropStream spotlight dimmed the page at 45%.
- Rule: no shadow on header boxes. Every app/graphic backdrop uses the 0.88 white LUT (satellite Street View stays at 0.75). No dimming on blur fills. Spotlight dim 15% max. He also tried then cancelled a black header box: keep white box, black text.


**F51** (2026-11-24, 4 door-to-door tools v6). "Change the header to black back white text." "Make the lowest something else that's visual, because I can only see the highest. And I want them both to pop up a little quicker."
- Wrong: lowest callout sat on a tiny corner block, partly behind him and the scale bar; callouts landed late ("money" / "It's").
- Rule: hook header box is black with white text for this series (tool labels stay white). Data-map callouts go on large blocks clear of the person cutout, with up/down arrows and a pulsing outline on the pale block. Callouts pop on the earliest matching word ("earning" / "money"), not the end of the phrase.


**F52** (2026-11-24, 4 door-to-door tools v7). "Integrate the bit from SalesMapper about how reps can knock from their lock screen. I feel like that's been missed."
- Wrong: IMG_9934 (the lock-screen line) was left out of the cut because its Whisper transcript merged a re-take ("...lets reps track" said twice), so the useful line looked broken.
- Rules: before dropping a take, re-transcribe it in isolation; Whisper merges stumbles into one long word span (a 3.5 s "track"). Keep the clean second take. When the spoken word is wrong for the feature ("home screen" for lock screen), captions show the right word, audio untouched (his choice). Product demos come from salesmapper.ca captured frame-accurately: block video.play, seek the video per frame, pause and seek CSS animations (door_tools/cap_lock3.js). Sync the key action (Sale tap) to the matching word ("knocks"). Keep widget buttons above the caption band (y < 900).

**F53** (2026-11-24, SalesMapper lifetime-trial video v1). "Create a video centered around SalesMapper, playing off the concept of the lifetime free trial, pull the clips from the other video. Ask me questions." Pop-up answers: hook, reveal, offer; 3x hook + 43%/50% (120% dropped); lock-screen demo, stat cards, "free forever" graphic; ~20 s Instagram only. Lifetime trial is real for commenters (the site says 14 days with a card; Nathan confirmed commenters get lifetime).
- Cut (edits/sm_lifetime/cut.py): 9948 hook (kept whole: the gap finder cut the quiet "thing"), 9931 from 1.40 ("SalesMapper" only, "Last is" dropped), 9934 7.6-11.2 (clean second take), 9936, 9937. 21.8 s.
- Found by QA: 9948 is MONO, the old clips stereo; concatenating PCM segments with different channel counts garbled every clip after the hook. Rule: force -ac 2 on every segment (now in cut.py). Re-transcribe the whole cut in chunks after every splice.
- Found by QA: check the offer against salesmapper.ca before building a graphic around it; ask if it differs.
- Build (compose.py): hook push-in 1.0->1.1 and 1.2x bottom-anchored after, done by warping the 10-bit Y/U/V planes (no colour math); white two-tier hook card (H10/H14); App Store-style reveal row; salesmapper.ca lock-screen demo at full height (lock phone until the Sale tap, then the map phone for the pin drop, F52 "phones larger"); KPI tiles +43% / +50% on their words; iOS subscription card "Trial ends: Never, $0.00"; red "comment MAP". SFX on the same cues. Captioned + clean (H13).

## Shipped
- d2d_3_ways_close_rate_v4b.mp4 (1-2-3 order). Shipped 2026-11-21. Superseded: it had A/V drift (F15).
- d2d_3_ways_123_order_FINAL.mp4 and d2d_3_ways_giftcard_first_FINAL.mp4. Shipped 2026-11-21, both QA PASS. Open: the qualifying questions and gift card business names are placeholders.

- d2d_spouse_objection_v1_final.mp4 ("I need to talk to my spouse"). Shipped 2026-11-21, 19.3 s, QA PASS. Built from playbook v8 with no corrections yet. New inserts: notspouse, theline, branch (cue-timed to word times). Retakes cut in IMG_9748 and IMG_9749. QA dead-air check made plosive-aware (the "k" in "Close" was misread as silence; found by QA).

- d2d_spouse_objection_v1_captions.mp4 and d2d_spouse_objection_v1_clean.mp4: rebuilt with H11-H13 (iOS Notes, iMessage, Reminders; real app Sale tap; TikTok Sans labels, hook and captions). QA PASS on both. Found in review: labels covered the phone title bars, so labels are now hidden over screens.

- d2d_spouse_objection_v3_captions.mp4 and d2d_spouse_objection_v3_clean.mp4: runtime and crop fixes (F23). QA PASS, runtime gate PASS. Nathan approved the look.

- d2d_spouse_objection_v1_sfx_captions.mp4 and d2d_spouse_objection_v1_sfx_clean.mp4: push-in hook, two-tier headline, 77 subtle synthesized SFX. QA PASS on both, runtime gate PASS.

- d2d_not_interested_captions.mp4 and d2d_not_interested_clean.mp4 ("We're not interested" objection, stitched hook from @claytonnelson_ with a credit tag). Shipped 2026-11-21, 24.7 s, QA PASS on both, runtime gate PASS (Notes hold 1.5 s). Edit script: content_kit/edits/not_interested/make_edit5.py.
- d2d_not_interested v2 (captions + clean): 30.5 s, adds IMG_9774 (clean take), IMG_9780, IMG_9781; inserts: app door-outcomes, iOS Notes, app tap→Interested; no credit tag. QA PASS both, runtime gate PASS.
- d2d_not_interested v3: 29.9 s, ends role-play on "out of your hair anyway", Notes types 4 lines. QA PASS both.
- d2d_day_one_captions.mp4 / _clean.mp4 (AI cinematic rep + manager scene): 11.9 s, QA PASS both.
- d2d_3_lines_clean.mp4 / _captions.mp4 ("3 lines", light style): 54.1 s, 15 takes, QA PASS both.
- d2d_3_lines_SPLICE_original_picture.mp4: 54.2 s, plain splice, original HDR kept (luma diff 0.6/1023).
- d2d_3_lines_SPLICE_tight5.mp4: 51.3 s, tight splice, original HDR, speech at 0.04 s.
- d2d_IQ_terms.mp4 (+ d2d_IQ_no_cards.mp4, card PNG pack): 18.9 s, 16 term cards, original HDR, speech at 0.03 s.
- d2d_IQ_v2.mp4: zoom 1.2x up-shift, header, one-word captions, 16 brighter cards, original HDR. 18.9 s.
- d2d_IQ_v3.mp4: bigger cards + red follow pop-up. 18.9 s, original HDR.
- d2d_IQ_v4.mp4 (Reels) + d2d_IQ_v4_TIKTOK.mp4: 18.6 s, vivid red CTA, TikTok-safe layout.
- business_IQ_instagram.mp4 + business_IQ_tiktok.mp4 (F43 card shapes): 20.5 s, cards rotate wide/square/tall, audio decodes clean, face luma within 2.5/1023 of source, original HDR.

- business_IQ_instagram.mp4 + business_IQ_tiktok.mp4: 20.5 s, 16 spec-sheet cards, 140 px captions, original HDR. Shipped 2026-11-23 after a corrupt-audio first delivery (F44).
- business_IQ_instagram.mp4 + business_IQ_tiktok.mp4 v2 (F45): wide/wide/square, chin-tracked cards, 20.5 s, DELIVERY PASS both.
- business_IQ v3 (F46): false start cut from outro, 19.7 s, DELIVERY PASS both. Nathan: "besides that, it's good."
- tools_v4_instagram.mp4 (4 door-to-door tools, F48): smooth still-based Street View zoom, word-synced PropStream, Sunningdale income heat map. Instagram only.
- tools_v8_instagram.mp4 (F48-F52): 44.5 s, lock-screen line + site demo added, black hook header, bright backdrops. Instagram only.
- sm_lifetime_captions.mp4 + sm_lifetime_clean.mp4 (F53): 21.8 s, Instagram, DELIVERY PASS both, face luma within 1% of source.

## Performance
(Log 48 h stats per posted video here.)
