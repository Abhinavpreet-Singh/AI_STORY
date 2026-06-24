# AI Story Buddy

A kid-friendly Flutter app that reads illustrated stories aloud with synced word highlighting, then runs a per-story quiz with haptics, confetti, and a scorecard.

![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter)
![Riverpod](https://img.shields.io/badge/State-Riverpod-6F2BC2)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-FFBB00)

---

## Features

| Area | What it does |
|------|----------------|
| **Story library** | 3 stories; checkmark on stories read before |
| **Narration** | ElevenLabs TTS (mobile) with `flutter_tts` fallback (web / offline) |
| **Highlighting** | Current word + next word highlighted in sync with audio |
| **Pause / resume** | Pause mid-story; open menu saves progress to device |
| **Quiz** | 5 questions per story, loaded from JSON |
| **Feedback** | Shake + haptics on wrong answer; confetti on correct |
| **Scorecard** | Stars, correct/wrong counts at the end |

---

## Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| UI | **Flutter** | One codebase → Android, iOS, Web, desktop |
| State | **Riverpod** | TTS streams, quiz flow, and UI stay decoupled |
| TTS (primary) | **ElevenLabs API** | Natural voice + character timestamps for highlighting |
| TTS (fallback) | **flutter_tts** | Device engine when API unavailable (e.g. web CORS) |
| Playback | **audioplayers** | Streams ElevenLabs MP3 bytes in memory |
| Persistence | **shared_preferences** | Read stories + in-progress narration |
| Config | **flutter_dotenv** | API keys in `.env` (not committed) |
| Quiz data | **Bundled JSON** | `assets/data/quiz.json` — no backend required |

---

## App Flow

```
Story Menu → Pick story → Read aloud (highlighted) → Story Complete
    → Continue to Quiz (5 Qs) → Scorecard → Pick Another Story
```

**Phases** (`AppPhase`): `storyMenu` → `story` → `storyComplete` → `quiz` → `scorecard`

**TTS states** (`TtsState`): `idle` → `preparing` → `speaking` ↔ `paused` → `completed` / `error`

Opening the **menu** during narration pauses audio and saves character position + highlight so the child can resume later.

---

## TTS & Audio (how it works)

### Hybrid engine

```
speak(story.text)
    │
    ├─ ELEVENLABS_API_KEY + VOICE_ID set?
    │       YES → POST /v1/text-to-speech/{voice}/with-timestamps
    │             → base64 MP3 + character_end_times_seconds
    │             → audioplayers plays BytesSource (no temp file)
    │             → onPositionChanged drives highlight index
    │
    └─ NO / API fails → flutter_tts (device TTS)
                        → setProgressHandler drives highlight index
```

### Speech text vs display text

Stories keep punctuation on screen (`His gear!`) but TTS receives a cleaned version — `!`, `?`, quotes stripped via `SpeechTextMapper` so the voice does not read “exclamation mark”.

Highlight indices always map back to the **display** text the child sees.

### Highlight sync

1. Raw character index from audio position (ElevenLabs) or TTS progress (native)
2. Small **160 ms lead** on ElevenLabs to offset player latency
3. `HighlightHelper` snaps to the **current word + 1 word ahead**
4. `StoryCard` dims read text, highlights the active phrase, auto-scrolls

### Pause / resume

| Engine | Pause | Resume |
|--------|-------|--------|
| ElevenLabs | `audioplayers.pause()` | `audioplayers.resume()` |
| Native TTS | `flutter_tts.pause()` | Re-speaks from saved character offset |

Progress is persisted in `StoryProgressRepository` (story id, char index, highlight range).

---

## Data

### Stories — `lib/models/story_content.dart`

Hardcoded catalog (`pip_woods`, `luna_cloud`, `finn_tide`). Each has `id`, `title`, `subtitle`, `emoji`, `text`.

### Quizzes — `assets/data/quiz.json`

Keyed by story id; **5 questions** each:

```json
{
  "pip_woods": {
    "questions": [
      {
        "question": "What colour was Pip's lost gear?",
        "options": ["Red", "Green", "Blue", "Yellow"],
        "answer": "Blue"
      }
    ]
  }
}
```

`QuizRepository.loadQuizForStory(storyId)` loads at runtime. `quizSetProvider` reloads when the selected story changes.

### Read / in-progress — `shared_preferences`

| Key | Stores |
|-----|--------|
| `read_story_ids` | Stories finished at least once |
| `story_progress` | Paused narration (story id, char index, highlight) |

---

## Project Structure

```
lib/
├── main.dart                         # dotenv load, ProviderScope, theme
├── core/theme/                       # Brand colors, typography
├── models/
│   ├── app_state.dart                # TtsState, AppPhase, QuizAnswerState
│   ├── story_content.dart            # StoryCatalog (3 stories)
│   ├── quiz_question.dart            # QuizQuestion, QuizSet
│   └── saved_story_progress.dart
├── providers/
│   └── story_buddy_provider.dart     # StoryBuddyNotifier — main state machine
├── services/
│   ├── story_services.dart           # TtsService, QuizRepository
│   ├── story_read_repository.dart
│   └── story_progress_repository.dart
├── screens/
│   └── story_buddy_screen.dart       # Phase routing + MobileStoryShell
├── utils/
│   ├── highlight_helper.dart         # Word-window highlight math
│   └── speech_text_mapper.dart       # Display ↔ speech text mapping
└── widgets/
    ├── story_menu.dart               # Story picker
    ├── story_card.dart               # Scrollable text + highlighting
    ├── story_controls_bar.dart       # Read / Pause / Continue / Quiz
    ├── quiz_section.dart             # Questions + shake animation
    ├── scorecard.dart
    ├── buddy_character.dart          # Animated mascot (CustomPaint)
    ├── mobile_shell.dart             # Fixed phone viewport layout
    └── celebration_overlay.dart      # Confetti wrapper
```

---

## Setup

### Prerequisites

- Flutter SDK 3.2+
- Android Studio / Xcode (for emulators)
- [ElevenLabs](https://elevenlabs.io) account (optional but recommended for mobile)

### Environment

Copy `.env.example` → `.env` at project root:

```env
ELEVENLABS_API_KEY=your_api_key_here
ELEVENLABS_VOICE_ID=your_female_voice_id_here
```

Without these keys the app falls back to device TTS.

### Run

```bash
flutter pub get
flutter run                  # default device
flutter run -d chrome        # web (device TTS — ElevenLabs blocked by CORS)
flutter run -d emulator-5554 # Android emulator
```

### Test

```bash
flutter analyze
flutter test
```

---

## Architecture (state)

```
┌─────────────────────────────────────────────────────────┐
│  StoryBuddyScreen (ConsumerWidget)                      │
│    watches storyBuddyProvider + quizSetProvider         │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│  StoryBuddyNotifier (StateNotifier)                     │
│    phase, ttsState, highlights, quiz index, scores      │
│    listens → TtsService.events + .progress              │
└────────────┬───────────────────────────┬────────────────┘
             │                           │
┌────────────▼──────────┐    ┌───────────▼────────────────┐
│  TtsService           │    │  Repositories              │
│  ElevenLabs / native  │    │  Quiz, Read, Progress      │
│  audioplayers         │    │  (shared_preferences)      │
└───────────────────────┘    └────────────────────────────┘
```

All narration side-effects flow through **streams** into the notifier — the UI never polls TTS directly.

---

## Key Dependencies

```yaml
flutter_riverpod   # State management
flutter_dotenv     # .env secrets
flutter_tts        # Device TTS fallback
http               # ElevenLabs API
audioplayers       # MP3 playback + position events
confetti           # Correct-answer celebration
shared_preferences # Read stories + resume progress
```

---

## Design Notes

- **Mobile-first layout** — `MobileViewport` (430 px) with pinned controls; story scrolls inside the card only
- **CustomPaint buddy** — lightweight mascot, no Lottie/Rive asset cost
- **No root setState** — single notifier owns the state machine; widgets rebuild via `ref.watch`
- **Offline quiz** — JSON bundled; swapping `QuizRepository` to HTTP needs no UI changes

---

## License

Private / educational project — not published to pub.dev.
