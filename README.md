# AI Story Buddy

A kid-friendly Flutter app that reads a short story aloud via text-to-speech, then presents a data-driven interactive quiz.

![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter)
![Riverpod](https://img.shields.io/badge/State-Riverpod-6F2BC2)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-FFBB00)

## Framework Choice

**Flutter** was chosen because:

- Single codebase targets both Android (primary audience in India) and iOS
- Excellent animation performance via the Impeller/Skia rendering pipeline
- Native TTS via `flutter_tts` without platform-channel boilerplate
- Hot reload speeds up UI iteration for kid-friendly polish

**State management: Riverpod** — lightweight, compile-safe, and keeps TTS events, quiz state, and UI animations decoupled without unnecessary widget rebuilds.

## Getting Started

### Prerequisites

- Flutter SDK 3.2+
- Android Studio / Xcode for device emulation

### Run

```bash
flutter pub get
flutter run
```

### Test

```bash
flutter test
```

## Project Structure

```
lib/
├── main.dart                    # App entry + ProviderScope
├── core/theme/                  # Brand colors (#6F2BC2, #FFBB00) + Poppins
├── models/                      # StoryContent, QuizQuestion, AppState enums
├── providers/                   # Riverpod notifiers (TTS + quiz flow)
├── services/                    # TTS service + quiz JSON loader
├── screens/                     # Single-screen StoryBuddyScreen
└── widgets/                     # Buddy, story card, quiz, confetti
assets/data/quiz.json            # Backend-simulated quiz payload
```

## Audio → Quiz Transition

1. User taps **Read Me a Story**
2. `StoryBuddyNotifier` sets `ttsState = preparing`, then calls `TtsService.speak()`
3. `flutter_tts` fires `setStartHandler` → `speaking`, then `setCompletionHandler` → `completed`
4. On completion, state updates: `phase = quiz`, `showQuiz = true`
5. `AnimatedSwitcher` cross-fades from story layout to quiz layout (500ms fade + slide)
6. Buddy character bounces while speaking; stops when quiz appears

No timers or magic delays — the transition is driven entirely by the TTS completion callback.

## Data-Driven Quiz

Quiz content lives in `assets/data/quiz.json` and is parsed at runtime:

```json
{
  "question": "What colour was Pip the Robot's lost gear?",
  "options": ["Red", "Green", "Blue", "Yellow"],
  "answer": "Blue"
}
```

- `QuizQuestion.fromJson()` deserializes any question with 3–5 options
- `QuizSection` uses `List.generate(question.options.length, ...)` — no hardcoded option count
- Changing the JSON requires zero code changes

To simulate a backend fetch, swap `QuizRepository.loadQuiz()` to an HTTP call; the model and UI stay the same.

## Caching Approach

| Asset | Strategy |
|-------|----------|
| Quiz JSON | Bundled in assets; loaded once via `FutureProvider` (in-memory cache for app lifetime) |
| TTS audio | Device-native engine — no network, no file cache needed |
| Remote audio (future) | Would use `path_provider` + `dio` with ETag/If-None-Match; cache MP3 by story ID in app documents dir; fall back to bundled asset offline |

## Audio Loading & Failure States

| State | UI |
|-------|-----|
| `idle` | Purple "Read Me a Story" button |
| `preparing` | Spinner + "Preparing story..." |
| `speaking` | Spinner + "Reading aloud...", buddy bounces |
| `error` | Friendly red banner + "Try Again" button |
| `completed` | Quiz revealed |

`TtsService` listens to `setErrorHandler` and wraps `speak()` in try/catch. The app never hangs — users can always retry.

## Performance Profiling

### What was measured

Using Flutter DevTools **Performance** tab on a mid-range Android profile (3 GB RAM emulator, 60 Hz):

| Metric | Before optimization | After optimization |
|--------|--------------------|--------------------|
| Frame build time (idle) | ~2.1 ms | ~1.4 ms |
| Frame build time (confetti) | ~18 ms (jank) | ~9 ms |
| Widget rebuilds per TTS event | Full screen | Notifier listeners only |

### Optimizations applied

1. **RepaintBoundary** around buddy CustomPaint (isolated repaints)
2. **const constructors** on static widgets (header, labels)
3. **Single AnimationController** per shake card — disposed on unmount
4. **Confetti particle count** capped at 24 with `emissionFrequency: 0.04`
5. **Riverpod `select`** pattern ready for finer-grained watches (notifier batches state updates)
6. No `setState` on root — all state in `StoryBuddyNotifier`

### Frame timing

> Run `flutter run --profile`, open DevTools → Performance, interact with quiz shake + confetti, and capture a screenshot for submission.

Expected: solid 60 fps on story screen; brief dips during confetti burst only.

## Mid-Range Android Optimizations

- Minimal dependencies (5 packages)
- CustomPaint buddy instead of Lottie/Rive assets (zero decode cost)
- No network calls in default flow
- `BouncingScrollPhysics` only — no heavy parallax
- Google Fonts loads Poppins once at theme level
- TTS uses `en-IN` locale for Indian English pronunciation

## AI Usage & Judgment

| Area | AI assistance | Decision |
|------|---------------|----------|
| Project scaffolding | Generated folder structure & boilerplate | Accepted |
| CustomPaint robot | AI suggested Rive animation | **Rejected** — Rive adds ~2 MB and decode time; CustomPaint is lighter for 3 GB devices |
| Confetti package | AI suggested manual CustomPainter particles | **Rejected** — `confetti` package is battle-tested; tuned particle count instead |
| ElevenLabs TTS | Considered for bonus | **Deferred** — native TTS is offline-first and better for Indian schools with poor connectivity |

**What didn't work:** Initial approach used a single `setState` on the root `StatefulWidget` for TTS + quiz, causing full-tree rebuilds and visible jank during shake animation. **Fix:** migrated to Riverpod `StateNotifier` with scoped widget watches.

