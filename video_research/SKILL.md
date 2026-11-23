---
name: "short-form-video-edit"
description: "Edit Nathan's raw short-form footage (SalesMapper / D2D sales Reels, TikToks, Shorts) into finished videos, post captions and edit plans. Loads a living playbook from GitHub every run and writes Nathan's feedback back into it, so the editing improves over time."
---

# Short-form video edit (loader + learning loop)

This skill is a loader. The real instructions live in a living playbook on GitHub that changes as Nathan gives feedback. Never edit from memory or from an old copy.

## Step 0: load the latest playbook (always, before anything else)
Source of truth: GitHub repo `nathanup18/SalesMapperIos`, branch `claude/zen-cori-hyds6x` (use `main` once the playbook is merged there). Read these files:
- `video_research/edit_playbook/PLAYBOOK.md`: rules, preferences, pipeline and QA gate. Hard rules (section 1) override everything.
- `video_research/edit_playbook/FEEDBACK_LOG.md`: every past correction. Skim the latest entries and the "Shipped" list.
- Tools: `video_research/content_kit/` (make_edit.py, qa_check.py, delivery_check.py, inserts.html, render2.js, mockup.html, brand notes).

How to read them, in this order:
1. If the repo is checked out locally (Claude Code): `git fetch origin <branch>` and read the files from `origin/<branch>`.
2. Otherwise use the GitHub connector (`get_file_contents`, owner `nathanup18`, repo `SalesMapperIos`, ref `<branch>`).
3. If neither works, tell Nathan the playbook couldn't be loaded and use the fallback rules at the bottom of this file. Don't pretend it loaded.

Say in one line which playbook version you loaded (for example, "Playbook v5 loaded").

## Step 1: edit by the playbook
Follow PLAYBOOK.md: the pipeline (section 5), visual aids (section 4), preferences (section 2), and research defaults only where the playbook is silent.
- Ask Nathan formatting questions (layout, text style, caption choice, which take, where elements go) with the AskUserQuestion pop-up: 2-4 multiple-choice options, recommended first. Don't ask what the playbook already answers.
- Never change the brightness, saturation or look of his footage without asking first (H0). Keep his original HDR picture.

## Step 2: QA gate (blocks delivery)
Run `qa_check.py` and `delivery_check.py` on the rendered file and review the boundary contact sheet yourself. Fix every FAIL before sending. Re-transcribe the output to confirm no word was clipped. Tell Nathan the QA result in one line, and list any placeholders or judgment calls.

## Step 3: learning protocol (every time Nathan reacts, in the same turn)
Nathan wants this editing to get better every time it's used. Treat each correction, preference or reaction as training data:
1. Append an entry to FEEDBACK_LOG.md: the next F-number, date, video and version, what he said (near verbatim), what was wrong, and the rule it creates.
2. If it generalizes, update PLAYBOOK.md. Hard rules go in section 1, taste goes in section 2. Bump the version and add a CHANGELOG line.
3. If the rule can be checked automatically, add the check to qa_check.py.
4. Also log problems you find yourself in QA, marked "(found by QA)". Those count too.
5. Commit and push to the playbook branch with the message `playbook: <rule>`. If you can't write to GitHub from this surface, put the exact patch (the new log entry and the rule text) in your reply and tell Nathan it still needs committing.
6. Then make the fix and re-run QA.
Never weaken or delete a hard rule unless Nathan says so. If new feedback conflicts with an old rule, follow the new feedback, update the rule, and note the change in the log.

## Step 4: after posting
When Nathan shares stats (views, 3-second hold, average % watched, follows), log them under "Performance" in FEEDBACK_LOG.md. Note which editing choices the top videos share. A weekly consolidation run merges duplicate feedback and promotes repeated patterns to hard rules.

## Fallback hard rules (only if the playbook can't be loaded)
- **Never brighten, saturate or regrade his footage without asking first.** Keep the original iPhone HDR (HLG, bt2020, 10-bit x265). Convert graphics into HDR, never the footage out of it.
- **Ask with pop-ups:** formatting choices and captions go to him as AskUserQuestion multiple choice.
- **No dead space:** speech within 0.05 s of frame 0; cut every silence over ~0.1 s, splitting takes; never cut through a word; re-transcribe to verify. Cut points come from the waveform, not Whisper. Keep segment audio as PCM until the final encode (avoids A/V drift).
- **Captions and graphics:** never over the mouth. Measure the chin and place everything below it; graphics fully opaque.
- **Opening:** talking-head hooks open on the face, with no app or graphic over the hook.
- **Visual aids:** where there's no B-roll, build custom animated visuals (gift card, question card and so on) and cut back and forth with the face.
- **No flashes or black frames:** a section-opening graphic starts on the cut. Snap boundaries to the frame grid. Pad inserts with their first frame.
- **Full animations:** graphics play to completion and hold about 0.4 s.
- **Post captions:** lead with the most concrete story and its outcome, and end with "Follow for more D2D tips".
