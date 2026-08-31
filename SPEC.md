# Pitchtape — Build Specification

> Portfolio app 60, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Tap live match events from the touchline.

| Field | Value |
| --- | --- |
| Product name | Pitchtape |
| Bundle identifier | `com.zalupik.pupiuk` |
| Domain | https://zalupik-pupiuk.pro |
| Contact URL | https://zalupik-pupiuk.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `ptp_` |
| User-Agent | `Pitchtape/1.0 (iOS; +https://zalupik-pupiuk.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Pitchtape -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A sideline keeper taps a live match event onto the running clock.

### 2.1 User flow

1. Tap Goal on the live console.
2. Tap Foul, a card, or Sub onto the same open period.
3. Blow the whistle to park the period and open the next tape.
4. Open Matches from the drawer to start or resume a fixture.
5. Open Insights from the drawer and export the parked tapes as PDF.

### 2.2 Essential behaviour

- ON-AIR console is home: clock and score on top, call pad, live tape
- Clock equals accumulated plus now minus runStartedAt, no tick drift
- One-tap Goal, Foul, card, and Sub write a Call on the open period
- Whistle parks the period and opens the next empty tape
- Undo peels the last Call on the open period only
- Insights export parked tapes as PDF
- Sport templates; local only; no odds and no money

---

## 3. Uniqueness assignment for Pitchtape

| Axis | Assigned value |
| --- | --- |
| Architecture | **Period ADT fold (Running | Parked); the match is a fold over Calls; whistle writes a PeriodMark and opens the next Running tape** |
| UI approach | **SwiftUI Canvas TimelineView · take tape** |
| Naming convention | **Match-tape lexicon** |
| File organization | **By tape role (Clock, Period, Call, Whistle, Tape)** |
| Dependency strategy | **None (zero external dependencies)** |
| Design direction | **Steel blue console** |
| Typography | **DIN Alternate** |
| Navigation pattern | **Console-locked chrome (the ON-AIR board never leaves; Matches, Insights and Settings open from a leading drawer)** |
| AI art style | **Isometric 3D illustration** |
| Functional twist | **Whistle-split tape (whistle parks the period; taps land on the open tape)** |
| Persistence | **SwiftData with a Period entity and a Call entity in one ModelContainer** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — sideline_stats

**Core** — A sideline keeper taps a live match event onto the running clock.

**Audience** — Coaches and parents keeping a sheet on the touchline, not betting.

**User flow**

1. Tap Goal on the live console.
2. Tap Foul, a card, or Sub onto the same open period.
3. Blow the whistle to park the period and open the next tape.
4. Open Matches from the drawer to start or resume a fixture.
5. Open Insights from the drawer and export the parked tapes as PDF.

**Essential features**

- ON-AIR console is home: clock and score on top, call pad, live tape
- Clock equals accumulated plus now minus runStartedAt, no tick drift
- One-tap Goal, Foul, card, and Sub write a Call on the open period
- Whistle parks the period and opens the next empty tape
- Undo peels the last Call on the open period only
- Insights export parked tapes as PDF
- Sport templates; local only; no odds and no money

**Twist** — Whistle-split tape. Home is the ON-AIR console. A tap writes a Call at clock equals accumulated plus now minus runStartedAt. The whistle parks that period and opens the next empty tape. A tap always lands on the open period. Undo peels the last Call on the open period. Insights export parked tapes as PDF. Home verb: tap-the-call, not fill-a-form. Matches stores fixtures; Insights stores parked tapes, not a post-game sheet.

**Why this is not a repeat** — First sideline_stats in the portfolio. Home is a live console, not Occupath’s token blocks, not Goldnock’s arrow taps, and not a lock-before-kickoff league. The verb is tap-the-call; the whistle seals a period. Clock math is the family invariant. Seeded Goal is live. No food, slots, or barcode. Architecture, lexicon, organization, navigation, and twist are new. Closed axes are catalog leftovers only.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Landscape ON-AIR console: home | clock/score | away + live tape.
- Invariant: Clock = accumulated + now−runStartedAt (no tick drift). One-tap Goal/Foul/card/Sub. Undo last. PDF after.
- Never: No Reflex Call mini-game. Not a betting product.
- Desk `group_ellipse`: Covariance ellipse; flyer if dist/semiMajor>2.5; sightCorrection=(−cx,−cy). Keep x,y.

### 3.1 Architecture contract

Period is a closed ADT whose only cases are Running and Parked. A Call is appended only to the open Running tape; the match is the fold of those Calls onto clock and score. Whistle writes a PeriodMark, flips that Period to Parked, and opens the next empty Running tape. Clock is never a stored tick: it is accumulated plus now minus runStartedAt, evaluated when TimelineView invalidates. Views call park, commit, and undo; they never keep a second phase enum. One unit test proves the clock formula, one-tap Call write, undo of the last Call on the open period only, and whistle park-and-open, without constructing a View.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

SwiftUI Canvas plus TimelineView is confined to the take tape on Console — the only custom-drawn surface. TimelineView drives the live clock as accumulated plus context.date minus runStartedAt; Canvas draws Calls in take order on that tape. Goal, Foul, card, Sub, Undo, and Whistle are bordered-prominent SwiftUI controls at 10pt radius with hairline-plus-fill chrome, each at least 44pt with contentShape on the fill. Matches, Insights, and Settings are stock List, Form, Button, and drawer scenes. Empty Matches and empty Insights are full-page empty states with generated art, one headline, one line, and one full-width CTA. The console is a landscape-feeling board in the portrait frame: home | clock/score | away on top, call pad, then the tape using remaining height; iPad uses the width. Do not reuse Occupath token blocks, Goldnock arrow taps, or Diapason bellows. The ui axis value is never a section title.

### 3.3 Naming contract

Convention: Match-tape lexicon.

Examples to follow: `TapeClock`, `OpenPeriod`, `CallMark`, `parkTape(_:)`

### 3.4 Dependency contract

None. project.yml has no packages key. Do not add SPM or a bundled font — DIN Alternate is a system face. PDF export uses UIGraphicsPDFRenderer. The leftover VisionKit DataScannerViewController scanner and cgi search pl page 24 endpoint are unused; do not link VisionKit or AVFoundation for capture and do not call a remote catalog.

### 3.5 Navigation contract

The ON-AIR board on Console stays mounted; it never pops or leaves for a tab. Matches, Insights, and Settings open from a leading drawer as separate scenes. No TabView. Read ProcessInfo.processInfo.arguments once after onboarding: ReviewScreen today stays on Console, log opens Insights, goals opens Settings. One haptic on a successful Call or whistle, none on drawer presentation.

### 3.6 Screen composition contract

Drawer with separate scenes. Physical screens: Console (ON-AIR board; ReviewScreen today), Matches (fixture drawer scene), Insights (parked tapes and PDF; ReviewScreen log), Settings (drawer scene; ReviewScreen goals; contact URL, reset, re-run onboarding). Onboarding is a one-shot cover that writes defaults. Empty Console copy: No match yet. Start the clock. Empty Matches and empty Insights are full pages. Seed behind ptp.demo.v1 on Simulator only, skip onboarding after seed, enable Goal on a running tape, and fill Insights with several parked tapes. No Today, Scan, Search, or Goals screens. No Reflex Call mini-game. Not a betting product.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By tape role (Clock, Period, Call, Whistle, Tape)**

```
Pitchtape/
  Clock/ Period/ Call/ Whistle/ Tape/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Matches
A first-class screen for **Matches**. Must render empty, populated and error states.

### 5.3 Insights
A first-class screen for **Insights**. Must render empty, populated and error states.

### 5.4 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.5 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.6 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Match** — named per this app's convention.
- **Event** — named per this app's convention.
- **Player** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Steel blue console**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#141C1F` | Screen background |
| `surface` | `#1C272B` | Cards, rows, sheets |
| `ink` | `#EDF1F2` | Primary text and icons |
| `accent` | `#55C2E7` | Primary action, key figure, progress fill |
| `muted` | `#91A5AC` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **DIN Alternate**

DIN Alternate only, reached through one type-scale accessor of at most six Dynamic Type steps. Use UIFont DINAlternate-Bold mapped to text styles; never Font.custom with a fixed size. Clock seconds and scores go through NumberFormatter. Hierarchy is step, not a second family.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **10pt** for cards, sheets and primary surfaces; **8pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **hairline+fill** — a 1pt hairline border plus a flat fill tint, reused everywhere a surface sits above another.

Primary control: **bordered prominent** — primary actions use `.buttonStyle(.borderedProminent)` or an equivalent filled, bordered shape.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **SwiftUI Canvas TimelineView · take tape**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **SwiftUI Canvas TimelineView · take tape** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **SwiftData with a Period entity and a Call entity in one ModelContainer**

Exactly one ModelContainer, created once at launch, with an explicit Schema of Period and Call, a VersionedSchema from version 1, and a SchemaMigrationPlan. Period stores Running or Parked, accumulated, runStartedAt, home and away names, and an optional PeriodMark. Call stores kind (Goal, Foul, card, Sub), clockAt, and an inverse cascade relationship to Period. Clock and score are derived at display and are never stored ticks. The leftover Julian day number daykey is unused; fixture dates use Calendar.current.startOfDay. Tests use ModelConfiguration(isStoredInMemoryOnly: true). resetAllData wipes both entities.

This app uses **SwiftData**. SwiftData has several sharp edges that produce
runtime crashes and silent data loss; all of the following are mandatory.

**Container**

- Exactly one `ModelContainer`, created once at app start and injected. Never
  construct a container inside a view body or a computed property.
- Declare an explicit `Schema` listing every `@Model` type.
- Define a `VersionedSchema` and a `SchemaMigrationPlan` from version 1, even
  though there is nothing to migrate yet. Retrofitting migration later is the
  single most expensive SwiftData mistake.
- Handle container creation failure with a recoverable path, not `try!`.

**Modelling**

- Every relationship must declare its inverse with `@Relationship(inverse:)`.
  A missing inverse is the most common SwiftData bug: it produces duplicated
  objects and orphaned rows that only appear after a relaunch.
- Every to-many relationship must declare a delete rule, normally
  `@Relationship(deleteRule: .cascade)` for owned children.
- Use `@Attribute(.unique)` on the product barcode. Understand that this makes
  inserts behave as upserts.
- Do not store derived values (day totals, remaining budget). Compute them.
- Store the day as a normalised `startOfDay` value if you query by day, and
  index it. Querying by a raw timestamp will silently miss rows.

**Threading**

- `ModelContext` is not `Sendable`. Never capture one in a `Task` that hops
  actors.
- Background work uses `@ModelActor`. Inside it, fetch by `PersistentIdentifier`
  rather than passing model objects across the boundary.
- Models themselves are not `Sendable`. Map to plain structs before handing data
  to the UI layer or across an actor boundary.

**Queries**

- `@Query` belongs in views only, with an explicit and stable `sort:`.
- `#Predicate` supports a restricted subset of Swift. Keep predicates to simple
  comparisons on stored properties; do the rest in memory. Calling an arbitrary
  Swift function inside a predicate compiles but traps at runtime.
- Do not build a predicate that captures a non-`Sendable` value.

**Saving**

- Call `context.save()` explicitly after a batch of mutations rather than
  relying on autosave, so the moment of persistence is deterministic.
- Delete through the context, then save, then let the UI update from the query.

**Testing**

- Tests use `ModelConfiguration(isStoredInMemoryOnly: true)`.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Pitchtape/1.0 (iOS; +https://zalupik-pupiuk.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as medical advice. It is a personal food log.
- Nutrition data is credited to Open Food Facts, a public database.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.sports`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.sports
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Whistle-split tape (whistle parks the period; taps land on the open tape)

Whistle-split tape is the only home verb: a tap always writes a Call on the open tape, and the whistle parks that period. The parked tape is sealed; the next empty Running tape is already open, so a tap cannot land on a parked period. Undo peels only the last Call on the open period. Clock at each Call is accumulated plus now minus runStartedAt, so there is no tick drift. Insights export parked tapes as PDF; Matches stores fixtures, not a post-game form. Seeded home keeps Goal live; a blocked whistle is a unit-test fixture.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Isometric 3D illustration**


Base prompt, reused and extended for every asset:

```
Isometric 3D illustration, faceted geometric solids, three-quarter elevation, even studio light, sideline console and whistle as hard-edged objects, measured and quiet, no photography, no glassmorphism, no lettering, no specified pigments
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `ptp_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `ptp_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `ptp_Splash` | 1290x2796 | allowed | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `ptp_Onboarding1` | 1024x1536 | allowed | Onboarding page 1 illustration: what the app is for. |
| 4 | `ptp_Onboarding2` | 1024x1536 | allowed | Onboarding page 2 illustration: the main verb. |
| 5 | `ptp_Onboarding3` | 1024x1536 | allowed | Onboarding page 3 illustration: why they stay. |
| 6 | `ptp_EmptyHome` | 1024x1024 | allowed | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `ptp_EmptyList` | 1024x1024 | allowed | Empty state: a secondary list has no rows. |
| 8 | `ptp_CardBackdrop` | 1200x800 | allowed | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `ptp_ControlFace` | 512x512 | allowed | Custom control artwork used for the primary interactive element. |
| 10 | `ptp_TwistHero` | 1024x1024 | allowed | Hero art for the 'Whistle-split tape (whistle parks the period; taps land on the open tape)' feature screen. |
| 11 | `ptp_SuccessMark` | 512x512 | allowed | Shown briefly when the primary action succeeds. |
| 12 | `ptp_HeaderDecor` | 1200x600 | allowed | Decorative header accent on the main screen. |

### Prompt per asset

**`ptp_AppIcon`** — 1024x1024

```
Isometric 3D emblem of a centred whistle over a take tape, filling the canvas, no lettering, no rounded mask
```

**`ptp_Splash`** — 1290x2796

```
Vertical isometric 3D console loft with a quiet centre band for a wordmark
```

**`ptp_Onboarding1`** — 1024x1536

```
Isometric 3D empty ON-AIR console waiting for the first tap
```

**`ptp_Onboarding2`** — 1024x1536

```
Isometric 3D finger tapping a Call onto a running take tape
```

**`ptp_Onboarding3`** — 1024x1536

```
Isometric 3D whistle parking a period beside a sealed tape
```

**`ptp_EmptyHome`** — 1024x1024

```
Isometric 3D empty console, inviting the first clock start
```

**`ptp_EmptyList`** — 1024x1024

```
Isometric 3D empty tape rack with no parked periods
```

**`ptp_CardBackdrop`** — 1200x800

```
Low-contrast isometric 3D console plane for sitting behind type
```

**`ptp_ControlFace`** — 512x512

```
Isometric 3D face of a single call-pad key
```

**`ptp_TwistHero`** — 1024x1024

```
Isometric 3D whistle splitting a tape into a parked reel and an open reel
```

**`ptp_SuccessMark`** — 512x512

```
Isometric 3D confirmation of a written Call on the open tape
```

**`ptp_HeaderDecor`** — 1200x600

```
Wide isometric 3D band of console bevel and tape edge
```


### 13.3 Asset rules

- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, background textures, and anything else that needs a guaranteed transparent region or a guaranteed seamless join are drawn in SwiftUI via `Path` or `Shape`. The image generator is not used for these elements: it guarantees neither an alpha channel nor a seamless tile.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`ptp.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `PitchtapeTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Parse `ProcessInfo.processInfo.arguments` once after onboarding. 
   `-ReviewScreen today|log|goals` switches the running app's live navigation.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Pitchtape -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Period ADT fold (Running | Parked); the match is a fold over Calls; whistle writes a PeriodMark and opens the next Running tape** with no leakage across layers.
- [ ] UI approach matches **SwiftUI Canvas TimelineView · take tape**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Console-locked chrome (the ON-AIR board never leaves; Matches, Insights and Settings open from a leading drawer)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **DIN Alternate** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Pitchtape
xcodegen generate
xcodebuild -scheme Pitchtape -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Pitchtape -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
