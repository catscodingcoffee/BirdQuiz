# BirdQuiz

A flashcard-style bird identification quiz app for iPhone.

## Features

- **Named Decks** — create as many decks as you want (backyard birds, raptors, warblers, etc.)
- **Bird Search** — search the full eBird taxonomy (~10,000 species) by common or scientific name
- **Photo + Audio Cards** — each card fetches a top-rated photo and audio clip automatically
- **Two Quiz Modes**
  - *Flashcard* — see the image or hear the sound, tap to flip and reveal, mark Got It / Missed It
  - *Multiple Choice* — pick from 4 options, instant feedback
- **Three Media Modes** — Image only, Sound only, or Mixed (alternates between the two)
- **Score Screen** — percentage ring, correct/incorrect counts, restart button

## Data Sources

| Source | Used for |
|---|---|
| [eBird API](https://documenter.getpostman.com/view/664302/S1ENwy59) | Full species taxonomy & search |
| [iNaturalist API](https://api.inaturalist.org/v1/docs/) | Bird photos (public, no auth required) |
| [Xeno-canto](https://xeno-canto.org/explore/api) | Audio clips |

## Setup in Xcode

### 1. Create the Xcode Project

1. Open Xcode → **File > New > Project**
2. Choose **iOS > App**
3. Set:
   - Product Name: `BirdQuiz`
   - Bundle Identifier: `com.yourname.BirdQuiz`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData** (or None — SwiftData is set up manually in the code)
4. Click **Next**, choose a save location

### 2. Add the Source Files

Delete the auto-generated `ContentView.swift` and `BirdQuizApp.swift`, then drag in all files from this repo maintaining the folder structure:

```
BirdQuiz/
├── BirdQuizApp.swift
├── Models/
│   ├── BirdSpecies.swift
│   └── DeckModels.swift
├── Services/
│   ├── eBirdService.swift
│   ├── iNaturalistService.swift
│   ├── XenoCantoService.swift
│   ├── MediaService.swift
│   └── KeychainHelper.swift
├── ViewModels/
│   ├── BirdSearchViewModel.swift
│   └── QuizViewModel.swift
└── Views/
    ├── ContentView.swift
    ├── DeckListView.swift
    ├── DeckDetailView.swift
    ├── BirdSearchSheet.swift
    ├── QuizView.swift
    ├── SettingsView.swift
    └── Components/
        ├── FlashcardView.swift
        └── BirdRowView.swift
```

### 3. Configure Info.plist

Add the following keys to your app's `Info.plist` (or via the target's Info tab):

```xml
<!-- Allow loading bird images/audio from external URLs -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 4. Get an eBird API Key

1. Sign in or create a free account at [ebird.org](https://ebird.org)
2. Go to [ebird.org/api/keygen](https://ebird.org/api/keygen)
3. Copy your API key
4. Launch the app, go to **Settings**, paste the key, tap **Save API Key**
5. The taxonomy will download automatically (~1–2 MB, cached for 7 days)

### 5. Build & Run

Select your iPhone or a simulator (iOS 17+) and hit Run.

## Notes

- **Minimum iOS**: 17.0 (uses SwiftData and `@Observable`-compatible patterns)
- **iNaturalist API**: Photos are fetched from the public iNaturalist taxa API — no authentication required. Audio is fetched from the Xeno-canto public API.
- **API Key storage**: Your eBird API key is stored securely in the iOS Keychain (not UserDefaults).
- **Offline**: Once media URLs are fetched and saved per card, the card row thumbnails and quiz will load from cache (iOS URLCache). The taxonomy is stored in UserDefaults after first download.
