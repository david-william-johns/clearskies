# Tile Expansion Bug — Persistent Issue Log

**File:** `lib/features/forecast/day_forecast_tile.dart`
**Status:** RESOLVED (2026-03-15, Session 8)
**First reported:** 2026-03-15 (Session 7)

---

## Bug Description

Clicking a `DayForecastTile` in the forecast list does not expand the tile to show the detailed view. The tile header (collapsed state) is visible and clickable, but no expansion occurs.

### Symptom Evolution

**Phase 1 (initial report):** Clicking anywhere on a tile produced no response at all — not even the toggle arrow changed. `onTap` was never firing.

**Phase 2 (current state, after partial fixes):** The toggle arrow **does** rotate (up → down or down → up) when clicked, proving that `_toggle()` fires and `setState(() => _expanded = !_expanded)` executes correctly. However, the tile body still does not expand — no visible height change, no content appears.

This means:
- The `GestureDetector.onTap` IS now wired correctly ✓
- The state IS toggling (`_expanded` flips) ✓
- The animated expansion widget is NOT reflecting the state change ✗

---

## Relevant Code Structure

**File:** `lib/features/forecast/day_forecast_tile.dart`

```
DayForecastTile (StatefulWidget)
  └── _DayForecastTileState
        ├── _expanded: bool (initState from widget.initiallyExpanded, default false)
        ├── _toggle() => setState(() => _expanded = !_expanded)
        └── build()
              └── GestureDetector(onTap: _toggle, behavior: HitTestBehavior.opaque)
                    └── AnimatedContainer(duration: 250ms)
                          └── Column
                                ├── _CollapsedHeader(expanded: _expanded)  ← arrow rotates ✓
                                └── [EXPANSION WIDGET HERE] ← broken ✗

_ExpandedBody (StatefulWidget — converted from StatelessWidget in commit 1d379e9)
  └── _ExpandedBodyState
        ├── _selectedSlotIndex: int = 0
        └── build()
              └── Column
                    ├── Divider
                    ├── _DarkWindowSummary
                    ├── IntrinsicHeight(Row([HourlyConditionsGrid, SizedBox(w:210, FlutterMap)]))
                    ├── _CloudCoverChart (height: 60px fixed)
                    └── _MoonInfo
```

**Key complexity:** `_ExpandedBody` contains `IntrinsicHeight` wrapping a `Row` that includes `FlutterMap` from the `flutter_map` package. `FlutterMap` uses `LayoutBuilder` internally and **may not support intrinsic height measurement**, which could cause the expanded body to report 0 height to its parent layout widget.

---

## Forecast List Context

`DayForecastTile`s are rendered inside a `ListView` in `forecast_screen.dart`:

```dart
ScrollConfiguration(
  behavior: ScrollConfiguration.of(context).copyWith(
    dragDevices: {PointerDeviceKind.touch},
  ),
  child: ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      _LegendBar(),
      ...forecasts.map((f) => DayForecastTile(
            key: ValueKey(f.date),
            forecast: f,
            location: location,
            initiallyExpanded: false,
          )),
      _Footer(),
    ],
  ),
),
```

---

## All Fix Attempts (Chronological)

### Attempt 1 — HitTestBehavior.opaque
**Hypothesis:** `GestureDetector` with default `deferToChild` was not registering taps on empty space in the tile header's `Row`/`Column` layout.
**Change:** Added `behavior: HitTestBehavior.opaque` to `GestureDetector` in `_DayForecastTileState.build()`.
**Result:** FAILED — tiles still did not respond to clicks at all.

---

### Attempt 2 — Remove flutter_animate wrapper from tile list
**Hypothesis:** `.animate().fadeIn().slideY()` wrapper around each `DayForecastTile` in `forecast_screen.dart` was interfering with state management.
**Change:** Removed `flutter_animate` wrappers from the `ListView` children in `forecast_screen.dart`.
**Result:** FAILED — tiles still did not respond.

---

### Attempt 3 — ScrollConfiguration mouse drag fix (FIXED PHASE 1)
**Hypothesis:** Flutter Windows default `ScrollBehavior` includes `PointerDeviceKind.mouse` in `dragDevices`, causing the `ListView` scroll gesture recognizer to win the gesture arena over every `GestureDetector.onTap` inside the list. Mouse clicks were being consumed as scroll drag attempts.
**Change:** Wrapped `ListView` in `ScrollConfiguration(behavior: ...copyWith(dragDevices: {PointerDeviceKind.touch}))`. Added `import 'package:flutter/gestures.dart'`.
**Result:** PARTIAL SUCCESS — tap now registers (arrow rotates), but expansion still doesn't occur. Phase 1 resolved, Phase 2 begins.

---

### Attempt 4 — Remove .animate().fadeIn() from AnimatedCrossFade.secondChild
**Hypothesis:** `_ExpandedBody(...).animate().fadeIn()` on the `secondChild` of `AnimatedCrossFade` was interfering with height measurement. `AnimatedCrossFade` keeps both children in the tree and measures `secondChild`'s height while it's "hidden". The `flutter_animate` wrapper may report 0 height during initial measurement, causing `AnimatedCrossFade` to store 0 as the target height and animate 0→0.
**Change:** Removed `.animate().fadeIn(duration: 300.ms, curve: Curves.easeIn)` from `secondChild`. Removed `import 'package:flutter_animate/flutter_animate.dart'` (now unused).
**Result:** FAILED — tiles still do not expand.

---

### Session 8 Observations (2026-03-15)

Screenshots CelEvents02/03/04 provided:
- **CelEvents02:** Initial state — all tiles collapsed, arrow ▼ on each, TODAY tile highlighted.
- **CelEvents03:** TODAY clicked — arrow rotated to ▲, tile height **identical** to collapsed state. Zero visual expansion.
- **CelEvents04:** MON clicked — arrow rotated to ▲ on MON, TODAY arrow still ▲ (state persists). Neither tile expanded. The "TODAY tile not illuminated on MON" observation is expected — the blue highlight is `isToday` (date-based), not expansion-based.

Desktop shortcut confirmed at `D:\ClaudeCode_Projects\ClearSkies\ClearSkies.lnk`, pointing to:
`D:\ClaudeCode_Projects\ClearSkies\clearskies\build\windows\x64\runner\Debug\clearskies.exe`
This is correct. The shortcut is NOT the issue.

**Key deduction from screenshots:** Tile height is pixel-identical before and after click in all cases. `_ExpandedBody` is rendering at exactly 0×0 height — not partially, but completely zero.

---

### Attempt 5 — Replace AnimatedCrossFade with AnimatedSize + ClipRect
**Hypothesis:** `AnimatedCrossFade` keeps both children in the tree simultaneously. `_ExpandedBody` contains `IntrinsicHeight(Row([..., FlutterMap]))`. `FlutterMap` (which uses `LayoutBuilder`) likely does not support intrinsic height measurement, causing the hidden `secondChild` to be rendered with 0 height. `AnimatedCrossFade`'s size transition therefore animates from 0 → 0. `AnimatedSize` only holds ONE child at a time, avoiding the hidden-layout problem entirely.
**Change:** Replaced:
```dart
AnimatedCrossFade(
  duration: const Duration(milliseconds: 350),
  sizeCurve: Curves.easeInOutCubic,
  crossFadeState: _expanded
      ? CrossFadeState.showSecond
      : CrossFadeState.showFirst,
  firstChild: const SizedBox.shrink(),
  secondChild: _ExpandedBody(forecast: f, location: widget.location),
),
```
With:
```dart
ClipRect(
  child: AnimatedSize(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOutCubic,
    child: _expanded
        ? _ExpandedBody(forecast: f, location: widget.location)
        : const SizedBox.shrink(),
  ),
),
```
**Result:** FAILED — tiles still do not expand. (Status as of last test.)

---

## Current Code State (after all attempts)

Lines 50–91 of `day_forecast_tile.dart`:

```dart
return GestureDetector(
  onTap: _toggle,
  behavior: HitTestBehavior.opaque,
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: isToday
          ? AppColors.surfaceElevated.withAlpha(205)
          : AppColors.surface.withAlpha(190),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isToday
            ? AppColors.primary.withAlpha(80)
            : AppColors.surfaceBorder,
        width: isToday ? 1.5 : 1,
      ),
    ),
    child: Column(
      children: [
        _CollapsedHeader(
            forecast: f,
            score: score,
            scoreColor: scoreColor,
            isToday: isToday,
            expanded: _expanded),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            child: _expanded
                ? _ExpandedBody(
                    forecast: f, location: widget.location)
                : const SizedBox.shrink(),
          ),
        ),
      ],
    ),
  ),
);
```

---

### Attempt 6 — Replace IntrinsicHeight with SizedBox(height: 220) ← CURRENT FIX

**Hypothesis:** Root cause identified via code analysis. `_ExpandedBodyState.build()` uses `IntrinsicHeight` wrapping a `Row` that contains `_WeatherMapPanel → FlutterMap`. `FlutterMap` uses `LayoutBuilder` internally. Flutter's `LayoutBuilder` **throws `FlutterError`** when asked for intrinsic dimensions: *"LayoutBuilder does not support returning intrinsic dimensions."* This exception escapes through `IntrinsicHeight.performLayout` into the parent `Column.performLayout`, causing the **entire `_ExpandedBody` Column to fail layout** and render at 0×0. `AnimatedSize` receives child size 0→0 (no change). `ClipRect` clips to 0×0. Nothing visible.

**Change:** In `_ExpandedBodyState.build()` (~line 373):
```dart
// BEFORE
child: IntrinsicHeight(
  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, ...),
),

// AFTER
child: SizedBox(
  height: 220,
  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, ...),
),
```

**Result:** FIXED ✓ — Tiles now expand and collapse correctly.

---

## Hypotheses Not Yet Tested

1. **`_ExpandedBody` itself has 0 height** — Even with `AnimatedSize`, if `_ExpandedBody` renders at 0 height, nothing would be visible. This could be confirmed by temporarily replacing `_ExpandedBody` with a hardcoded `Container(height: 100, color: Colors.red)` to see if ANY expansion occurs. If the red box appears, `_ExpandedBody` is the problem; if not, `AnimatedSize`/`_toggle` is still the problem.

2. **`IntrinsicHeight` + `FlutterMap` layout crash** — `FlutterMap` uses `LayoutBuilder` internally. Flutter docs warn that `LayoutBuilder` inside `IntrinsicHeight` has undefined behaviour. This could silently cause `_ExpandedBody` to fail to render and display as 0 height. Fix: wrap the `IntrinsicHeight` row in a `SizedBox` with a fixed height instead.

3. **`AnimatedSize` minimum size constraint** — `AnimatedSize` may not shrink to `SizedBox.shrink()` (0×0) correctly if it's inside a `Column` with specific constraints. The tile may already be at 0-expanded height and `AnimatedSize` has no room to grow.

4. **Widget key issue causing state reset** — Each rebuild creates new `_ExpandedBody` widget instances (no explicit key). The state `_selectedSlotIndex` is in `_ExpandedBodyState`. If Flutter is rebuilding the widget tree in a way that resets the element tree, `_expanded` might be getting reset to `false` on each frame.

5. **`AnimatedContainer` around the whole tile** — The outer `AnimatedContainer` (250ms duration) wraps the entire `Column` including the expansion area. Its height is not explicitly set — it grows with children. But if it has implicit constraints preventing growth, the inner `AnimatedSize` would have nowhere to expand into.

6. **The `ListView` clipping** — `ListView` clips its children. If `AnimatedSize` is trying to grow but the `ListView` item's cached size is stale (Flutter's `SliverList` caches child extents), the tile may appear unchanged until the list is scrolled.

---

## Recommended Next Steps (in priority order)

1. **Diagnostic test:** Replace the expansion widget temporarily with `if (_expanded) Container(height: 100, color: Colors.red)` — no animation, just a raw conditional. If a red box appears on click, the state machine works and only the animation widget is broken. If nothing appears, the problem is deeper (state not actually changing, or parent clipping).

2. **Fix IntrinsicHeight + FlutterMap:** Replace `IntrinsicHeight` with a fixed-height container for the map row, e.g. `SizedBox(height: 220, child: Row([...]))`. This removes the `LayoutBuilder`-incompatible intrinsic height measurement.

3. **Add `key` to `_ExpandedBody`:** Add `key: ValueKey(f.date)` to prevent unintended state resets.

4. **Verify `ListView` extent caching:** Try wrapping each `DayForecastTile` in a `AutomaticKeepAliveClientMixin` or adding `shrinkWrap: true` to the `ListView` to see if extent caching is the issue.

---

## Build Command Reference

```bash
# Kill old exe first (prevents LNK1168 linker error)
rm build/windows/x64/runner/Debug/clearskies.exe

# Build
cd d:/ClaudeCode_Projects/ClearSkies/clearskies
D:/flutter/bin/flutter.bat build windows --debug

# Shortcut location (OneDrive Desktop, NOT regular Desktop)
C:\Users\david\OneDrive\Desktop\ClearSkies.lnk
# Points to: D:\ClaudeCode_Projects\ClearSkies\clearskies\build\windows\x64\runner\Debug\clearskies.exe
```
