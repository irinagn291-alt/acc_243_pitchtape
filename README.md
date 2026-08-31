# Pitchtape

Sideline sheet for coaches and parents. Tap Goal, Foul, Card, or Sub onto a live clock. The whistle parks that period and opens the next empty tape. Local only. Not a betting product.

## Architecture

Period is a closed ADT (`Running` | `Parked`). A Call is appended only to the open Running tape. The match is the fold of those Calls onto clock and score. `WhistleSplit.parkTape` writes a `PeriodMark`, seals the period, and opens the next empty Running tape.

Clock is never a stored tick: `accumulated + now − runStartedAt`, evaluated when `TimelineView` invalidates. Views call park, commit, and undo through `BoothDesk`. They never hold a second phase enum. Persistence is one SwiftData `ModelContainer` of Period and Call, reached only through `TapeBooth`.

This pattern fits a live touchline sheet: the open tape is the only write target, and the whistle is the only way a period becomes history.

## Unique feature

Whistle-split tape. A tap always lands on the open period. Undo peels only the last Call on that period. Insights export parked tapes as PDF. Matches store fixtures, not a post-game form.

## Art

Style: isometric 3D illustration. Base prompt:

```
Isometric 3D illustration, faceted geometric solids, three-quarter elevation, even studio light, sideline console and whistle as hard-edged objects, measured and quiet, no photography, no glassmorphism, no lettering, no specified pigments
```

| Image set | Prompt |
| --- | --- |
| `ptp_AppIcon` | Isometric 3D emblem of a centred whistle over a take tape, filling the canvas, no lettering, no rounded mask |
| `ptp_Splash` | Vertical isometric 3D console loft with a quiet centre band for a wordmark |
| `ptp_Onboarding1` | Isometric 3D empty ON-AIR console waiting for the first tap |
| `ptp_Onboarding2` | Isometric 3D finger tapping a Call onto a running take tape |
| `ptp_Onboarding3` | Isometric 3D whistle parking a period beside a sealed tape |
| `ptp_EmptyHome` | Isometric 3D empty console, inviting the first clock start |
| `ptp_EmptyList` | Isometric 3D empty tape rack with no parked periods |
| `ptp_CardBackdrop` | Low-contrast isometric 3D console plane for sitting behind type |
| `ptp_ControlFace` | Isometric 3D face of a single call-pad key |
| `ptp_TwistHero` | Isometric 3D whistle splitting a tape into a parked reel and an open reel |
| `ptp_SuccessMark` | Isometric 3D confirmation of a written Call on the open tape |
| `ptp_HeaderDecor` | Wide isometric 3D band of console bevel and tape edge |

## How this differs

First `sideline_stats` in the portfolio. Home is a live ON-AIR console, not Occupath token blocks, Goldnock arrow taps, or Diapason bellows. The verb is tap-the-call. The whistle seals a period.

## Build

```bash
cd Pitchtape
xcodegen generate
xcodebuild -scheme Pitchtape -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```
