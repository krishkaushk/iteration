# iteration — CLAUDE.md

Personal iOS fitness tracking app (renamed from "GymTracker" to "iteration" on 2026-08-04). Core motivation: an app that **rewards/reinforces the habit of going to the gym** — streaks, PRs, and a monthly goal are the main feature. Custom exercises and switching gyms are secondary, swappable features, not the focus. A secondary design problem the app also addresses is **equipment variance** — the same exercise on different machines or in different gyms produces incomparable weight data; not yet built (Phase 4).

Single user, personal use only. Not targeting the App Store.

**Naming note**: the rename is complete everywhere except one cosmetic leftover. `.xcodeproj` is `iteration.xcodeproj`, the target/scheme/bundle identifier (`com.krishkaushik.iteration`) all say "iteration", and as of 2026-08-07 the on-disk folders are renamed too — repo root contains `iteration/` (was `GymTracker/`), which contains `iteration.xcodeproj` and `iteration/` (the source folder, was `GymTracker/GymTracker/`). So the full path to the Xcode project is `iteration/iteration.xcodeproj`, and source files live at `iteration/iteration/*.swift`. The only thing still literally named "GymTracker" on disk is `GymTrackerApp.swift` (cosmetic only, doesn't affect the build — nobody's asked for it to change). Repo root itself is `/Users/krishkaushik/PersonalProjects/iteration` — if you're looking for this project and land in a `gym` folder instead, you're in the wrong (stale) place.

---

## Stack

| Layer | Choice |
|---|---|
| Language | Swift |
| UI | SwiftUI (deployment target 26.5) |
| Auth | Firebase Auth (email/password) |
| Database | Cloud Firestore (Firebase Spark plan — free) |
| Charts | Swift Charts (`import Charts`, built-in iOS 16+) |
| Widget | WidgetKit + ActivityKit — Live Activity built (`WorkoutWidgetExtension`, no App Group); home-screen widget still Phase 6 |
| Architecture | MVVM + `@Observable` (iOS 17+ pattern) |
| Package manager | Swift Package Manager |

Firebase packages: `FirebaseAuth`, `FirebaseFirestore` (native Firestore SDK has built-in `Codable` support — no separate `FirebaseFirestoreSwift` package)

Device: iPhone 17 Pro. No paid Apple Developer account — testing on Simulator during development, 7-day personal provisioning for device installs.

Default weight unit: **lbs**. A kg toggle is planned (Phase 5) but not yet built — no `weightUnit` field or UI exists yet.

---

## Xcode 26 / macOS 16 Constraints — CRITICAL

These rules apply to every file in this project. Violating them causes build failures.

- **No UIKit**: `import UIKit` is unavailable. No `UITabBarAppearance`, `UIColor`, `UITabBar`. (`.keyboardType(_:)` is fine despite taking a `UIKeyboardType` — confirmed it compiles without an explicit UIKit import, e.g. `NumericField.swift`; the earlier blanket claim that `UIKeyboardType` itself was unavailable was wrong.)
- **No `textInputAutocapitalization`**: removed in iOS 26.
- **No `Group { if ... }` conditional content in overlays**: causes TableColumn type-inference failure. Use plain `if/else` with full modifier chains on each branch.
- **Long chained collection operations time out the type checker**. Always break into explicitly typed intermediate `let` bindings:
  ```swift
  // BAD — type checker times out
  let volume = workout.exercises.flatMap { $0.sets }.filter { ... }.reduce(0.0) { ... }

  // GOOD
  let allSets: [ExerciseSet] = workout.exercises.flatMap { $0.sets }
  let validSets = allSets.filter { $0.weight > 0 && $0.reps > 0 }
  let volume: Double = validSets.reduce(0.0) { acc, s in acc + s.weight * Double(s.reps) }
  ```
- **Tab bar**: use only `.tint(Color.appPrimary)`. No `UITabBarAppearance`.
- **Color scheme**: `MainTabView` sets `.preferredColorScheme(.dark)` so Swift Charts renders correctly on the dark theme.

---

## Project Structure

Full path from repo root: `iteration/iteration.xcodeproj` (project) and `iteration/iteration/` (source, shown below as `iteration/` for brevity).

```
iteration/
  GymTrackerApp.swift          — app entry point, FirebaseApp.configure() in init()
  ContentView.swift            — root router (loading → SignInView or MainTabView)
  Extensions/
    Color+Theme.swift          — dark theme palette
  Models/
    AppTab.swift               — enum AppTab: home, workout, history, progress, profile
    Exercise.swift             — system + custom exercise
    Gym.swift
    WorkoutSession.swift       — WorkoutSession, WorkoutExercise, ExerciseSet
    BodyWeightLog.swift        — body weight log entries
    UserSettings.swift         — monthlyGoal (default 20)
    WorkoutActivityAttributes.swift — ActivityAttributes/ContentState for the workout Live Activity; Firebase-free, shared with WorkoutWidgetExtension target
    EndRestTimerIntent.swift   — LiveActivityIntent behind the Live Activity's Done button; Firebase-free, shared with WorkoutWidgetExtension target
  ViewModels/
    AuthViewModel.swift        — Firebase Auth listener, signIn/signUp/signOut
    WorkoutViewModel.swift     — active session, rest timer, home stats, Live Activity lifecycle
    ExerciseViewModel.swift    — exercise library + search
    GymViewModel.swift         — gym CRUD
    ProgressViewModel.swift    — strength/volume/bodyweight chart data
  Views/
    MainTabView.swift          — TabView shell (5 tabs)
    Auth/
      SignInView.swift
      SignUpView.swift
    Home/
      HomeView.swift           — live dashboard: streak, PRs, monthly goal, week activity
    Workout/
      WorkoutView.swift        — active workout session UI
      ExercisePickerView.swift — sheet to pick exercise during workout
      GymPickerView.swift      — sheet to pick gym at workout start
    History/
      HistoryView.swift        — past sessions, expandable, repeat workout
    Progress/
      ProgressTabView.swift    — Swift Charts: strength, volume, body weight
    Exercises/
      ExerciseListView.swift   — searchable library (accessed via Profile sheet)
      AddExerciseView.swift    — add custom exercise
    Profile/
      ProfileView.swift        — gym management, monthly goal stepper, exercise library sheet, sign out
    Components/
      BlockButton.swift
      BlockTextField.swift
      NumericField.swift       — custom field using String internally to allow clearing
  Services/
    FirestoreService.swift     — singleton, all Firestore reads/writes
  GoogleService-Info.plist     — Firebase config, flat in iteration/ (not under a Resources/ folder); gitignored, not committed
```

**`WorkoutWidgetExtension` target** — separate Widget Extension target for the rest-timer/set-tracking Live Activity (Lock Screen + Dynamic Island), full path `iteration/WorkoutWidget/` (sibling to `iteration/iteration/`, not nested inside it):
```
iteration/WorkoutWidget/
  WorkoutWidgetBundle.swift       — @main WidgetBundle
  WorkoutWidgetLiveActivity.swift — Lock Screen + Dynamic Island UI (ActivityConfiguration)
  Info.plist                      — NSExtensionPointIdentifier = com.apple.widgetkit-extension
```
No App Group — the Activity is driven entirely by in-process `Activity.update()` calls from `WorkoutViewModel`; the Done button's `LiveActivityIntent` runs in the app's own process and talks back to `WorkoutViewModel` via `NotificationCenter`, not shared storage. **If this target is ever deleted and recreated**: Xcode's Widget Extension wizard has defaulted to visionOS (`SDKROOT = xros`) rather than iOS in this project before, which silently breaks the `ActivityKit` import (unavailable on visionOS) — check `SUPPORTED_PLATFORMS`/`SDKROOT`/`TARGETED_DEVICE_FAMILY` in the new target's build settings before assuming a build failure is something else.

`Mockups/gym_tracker_ios_mockup_gold.html` at the repo root — early design reference, not part of the Xcode project.

---

## Architecture: MVVM + @Observable

- **Models**: plain Swift structs with `Codable` conformance, map 1:1 to Firestore documents
- **ViewModels**: `@Observable` classes, own all async Firestore/Auth operations, hold published state
- **Views**: SwiftUI Views, read from ViewModels via `@State` / `@Environment`
- **Services**: stateless helpers that wrap Firebase SDK calls

**Shared ViewModels injected at app root (GymTrackerApp):**
- `AuthViewModel` — `.environment(authViewModel)`
- `WorkoutViewModel` — `.environment(workoutViewModel)` (shared between WorkoutView and HistoryView)
- `Binding<AppTab>` — `.environment(\.selectedTab, $selectedTab)` via custom EnvironmentKey

**Tab switching**: use `@Environment(\.selectedTab) private var selectedTab` then `selectedTab.wrappedValue = .workout`.

SwiftUI ↔ React mental model:
- `@State` ≈ `useState`
- `@Observable` + `@State var vm = MyViewModel()` ≈ `useContext` + a store
- `@Binding` ≈ passing a setter as a prop
- `.task { }` ≈ `useEffect([], [])`

---

## Firestore Data Model

```
systemExercises/{id}
  name: String
  category: String          // "chest" | "back" | "legs" | "shoulders" | "arms" | "core"
  equipmentType: String     // "barbell" | "dumbbell" | "machine" | "cable" | "bodyweight"

users/{userId}/
  profile/settings          // single doc (fixed id "settings"): monthlyGoal (Int, default 20)
  gyms/{gymId}/             // name, location, createdAt
  exerciseTemplates/{id}/   // custom exercises: same schema as systemExercises + isCustom: true
  equipmentVariants/{id}/   // label, gymId, exerciseTemplateId, weightOffset (Float?)
  workoutSessions/{sessionId}/
    gymId, gymName, startedAt, endedAt, notes
    exercises: [WorkoutExercise]   // embedded array (not subcollection)
      sets: [ExerciseSet]          // embedded array
  bodyWeightLogs/{logId}/   // date, weightLbs, notes?
```

**Note**: WorkoutSession stores exercises and sets as embedded arrays in a single Firestore document, not as subcollections. This is simpler for reads but means a single workout document can grow large with many exercises/sets.

**Equipment variant logic (Phase 4 — not yet built):**
- A `set` optionally references a `variantId`
- `weightOffset` on a variant: e.g., machine reads 5lbs heavier than actual → offset = -5
- Progress charts use `displayWeight = rawWeight + offset` to normalize across variants

---

## Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /systemExercises/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## Pre-built Exercise Library

Seeded to `systemExercises` via `FirestoreService.seedSystemExercises()`. Diffs against existing exercise names and batch-inserts only what's missing — safe to re-run any time new exercises are added to the source array, won't duplicate or wipe existing entries. Source array in `FirestoreService.swift` is grouped by muscle group (matches the order below), not by equipment type.

**Chest (14):** Bench Press, Incline Bench Press, Decline Bench Press, DB Bench Press, DB Incline Bench Press, DB Fly, Smith Machine Bench Press, Smith Machine Incline Bench Press, Machine Chest Press, Chest Fly Machine, Cable Fly, Cable Crossover, Push-up, Dip

**Back (16):** Deadlift, Barbell Row, Pendlay Row, Barbell Shrug, DB Row, DB Shrug, T-Bar Row, Seated Row Machine, Chest-Supported Row, Lat Pulldown, Close-Grip Lat Pulldown, Reverse-Grip Lat Pulldown, Cable Row – Wide Grip, Cable Row – Close Grip, Pull-up, Chin-up

**Legs (19):** Squat, Front Squat, Romanian Deadlift, Sumo Deadlift, Hip Thrust, Goblet Squat, Bulgarian Split Squat, Walking Lunge, Reverse Lunge, Step-Up, Leg Press, Hack Squat, Leg Curl, Leg Extension, Standing Calf Raise, Seated Calf Raise, Hip Abductor Machine, Hip Adductor Machine, Glute Bridge

**Shoulders (6):** Overhead Press, DB Shoulder Press, Lateral Raise, Machine Shoulder Press, Cable Lateral Raise, Face Pull

**Arms (14):** EZ Bar Curl, Preacher Curl, Reverse Curl, Close-Grip Bench Press, Skullcrusher, DB Curl, Hammer Curl, Concentration Curl, Tricep Kickback, Overhead Tricep Extension, Cable Curl, Tricep Pushdown, Cable Overhead Tricep Extension, Bench Dip

**Core (12):** Russian Twist, Cable Woodchopper, Plank, Side Plank, Sit-up, Crunch, Bicycle Crunch, Hanging Leg Raise, Ab Wheel Rollout, Mountain Climbers, Dead Bug, V-Up

**Naming convention for new entries:** barbell = plain name, dumbbell = `DB ` prefix, cable = `Cable ` prefix, machine/Smith Machine = `Machine `/`Smith Machine ` prefix, bodyweight = plain name. Smith Machine exercises use `equipmentType: "machine"` (no separate enum case) — true free-weight-vs-Smith-Machine offset tracking is Phase 4's job, not this library.

---

## Design System

**Colors (dark theme):**
```swift
// Defined in Extensions/Color+Theme.swift
appBackground:       #121212   // dark background
appSurface:          #171717   // card backgrounds
appPrimary:          #A8313F   // maroon/red accent
appAccent:           #D4A23C   // gold — PRs, streaks, achievements
appText:             #EDEDED   // primary text (light)
appMuted:            #7A7A7A   // secondary/label text
appBorder:           #222222   // dividers and borders
appDestructive:      #C0392B   // destructive actions
appCardMaroon:       #7A1F2B   // CTA card background
appCardMaroonLight:  #F0C2C7   // light text on maroon cards
```

**Shape language:**
- Cards: `cornerRadius: 12–16` — rounded, modern feel
- Buttons: full-width, rounded corners (12), uppercase labels
- Input fields: rounded with 1pt `appBorder` stroke
- Section headers: uppercase, letter-spaced, `appMuted` color
- Numbers (weight, reps, streaks): large, medium weight, `monospacedDigit()`
- Decorative: subtle `0.04` opacity white circles on maroon cards

**Typography:** SF Pro (SwiftUI system font). `.fontWeight(.medium)` to `.heavy` for headings and numbers. Never gradients.

---

## App Screens & Tab Structure

```
TabView: Home | Workout | History | Progress | Profile
```

- **Home**: live dashboard — date, greeting, last session CTA card, streak, PRs this month, monthly goal progress bar, week activity blocks, recent workouts list
- **Workout** (active session): gym picker → exercise list with set rows, add exercise sheet, count-up rest timer overlay, finish confirmation
- **History**: past sessions list (expandable), repeat workout button
- **Progress**: strength line chart (exercise picker), weekly volume bar chart (last 12 weeks), body weight log + line chart
- **Profile**: gym management (add/delete), exercise library sheet, sign out

**Exercises** tab was removed. Exercise library is accessible from Profile → "Exercise Library" sheet.

---

## Key Component Patterns

### NumericField
Custom component using `String` internally to allow field clearing. Standard `TextField(.number)` never allows an empty state.
```swift
NumericField(placeholder: "0", value: $binding)
NumericField(placeholder: "0", value: $binding, allowDecimal: false) // for reps
```

### Bounds-checked Bindings in WorkoutView
All `Binding` closures for set weight/reps include index guards to prevent crash after set deletion:
```swift
get: {
    guard let session = workoutVM.currentSession,
          exerciseIndex < session.exercises.count,
          setIndex < session.exercises[exerciseIndex].sets.count
    else { return 0 }
    return session.exercises[exerciseIndex].sets[setIndex].weight
}
```

### Rest Timer
Count-up timer in `WorkoutViewModel` using `Task { @MainActor }` with `Task.sleep(for: .seconds(1))`. Starts automatically when a set is marked complete.

### Tab Switching
Custom `EnvironmentKey` holding `Binding<AppTab>`. Inject at root, read with `@Environment(\.selectedTab)`, switch with `selectedTab.wrappedValue = .history`.

### Init Order (Firebase)
`FirebaseApp.configure()` must run before any `AuthViewModel` init. Pattern:
```swift
init() {
    FirebaseApp.configure()
    _authViewModel = State(initialValue: AuthViewModel())
}
```

---

## Build Phases

- [x] Phase 0: Install Xcode, set up Apple ID in Xcode
- [x] Phase 1: Xcode project + Firebase setup + Auth screens + TabView shell
- [x] Phase 2: Core logging — gyms, exercises, active workout, history, repeat workout, rest timer
- [x] Phase 3: Progress charts (Swift Charts) + body weight tracking + HomeView live data
- [x] Rest timer + workout Live Activity (Lock Screen + Dynamic Island) — not one of the numbered phases below, built ahead of them as an agreed-upon interim feature
- [ ] Phase 4: Equipment variants + weight offset normalization — deprioritized by user, don't default to suggesting this next
- [ ] Phase 5: Polish — set notes, unit toggle (lbs/kg), offline edge cases
- [ ] Phase 6: WidgetKit homescreen widget (App Group + shared UserDefaults)

---

## Key Decisions

- **Firebase over Supabase**: user preference + free tier requirement
- **Swift/SwiftUI over React Native**: user wants to learn Swift as a new language
- **iOS 17+ APIs, 26.5 deployment target**: device is an iPhone 17 Pro; target enables `@Observable`, Swift Charts, all modern APIs
- **MVVM not TCA/Composable Architecture**: lower learning curve for someone new to Swift
- **No CoreData / SwiftData**: Firestore's built-in offline persistence handles caching; avoid dual data layer complexity
- **Exercises moved from tab to Profile sheet**: keeps tab count at 5 (iOS standard) matching the Home | Workout | History | Progress | Profile spec
- **Embedded arrays not subcollections**: WorkoutSession stores exercises/sets as arrays in one document — simpler reads, fine for personal-scale data
- **Widget deferred to Phase 6**: WidgetKit + Firestore data handoff design depends on understanding the full session data flow first
