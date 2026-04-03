<p align="center">
  <img src="logo.png" alt="niji logo" width="300">
</p>

# niji

[![Package Version](https://img.shields.io/hexpm/v/niji)](https://hex.pm/packages/niji)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/niji/)

A practical OKLCH color toolkit for Gleam.

It includes:

- OKLCH and RGB types
- OKLCH <-> RGB conversion
- CSS-style gamut mapping for out-of-gamut colors
- Hex parsing/formatting (`#RGB`, `#RGBA`, `#RRGGBB`, `#RRGGBBAA`)
- Color manipulation helpers (lighten, saturate, rotate hue, mix)
- Palette helpers (complementary, triadic, analogous, split-complementary)
- Perceptual distance (`deltaE OK`)
- WCAG contrast checks
- ANSI terminal color output
- Integration with `gleam_community/colour`

## What Is OKLCH?

OKLCH is a perceptual color space based on OKLab, expressed as:

- `L`: lightness (`0.0` to `1.0`)
- `C`: chroma (color intensity, `>= 0.0`)
- `H`: hue angle in degrees (`0` to `360`)

Compared to RGB/HSL, OKLCH is usually easier to reason about when designing palettes:

- equal lightness steps look more visually even,
- hue rotation gives more predictable color relationships,
- chroma control is more intuitive for vivid vs muted colors.

In this library, `to_rgb/1` applies CSS-inspired gamut mapping so colors that cannot be displayed in sRGB are adjusted more gracefully than simple channel clipping.

## Installation

```sh
gleam add niji@1
```

## Quick Start

```gleam
import niji

pub fn main() {
  let brand = niji.oklch(0.62, 0.19, 250.0, 1.0)

  // Convert to CSS and hex
  let css = niji.to_css(brand)
  let hex = niji.to_hex(brand)

  // Generate a complementary color
  let complement = niji.complementary(brand)

  // Mix 20% toward complement
  let mixed = niji.mix(brand, complement, 0.2)

  // Guarantee sRGB-safe output for UI
  let safe = niji.gamut_map(mixed)

  // Print values in terminal color
  let preview = niji.ansi_bg(safe, "  OKLCH  ")
  preview
}
```

## Core API

### Constructors

- `oklch(l, c, h, alpha)`
- `rgb(r, g, b, alpha)`
- `rgb_from_ints(r, g, b, alpha)`

All constructors normalize/clamp inputs to safe ranges.

### Conversion

- `to_rgb(color)`
- `to_rgb_clamped(color)`
- `rgb_to_oklch(color)`
- `to_hex(color)`
- `rgb_to_hex(color)`

### Manipulation

- `lighten`, `darken`
- `saturate`, `desaturate`
- `rotate_hue`
- `set_l`, `set_c`, `set_h`, `set_alpha`
- `mix`

### Palette helpers

- `complementary(color)`
- `triadic(color) -> #(Oklch, Oklch)`
- `analogous(color, angle) -> #(Oklch, Oklch)`
- `split_complementary(color, angle) -> #(Oklch, Oklch)`

### Gamut + distance

- `in_gamut(color) -> Bool`
- `gamut_map(color) -> Oklch`
- `distance(color1, color2) -> Float`

### Accessibility

- `luminance(color)`
- `contrast_ratio(color1, color2)`
- `wcag_aa(ratio)`
- `wcag_aaa(ratio)`
- `wcag_aa_large_text(ratio)`
- `wcag_aaa_large_text(ratio)`

### ANSI output

- `ansi(color, text)` (foreground)
- `ansi_bg(color, text)` (background)
- `ansi_fg_bg(fg, bg, text)`

### `gleam_community/colour` interop

- `from_colour(colour)`
- `to_colour(oklch_color)`

## Examples

### Parse hex and rotate hue

```gleam
import niji
import gleam_community/colour
import gleam/result

pub fn main() {
  let assert Ok(rotated) =
    colour.from_rgb_hex_string("#3366FF")
    |> result.map(niji.from_colour)
    |> result.map(niji.rotate_hue(_, 45.0))

  niji.to_css(rotated)
}
```

### Check contrast

```gleam
import niji

pub fn main() {
  let text = niji.oklch(0.15, 0.02, 250.0, 1.0)
  let bg = niji.oklch(0.96, 0.01, 250.0, 1.0)

  let ratio = niji.contrast_ratio(text, bg)
  let passes = niji.wcag_aa(ratio)

  #(ratio, passes)
}
```

## Development

```sh
gleam test
gleam run
```

## Notes

- Chroma (`c`) is lower-bounded at `0.0` and not hard-capped.
- Hue wraps around the color wheel (`0..360`).
- `to_rgb/1` is recommended for display output in sRGB contexts.

## Documentation

- Hex package: <https://hex.pm/packages/niji>
- API docs: <https://hexdocs.pm/niji/>
