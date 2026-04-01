# OKLCH Implementation Fix Plan

## Goal

Bring `src/oklch.gleam` in line with CSS Color 4 / OKLab-OKLCH conversions, make gamut mapping actually effective, and lock behavior with reference-quality tests.

## Phase 1: Correct Core Color Math

1. Replace `rgb_to_oklch/1` internals with canonical pipeline:
   - sRGB -> linear sRGB (correct transfer function)
   - linear sRGB -> LMS (matrix)
   - LMS -> nonlinearity (`cbrt` per channel)
   - LMS' -> OKLab (matrix)
   - OKLab -> OKLCH (`C = sqrt(a^2+b^2)`, `h = atan2(b,a)`)
2. Replace `oklch_to_rgb_clamped/1` internals with inverse canonical pipeline:
   - OKLCH -> OKLab (`a = C*cos(h)`, `b = C*sin(h)`)
   - OKLab -> LMS' (inverse matrix)
   - LMS' -> LMS (`^3`)
   - LMS -> linear sRGB (inverse matrix)
   - linear sRGB -> sRGB transfer function
3. Keep alpha pass-through unchanged.

## Phase 2: Fix Transfer Functions

1. `srgb_to_linear/1`
   - Use branch threshold `0.04045` (not divided by 12.92).
   - For upper branch use `((c + 0.055) / 1.055) ^ 2.4`.
2. `linear_to_srgb/1`
   - Use threshold `0.0031308`.
   - For upper branch use `1.055 * (c ^ (1/2.4)) - 0.055`.
3. Clamp output channel to `[0,1]` only where intended (final public RGB output), not in internal gamut checks.

## Phase 3: Make Gamut Mapping Functional

1. Introduce an unclamped conversion path for internal checks (e.g. `oklch_to_rgb_raw/1`) that can return values outside `[0,1]`.
2. Update `is_in_gamut/1` to evaluate raw RGB channel bounds.
3. Update `clip_to_gamut/1` to:
   - convert via raw path,
   - clamp channels,
   - convert back to OKLCH with corrected transforms.
4. Keep `oklch_to_rgb/1` behavior:
   - short-circuit black/white,
   - if in gamut, return converted color,
   - else run binary-search Local MINDE path.
5. Verify `binary_search_chroma/8` returns the searched chroma candidate (or clipped candidate) rather than defaulting back to unrelated original state at termination.

## Phase 4: Serialization and Hex Fixes

1. Fix `format_chroma/1` and `format_alpha/1` to preserve leading zeros in decimals:
   - `0.05` must serialize as `"0.05"`, not `"0.5"`.
2. Ensure alpha hex in `rgb_to_hex/1` is always two uppercase hex digits when `alpha < 1.0`.
3. Optionally centralize two-digit hex formatting in a helper (`to_hex_2/1`) used by all channels.

## Phase 5: Hue Normalization Robustness

1. Replace manual single-step wrap logic in `rotate_hue/2` and `set_h/2` with the shared modulo-based normalization (`clamp_h/1` style), so large negative values normalize correctly.

## Phase 6: Testing Upgrades

1. Add reference conversion tests with known-value fixtures:
   - `#FF0000`, `#00FF00`, `#0000FF`, neutral grays, and a wide-gamut-like high chroma case.
2. Add round-trip accuracy thresholds:
   - `RGB -> OKLCH -> RGB` absolute per-channel tolerance.
3. Add dedicated gamut-mapping behavior tests:
   - assert out-of-gamut input follows mapped path,
   - assert mapped RGB channels end in `[0,1]`,
   - assert approximate lightness/hue preservation.
4. Add CSS string edge cases:
   - chroma/alpha values `0.01`, `0.05`, `0.10`, `1.00`.
5. Add hex alpha formatting tests:
   - e.g. alpha `0.03`, `0.5`, `1.0`.

## Phase 7: Validation and Regression Checks

1. Run `gleam test` and ensure all legacy tests still pass or are updated for corrected math.
2. Add a small developer sanity script in `dev/oklch_dev.gleam` to print a few known conversions for quick manual inspection.
3. Confirm docs/examples match final output formatting and behavior.

## Suggested Execution Order

1. Core math + transfer functions
2. Gamut mapping plumbing
3. Formatting/hex fixes
4. Tests
5. Final cleanup and docs touch-ups
