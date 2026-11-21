---
inclusion: always
---

# Product: Hauntcast Weather

Hauntcast Weather is a web app that warns people about natural hazards at their current location
(heavy rain, debris flows known in Peru as *huaycos*, floods, frost, heat waves, earthquakes, hurricanes and more),
explains how serious the situation is with a 0–4 **Skull Scale**, and tells them what to do before, during and after.

It is built for the **Kiroween 2026** hackathon, **Costume Contest** category. In this category the spooky design must
make the app *work better*, not just decorate it: the Halloween layer exists to make risk easier to understand and remember.

- Team: Gabriel and Luciana. Talk to the team in **Spanish**.
- Code, identifiers, code comments and commit messages are in **English**.
- User-facing text is bilingual: **English and Spanish** (judges use English).
- The full plan (modules, owners, schedule) is in `README.md` (Spanish). The hazard list and the Skull Scale are in
  `hazards.md`.

## Core user flow

1. The user opens the app and allows location access, or searches for a city.
2. The app follows the location in real time while it is open and asks the backend for the risk at that point.
3. The main screen shows the overall level (0–4), the active alerts and a "What to do now" block.
4. Tapping an alert shows its description, its source and time, and recommendations for before, during and after.
5. With no alerts, the app shows a calm state and the upcoming forecast.
6. Optional: with an account, users save places and get notified when a saved place's level rises.

## Product principles (must hold everywhere)

- **Official vs estimated.** Every alert is either `official` (issued by a national weather service such as SENAMHI or
  NWS) or `estimated` (computed by Hauntcast from a forecast and thresholds). The UI always says which one it is,
  and always shows the source and the time of the data.
- **Never fake calm.** If a source fails or returns invalid data, say so ("source unavailable") and fall back to another
  source. Never show level 0 just because data is missing.
- **Actions first.** At levels 3 and 4, the "What to do now" block appears before any animation.
- **Official advice first.** When an official alert carries its own recommendation (SENAMHI `RECOMENDAC`), show it first.
  Our own recommendations must cite an official source (INDECI, CENEPRED, Ready.gov/FEMA, CENAPRED).
- **Works without an account.** Accounts are optional and only add saved places and background notifications.
- **Respectful horror.** Skeletons and ghosts explain and warn; they never mock real victims. No jokes at levels 3 and 4.
  A "calm mode" turns off animations, and `prefers-reduced-motion` is always respected.
- **Accessible.** The risk level is always shown with color, icon and text together, never color alone.

## Phases

- **Phase 1 · Make it work:** the complete app with a simple, clean UI and no Halloween styling yet (modules M0–M5).
  The UI must already isolate `<RiskBadge level>` and `<HazardScene hazard level>` so Phase 2 replaces components
  instead of rewriting screens.
- **Phase 2 · Make it haunt:** the Halloween layer (Skull Scale visuals, one animation per hazard, graveyard ambience
  that reacts to the real weather), designed by both team members together (module M6).
- Then optional M7 (accounts and background notifications) and M8 (quality and submission).

## Out of scope

- Admin panel or admin roles. The Supabase dashboard plus versioned SQL seeds in `supabase/` act as the admin.
- Chat, social features or user-generated content.
- Paid data sources.
