# AI Story Buddy

Kid-friendly Flutter app: pick a story, hear it read aloud with synced highlighting, answer a quiz, see a scorecard.

```bash
flutter pub get
cp .env.example .env   # add ELEVENLABS_API_KEY + ELEVENLABS_VOICE_ID
flutter run
```

---

## Framework choice

**Flutter** — single codebase for Android (primary), iOS, and web; smooth animations; hot reload for UI polish.

**Riverpod** — TTS runs on async streams (`events`, `progress`). Riverpod keeps narration, quiz, and UI decoupled so the whole screen does not rebuild on every highlight tick.

---

## Audio end → quiz transition

No timers. The handoff is **event-driven**:

1. `TtsService` emits `TtsEventType.completed` when playback finishes (ElevenLabs `onPlayerComplete` or `flutter_tts` completion handler).
2. `StoryBuddyNotifier._onTtsEvent` sets `ttsState = completed`, `phase = storyComplete`, `showQuiz = false`.
3. UI shows a **Story finished** banner and buttons: **Continue to Quiz**, **Replay**, **More Stories**.
4. User taps **Continue to Quiz** → `continueToQuiz()` sets `phase = quiz`, `showQuiz = true`, resets question index.

The quiz never auto-appears; the child chooses when to move on. Phase changes are explicit (`AppPhase` enum), not inferred from widgets.

---

## Data-driven quiz

Quiz lives in `assets/data/quiz.json`, keyed by story id. Each story has **5 questions**; option count varies (3–5).

```json
"pip_woods": {
  "questions": [
    { "question": "...", "options": ["Red", "Green", "Blue", "Yellow"], "answer": "Blue" },
    { "question": "...", "options": ["Afraid", "Curious", "Angry"], "answer": "Curious" }
  ]
}
```

- `QuizRepository.loadQuizForStory(storyId)` parses JSON at runtime.
- `QuizQuestion.fromJson` accepts any `options` array length.
- `QuizSection` builds choices with `List.generate(question.options.length, …)` — no hardcoded option count.
- `quizSetProvider` reloads when `selectedStoryId` changes.

Swap the repository to HTTP later; models and UI stay the same.

---

## Caching

| Asset | Approach |
|-------|----------|
| **Quiz JSON** | Bundled in assets; loaded once per story via `FutureProvider` (in-memory for app lifetime). |
| **ElevenLabs audio** | Fetched per narration; played from in-memory `BytesSource` (no disk write). Re-fetch on resume if session was lost. |
| **Read / progress** | `shared_preferences` — which stories are done, paused narration position. |

**Remote audio (if added):** cache MP3 by `storyId` + text hash in app documents (`path_provider`). Check `If-None-Match` / ETag on refetch. On miss or offline, use cached file or fall back to `flutter_tts`.

---

## Audio loading & failure states

| `TtsState` | What happens | UI |
|------------|--------------|-----|
| `idle` | Ready | “Read Me a Story” |
| `preparing` | ElevenLabs HTTP or TTS init | Spinner — “Preparing story…” |
| `speaking` | Audio playing | “Pause”; buddy animates |
| `paused` | Playback frozen; progress saved | “Continue Story” |
| `completed` | Story done | Story-complete actions |
| `error` | API/TTS failure | Red banner + “Try Again” |

**Engine:** ElevenLabs with-timestamps API when `.env` keys exist; otherwise `flutter_tts` (required on web — CORS blocks ElevenLabs).

**Errors:** `setErrorHandler`, HTTP failures, and `speak()` try/catch all emit `TtsEventType.error` with a friendly message. User can always retry; app does not hang.

---

## Performance profiling

**Tool:** Flutter DevTools → Performance tab, `flutter run --profile` on a mid-range Android emulator (~3 GB RAM).

**Measured:** frame build time (idle story screen), frame time during confetti/shake, rebuild scope on TTS progress events.

| Metric | Before | After |
|--------|--------|-------|
| Rebuilds per highlight tick | Full screen (`setState` on root) | Notifier listeners + targeted widgets |
| Buddy repaint | Whole layout | `RepaintBoundary` around `CustomPaint` mascot |
| Confetti cost | Higher particle count | Capped burst; overlay isolated |

**Changes:** migrated root `setState` → `StoryBuddyNotifier`; `RepaintBoundary` on buddy; confetti tuned; no `google_fonts` network fetch (system fonts); highlight updates via stream, not rebuild loops.

> **Screenshot:** Run profile mode, interact with quiz + confetti, capture the Performance timeline in DevTools and attach as `docs/frame_timing.png` for submission.

---

## Mid-range Android optimizations

- **7 dependencies** — no Lottie/Rive; buddy is `CustomPaint`.
- **No mandatory network** — quiz is bundled; TTS falls back to device engine.
- **Fixed viewport** (`MobileStoryShell`) — one scroll region, pinned controls; less layout work.
- **Android audio context** — `audioplayers` uses `speech`/`media` usage for clearer speaker output.
- **Const widgets** where static (header, labels).

---

## AI usage & judgment

| Area | AI help | Human call |
|------|---------|------------|
| Scaffolding, TTS wiring, highlight sync | Yes | Reviewed and iterated on lag/sync |
| Rive/Lottie mascot | Suggested | **Rejected** — extra MB + decode cost; kept `CustomPaint` buddy |
| Auto-advance to quiz on TTS end | Suggested | **Changed** — `storyComplete` + explicit “Continue to Quiz” for kid pacing |
| `vibration` plugin | Used initially | **Removed** — compileSdk issues; replaced with `HapticFeedback` |
| ElevenLabs only | Considered | **Hybrid** — ElevenLabs on mobile for quality + timestamps; `flutter_tts` fallback for web/offline |

**What failed:** Highlighting lagged behind voice when using trailing word windows + throttled progress. **Fix:** current-word window, 160 ms audio lead, `SpeechTextMapper` so display text and TTS timestamps stay aligned. **Also:** `vibration` broke Android build — swapped to built-in haptics.

---

## Structure (quick)

```
lib/providers/story_buddy_provider.dart   # State machine
lib/services/story_services.dart          # TtsService + QuizRepository
assets/data/quiz.json                     # Per-story questions
```
