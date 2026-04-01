import gleam/float
import gleam/int
import gleam/list
import gleam/string

// =============================================================================
// TYPES
// =============================================================================

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

// =============================================================================
// CONSTANTS
// =============================================================================

const pi = 3.141592653589793

const ansi_reset = "\u{001b}[0m"

const ansi_fg_prefix = "\u{001b}[38;2;"

const ansi_bg_prefix = "\u{001b}[48;2;"

// =============================================================================
// TYPE CONSTRUCTORS
// =============================================================================

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

// =============================================================================
// CONVERSION FUNCTIONS
// =============================================================================

/// Convert OKLCH color to RGB.
/// 
/// Uses the OKLAB color space as an intermediate step:
/// OKLCH -> OKLAB -> Linear RGB -> sRGB
/// 
/// Negative RGB values are clamped to 0.
pub fn oklch_to_rgb(color: Oklch) -> Rgb {
  let Oklch(l: l, c: c, h: h, alpha: alpha) = color
  let h_rad = h *. pi /. 180.0

  let a = c *. cos(h_rad)
  let b_val = c *. sin(h_rad)

  let r = 1.0 *. l +. 0.3963377774 *. a +. 0.2158037573 *. b_val
  let g = 1.0 *. l -. 0.1055613458 *. a -. 0.0638541728 *. b_val
  let b = 1.0 *. l -. 0.0894841775 *. a -. 1.291485548 *. b_val

  let r = linear_to_srgb(r)
  let g = linear_to_srgb(g)
  let b = linear_to_srgb(b)

  let r = case r <. 0.0 {
    True -> 0.0
    False -> r
  }
  let g = case g <. 0.0 {
    True -> 0.0
    False -> g
  }
  let b = case b <. 0.0 {
    True -> 0.0
    False -> b
  }

  Rgb(r: r, g: g, b: b, alpha: alpha)
}

/// Convert RGB color to OKLCH.
/// 
/// Uses the OKLAB color space as an intermediate step:
/// sRGB -> Linear RGB -> OKLAB -> OKLCH
pub fn rgb_to_oklch(color: Rgb) -> Oklch {
  let Rgb(r: r, g: g, b: b, alpha: alpha) = color

  let r = srgb_to_linear(r)
  let g = srgb_to_linear(g)
  let b = srgb_to_linear(b)

  let l = 0.2104542553 *. r +. 0.793617785 *. g -. 0.0040720468 *. b
  let a_val = 1.9779984951 *. r -. 2.428592205 *. g +. 0.4505937099 *. b
  let b_val = 0.0259040371 *. r +. 0.7827717662 *. g -. 0.808675766 *. b

  let l = case l <. 0.0 {
    True -> 0.0
    False -> l
  }
  let c = case float.square_root(a_val *. a_val +. b_val *. b_val) {
    Ok(v) -> v
    Error(_) -> 0.0
  }
  let h = atan2(b_val, a_val) *. 180.0 /. pi

  let h = case h <. 0.0 {
    True -> h +. 360.0
    False -> h
  }

  Oklch(l: l, c: c, h: h, alpha: alpha)
}

/// Convert OKLCH color to hex string.
pub fn oklch_to_hex(color: Oklch) -> String {
  let rgb = oklch_to_rgb(color)
  rgb_to_hex(rgb)
}

/// Parse a hex string to OKLCH color.
pub fn hex_to_oklch(hex: String) -> Result(Oklch, ParseError) {
  case hex_to_rgb(hex) {
    Ok(rgb) -> Ok(rgb_to_oklch(rgb))
    Error(e) -> Error(e)
  }
}

/// Convert RGB color to hex string.
pub fn rgb_to_hex(color: Rgb) -> String {
  let Rgb(r: r, g: g, b: b, alpha: alpha) = color

  let r_int = float.round(r *. 255.0)
  let g_int = float.round(g *. 255.0)
  let b_int = float.round(b *. 255.0)

  let r_hex = int.to_base16(r_int)
  let g_hex = int.to_base16(g_int)
  let b_hex = int.to_base16(b_int)

  let r_hex = case string.length(r_hex) == 1 {
    True -> "0" <> r_hex
    False -> r_hex
  }
  let g_hex = case string.length(g_hex) == 1 {
    True -> "0" <> g_hex
    False -> g_hex
  }
  let b_hex = case string.length(b_hex) == 1 {
    True -> "0" <> b_hex
    False -> b_hex
  }

  let hex_string = string.uppercase(r_hex <> g_hex <> b_hex)

  case alpha <. 1.0 {
    True -> "#" <> hex_string <> int.to_base16(float.round(alpha *. 255.0))
    False -> "#" <> hex_string
  }
}

/// Parse a hex string to RGB color.
///
/// Supports #RGB, #RGBA, #RRGGBB, #RRGGBBAA formats.
pub fn hex_to_rgb(hex: String) -> Result(Rgb, ParseError) {
  let hex = string.trim(hex)

  let hex = case string.starts_with(hex, "#") {
    True -> string.drop_start(hex, 1)
    False -> hex
  }

  let chars = string.to_graphemes(hex)
  let len = list.length(chars)

  case len {
    3 -> {
      case chars {
        [r, g, b] -> {
          let r = string.append(r, r)
          let g = string.append(g, g)
          let b = string.append(b, b)
          parse_hex_rgb(r, g, b, "FF")
        }
        _ -> Error(InvalidHexLength)
      }
    }
    4 -> {
      case chars {
        [r, g, b, a] -> {
          let r = string.append(r, r)
          let g = string.append(g, g)
          let b = string.append(b, b)
          let a = string.append(a, a)
          parse_hex_rgb(r, g, b, a)
        }
        _ -> Error(InvalidHexLength)
      }
    }
    6 -> {
      case chars {
        [r1, r2, g1, g2, b1, b2] -> {
          let r = string.append(r1, r2)
          let g = string.append(g1, g2)
          let b = string.append(b1, b2)
          parse_hex_rgb(r, g, b, "FF")
        }
        _ -> Error(InvalidHexLength)
      }
    }
    8 -> {
      case chars {
        [r1, r2, g1, g2, b1, b2, a1, a2] -> {
          let r = string.append(r1, r2)
          let g = string.append(g1, g2)
          let b = string.append(b1, b2)
          let a = string.append(a1, a2)
          parse_hex_rgb(r, g, b, a)
        }
        _ -> Error(InvalidHexLength)
      }
    }
    _ -> Error(InvalidHexLength)
  }
}

// =============================================================================
// MANIPULATION FUNCTIONS
// =============================================================================

/// Lighten a color by increasing lightness.
/// Clamps to 1.0 if the result exceeds.
pub fn lighten(color: Oklch, amount: Float) -> Oklch {
  let Oklch(l: l, c: c, h: h, alpha: alpha) = color
  let new_l = float.clamp(l +. amount, 0.0, 1.0)
  Oklch(l: new_l, c: c, h: h, alpha: alpha)
}

/// Darken a color by decreasing lightness.
/// Clamps to 0.0 if the result goes below.
pub fn darken(color: Oklch, amount: Float) -> Oklch {
  lighten(color, 0.0 -. amount)
}

/// Increase chroma (saturation).
/// Clamps to 0.4 if exceeded.
pub fn saturate(color: Oklch, amount: Float) -> Oklch {
  let Oklch(l: l, c: c, h: h, alpha: alpha) = color
  let new_c = c +. amount
  let new_c = case new_c >. 0.4 {
    True -> 0.4
    False ->
      case new_c <. 0.0 {
        True -> 0.0
        False -> new_c
      }
  }
  Oklch(l: l, c: new_c, h: h, alpha: alpha)
}

/// Decrease chroma (saturation).
/// Clamps to 0.0 if exceeded.
pub fn desaturate(color: Oklch, amount: Float) -> Oklch {
  saturate(color, 0.0 -. amount)
}

/// Rotate hue by the given degrees.
/// Positive values rotate clockwise, negative counter-clockwise.
pub fn rotate_hue(color: Oklch, degrees: Float) -> Oklch {
  let Oklch(l: l, c: c, h: h, alpha: alpha) = color
  let new_h = h +. degrees
  let new_h = case new_h <. 0.0 {
    True -> new_h +. 360.0
    False ->
      case new_h >=. 360.0 {
        True -> new_h -. 360.0 *. float.floor(new_h /. 360.0)
        False -> new_h
      }
  }
  Oklch(l: l, c: c, h: new_h, alpha: alpha)
}

/// Set the alpha (opacity) channel.
pub fn set_alpha(color: Oklch, alpha: Float) -> Oklch {
  let Oklch(l: l, c: c, h: h, alpha: _) = color
  Oklch(l: l, c: c, h: h, alpha: float.clamp(alpha, 0.0, 1.0))
}

/// Set the lightness channel.
pub fn set_l(color: Oklch, l: Float) -> Oklch {
  let Oklch(l: _, c: c, h: h, alpha: alpha) = color
  Oklch(l: float.clamp(l, 0.0, 1.0), c: c, h: h, alpha: alpha)
}

/// Set the chroma (saturation) channel.
pub fn set_c(color: Oklch, c: Float) -> Oklch {
  let Oklch(l: l, c: _, h: h, alpha: alpha) = color
  Oklch(l: l, c: float.clamp(c, 0.0, 0.4), h: h, alpha: alpha)
}

/// Set the hue channel.
pub fn set_h(color: Oklch, h: Float) -> Oklch {
  let Oklch(l: l, c: c, h: _, alpha: alpha) = color
  let h = case h <. 0.0 {
    True -> h +. 360.0
    False ->
      case h >=. 360.0 {
        True -> h -. 360.0 *. float.floor(h /. 360.0)
        False -> h
      }
  }
  Oklch(l: l, c: c, h: h, alpha: alpha)
}

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

/// Mix two colors together using linear interpolation.
/// The weight parameter controls the mix: 0.0 returns color1, 1.0 returns color2.
/// Weight is clamped to 0.0-1.0 range.
/// Handles hue interpolation correctly across the 0/360 boundary.
pub fn mix(color1: Oklch, color2: Oklch, weight: Float) -> Oklch {
  let Oklch(l: l1, c: c1, h: h1, alpha: a1) = color1
  let Oklch(l: l2, c: c2, h: h2, alpha: a2) = color2

  let weight = float.clamp(weight, 0.0, 1.0)

  let w1 = 1.0 -. weight
  let w2 = weight

  let l = l1 *. w1 +. l2 *. w2
  let c = c1 *. w1 +. c2 *. w2
  let h = lerp_angle(h1, h2, weight)
  let alpha = a1 *. w1 +. a2 *. w2

  Oklch(l: l, c: c, h: h, alpha: alpha)
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

// =============================================================================
// ANSI FUNCTIONS
// =============================================================================

/// Wrap text in ANSI escape codes to display it with the given foreground color.
pub fn ansi(color: Oklch, text: String) -> String {
  let rgb = oklch_to_rgb(color)
  let Rgb(r: r, g: g, b: b, alpha: _) = rgb
  let r = float_to_256(r)
  let g = float_to_256(g)
  let b = float_to_256(b)

  ansi_fg_prefix
  <> int.to_string(r)
  <> ";"
  <> int.to_string(g)
  <> ";"
  <> int.to_string(b)
  <> "m"
  <> text
  <> ansi_reset
}

/// Wrap text in ANSI escape codes to display it with the given background color.
pub fn ansi_bg(color: Oklch, text: String) -> String {
  let rgb = oklch_to_rgb(color)
  let Rgb(r: r, g: g, b: b, alpha: _) = rgb
  let r = float_to_256(r)
  let g = float_to_256(g)
  let b = float_to_256(b)

  ansi_bg_prefix
  <> int.to_string(r)
  <> ";"
  <> int.to_string(g)
  <> ";"
  <> int.to_string(b)
  <> "m"
  <> text
  <> ansi_reset
}

/// Wrap text in ANSI escape codes to display it with both foreground and background colors.
pub fn ansi_fg_bg(fg: Oklch, bg: Oklch, text: String) -> String {
  let fg_rgb = oklch_to_rgb(fg)
  let Rgb(r: fg_r, g: fg_g, b: fg_b, alpha: _) = fg_rgb

  let bg_rgb = oklch_to_rgb(bg)
  let Rgb(r: bg_r, g: bg_g, b: bg_b, alpha: _) = bg_rgb

  let fg_r = float_to_256(fg_r)
  let fg_g = float_to_256(fg_g)
  let fg_b = float_to_256(fg_b)
  let bg_r = float_to_256(bg_r)
  let bg_g = float_to_256(bg_g)
  let bg_b = float_to_256(bg_b)

  ansi_fg_prefix
  <> int.to_string(fg_r)
  <> ";"
  <> int.to_string(fg_g)
  <> ";"
  <> int.to_string(fg_b)
  <> "m"
  <> ansi_bg_prefix
  <> int.to_string(bg_r)
  <> ";"
  <> int.to_string(bg_g)
  <> ";"
  <> int.to_string(bg_b)
  <> "m"
  <> text
  <> ansi_reset
}

// =============================================================================
// PRIVATE HELPER FUNCTIONS
// =============================================================================

fn clamp_l(l: Float) -> Float {
  float.clamp(l, 0.0, 1.0)
}

fn clamp_c(c: Float) -> Float {
  float.clamp(c, 0.0, 0.4)
}

fn clamp_h(h: Float) -> Float {
  case float.modulo(h, 360.0) {
    Ok(normalized) ->
      case normalized <. 0.0 {
        True -> normalized +. 360.0
        False -> normalized
      }
    Error(_) -> 0.0
  }
}

fn clamp_alpha(alpha: Float) -> Float {
  float.clamp(alpha, 0.0, 1.0)
}

fn clamp_channel(c: Float) -> Float {
  float.clamp(c, 0.0, 1.0)
}

fn parse_hex_rgb(
  r_hex: String,
  g_hex: String,
  b_hex: String,
  a_hex: String,
) -> Result(Rgb, ParseError) {
  case
    int.base_parse(r_hex, 16),
    int.base_parse(g_hex, 16),
    int.base_parse(b_hex, 16),
    int.base_parse(a_hex, 16)
  {
    Ok(r), Ok(g), Ok(b), Ok(a) -> {
      Ok(rgb_from_ints(r, g, b, int.to_float(a) /. 255.0))
    }
    _, _, _, _ -> Error(InvalidHexValue)
  }
}

fn srgb_to_linear(c: Float) -> Float {
  let c = case c <. 0.0 {
    True -> 0.0
    False ->
      case c >. 1.0 {
        True -> 1.0
        False -> c
      }
  }
  let threshold = 0.04045 /. 12.92
  case c <. threshold {
    True -> c /. 12.92
    False -> {
      let tmp = c +. 0.055
      let c = tmp /. 1.055
      c *. c *. c
    }
  }
}

fn linear_to_srgb(c: Float) -> Float {
  let c = case c <. 0.0 {
    True -> 0.0
    False -> c
  }
  case c <. 0.0031308 {
    True -> c *. 12.92
    False -> {
      case float.power(c, 1.0 /. 3.0) {
        Ok(tmp) -> {
          let c = tmp *. 1.055 -. 0.055
          case c >. 1.0 {
            True -> 1.0
            False -> c
          }
        }
        Error(_) -> 0.0
      }
    }
  }
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

fn float_to_256(f: Float) -> Int {
  float.clamp(f, 0.0, 1.0) *. 255.0 |> float.round
}

// =============================================================================
// FFI FUNCTIONS
// =============================================================================

@external(erlang, "math", "cos")
@external(javascript, "Math", "cos")
fn cos(x: Float) -> Float

@external(erlang, "math", "sin")
@external(javascript, "Math", "sin")
fn sin(x: Float) -> Float

@external(erlang, "math", "atan2")
@external(javascript, "Math", "atan2")
fn atan2(y: Float, x: Float) -> Float
