/// Utility functions for OKLCH colors.
import oklch/types.{type Oklch, Oklch}

/// Mix two colors together using linear interpolation.
/// The weight parameter controls the mix: 0.0 returns color1, 1.0 returns color2.
/// Weight is clamped to 0.0-1.0 range.
/// Handles hue interpolation correctly across the 0/360 boundary.
pub fn mix(color1: Oklch, color2: Oklch, weight: Float) -> Oklch {
  let Oklch(l: l1, c: c1, h: h1, alpha: a1) = color1
  let Oklch(l: l2, c: c2, h: h2, alpha: a2) = color2

  let weight = case weight <. 0.0 {
    True -> 0.0
    False ->
      case weight >. 1.0 {
        True -> 1.0
        False -> weight
      }
  }

  let w1 = 1.0 -. weight
  let w2 = weight

  let l = l1 *. w1 +. l2 *. w2
  let c = c1 *. w1 +. c2 *. w2
  let h = lerp_angle(h1, h2, weight)
  let alpha = a1 *. w1 +. a2 *. w2

  Oklch(l: l, c: c, h: h, alpha: alpha)
}

fn lerp_angle(a: Float, b: Float, t: Float) -> Float {
  let diff = b -. a
  let diff = case diff >. 180.0 {
    True -> diff -. 360.0
    False ->
      case diff <. -180.0 {
        True -> diff +. 360.0
        False -> diff
      }
  }
  let result = a +. diff *. t
  let result = case result <. 0.0 {
    True -> result +. 360.0
    False ->
      case result >=. 360.0 {
        True -> result -. 360.0
        False -> result
      }
  }
  result
}

/// Get the relative luminance of a color.
/// In OKLCH, lightness (L) directly corresponds to relative luminance.
pub fn luminance(color: Oklch) -> Float {
  let Oklch(l: l, c: _, h: _, alpha: _) = color
  l
}

/// Calculate the contrast ratio between two colors using WCAG formula.
/// Returns a value from 1.0 (no contrast) to 21.0 (maximum contrast).
pub fn contrast_ratio(color1: Oklch, color2: Oklch) -> Float {
  let l1 = luminance(color1)
  let l2 = luminance(color2)

  let lighter = case l1 >. l2 {
    True -> l1
    False -> l2
  }
  let darker = case l1 >. l2 {
    True -> l2
    False -> l1
  }

  let lighter = lighter +. 0.05
  let darker = darker +. 0.05

  lighter /. darker
}

/// Check if a contrast ratio meets WCAG AA standard for normal text (4.5:1).
pub fn wcag_aa(ratio: Float) -> Bool {
  ratio >=. 4.5
}

/// Check if a contrast ratio meets WCAG AAA standard for normal text (7:1).
pub fn wcag_aaa(ratio: Float) -> Bool {
  ratio >=. 7.0
}

/// Check if a contrast ratio meets WCAG AA standard for large text (3:1).
pub fn wcag_aa_large_text(ratio: Float) -> Bool {
  ratio >=. 3.0
}

/// Check if a contrast ratio meets WCAG AAA standard for large text (4.5:1).
pub fn wcag_aaa_large_text(ratio: Float) -> Bool {
  ratio >=. 4.5
}
