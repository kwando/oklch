/// Core types for the OKLCH color library.
/// This module contains the fundamental color types and constructors.
import gleam/float
import gleam/int

/// OKLCH color representation.
///
/// - `l`: Lightness (0.0 = black, 1.0 = white)
/// - `c`: Chroma/saturation (0.0 = neutral gray, 0.4 = maximum)
/// - `h`: Hue in degrees (0-360, where 0=red, 120=green, 240=blue)
/// - `alpha`: Opacity (0.0 = transparent, 1.0 = opaque)
pub type Oklch {
  Oklch(l: Float, c: Float, h: Float, alpha: Float)
}

/// RGB color representation.
///
/// - `r`: Red channel (0.0-1.0)
/// - `g`: Green channel (0.0-1.0)
/// - `b`: Blue channel (0.0-1.0)
/// - `alpha`: Opacity (0.0 = transparent, 1.0 = opaque)
pub type Rgb {
  Rgb(r: Float, g: Float, b: Float, alpha: Float)
}

/// Errors that can occur when parsing hex color strings.
pub type ParseError {
  /// The hex string has an invalid length (not 3, 4, 6, or 8 characters).
  InvalidHexLength
  /// The hex string contains invalid hexadecimal characters.
  InvalidHexValue
  /// A color channel value is outside the valid range.
  InvalidChannelValue
}

/// Create an OKLCH color with automatic clamping.
///
/// Values outside valid ranges are clamped:
/// - L is clamped to 0.0-1.0
/// - C is clamped to 0.0-0.4
/// - H wraps around (e.g., 400 becomes 40)
/// - Alpha is clamped to 0.0-1.0
pub fn oklch(l: Float, c: Float, h: Float, alpha: Float) -> Oklch {
  Oklch(l: clamp_l(l), c: clamp_c(c), h: clamp_h(h), alpha: clamp_alpha(alpha))
}

/// Create an RGB color with automatic clamping.
///
/// Values outside 0.0-1.0 are clamped.
pub fn rgb(r: Float, g: Float, b: Float, alpha: Float) -> Rgb {
  Rgb(
    r: clamp_channel(r),
    g: clamp_channel(g),
    b: clamp_channel(b),
    alpha: clamp_alpha(alpha),
  )
}

/// Create an RGB color from integer values (0-255).
///
/// Values outside 0-255 are clamped.
pub fn rgb_from_ints(r: Int, g: Int, b: Int, alpha: Float) -> Rgb {
  let r = int.clamp(r, 0, 255)
  let g = int.clamp(g, 0, 255)
  let b = int.clamp(b, 0, 255)
  Rgb(
    r: int.to_float(r) /. 255.0,
    g: int.to_float(g) /. 255.0,
    b: int.to_float(b) /. 255.0,
    alpha: clamp_alpha(alpha),
  )
}

fn clamp_l(l: Float) -> Float {
  float.clamp(l, 0.0, 1.0)
}

fn clamp_c(c: Float) -> Float {
  float.clamp(c, 0.0, 0.4)
}

fn clamp_h(h: Float) -> Float {
  let assert Ok(normalized) = float.modulo(h, 360.0)

  case normalized <. 0.0 {
    True -> normalized +. 360.0
    False -> normalized
  }
}

fn clamp_alpha(alpha: Float) -> Float {
  float.clamp(alpha, 0.0, 1.0)
}

fn clamp_channel(c: Float) -> Float {
  float.clamp(c, 0.0, 1.0)
}
