import gleam/float
import gleam/int
import gleam/string
import gleam_community/colour.{type Colour}

// =============================================================================
// TYPES
// =============================================================================

/// OKLCH color representation.
///
/// - `l`: Lightness (0.0 = black, 1.0 = white)
/// - `c`: Chroma/saturation (0.0 = neutral gray, can exceed 0.4 for wide-gamut colors)
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
/// - C is clamped to 0.0 or greater (no upper bound)
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

/// Convert OKLCH color to RGB using CSS gamut mapping.
///
/// Uses the CSS Color Module Level 4 gamut mapping algorithm:
/// "Binary Search Gamut Mapping with Local MINDE"
/// https://www.w3.org/TR/css-color-4/#gamut-mapping
///
/// This algorithm preserves lightness and hue while reducing chroma
/// to bring out-of-gamut colors into the sRGB gamut. The result is
/// perceptually closer to the original color than simple clamping.
///
/// For colors already within the sRGB gamut, no modification is made.
/// For colors outside the gamut, chroma is reduced until the color
/// fits within sRGB or until the difference between the clipped and
/// target color is below the Just Noticeable Difference (JND) threshold.
pub fn oklch_to_rgb(color: Oklch) -> Rgb {
  // Handle edge cases first (white and black)
  let Oklch(l: l, c: _, h: _, alpha: alpha) = color

  // If lightness >= 100%, return white
  case l >=. 1.0 {
    True -> Rgb(r: 1.0, g: 1.0, b: 1.0, alpha: alpha)
    False -> {
      // If lightness <= 0%, return black
      case l <=. 0.0 {
        True -> Rgb(r: 0.0, g: 0.0, b: 0.0, alpha: alpha)
        False -> {
          // Check if already in gamut
          case is_in_gamut(color) {
            True -> oklch_to_rgb_clamped(color)
            False -> gamut_map_oklch_to_rgb(color)
          }
        }
      }
    }
  }
}

/// Convert OKLCH color to RGB using simple clamping.
///
/// This is the original behavior that simply clamps negative RGB values
/// to 0.0 and values > 1.0 to 1.0. This is faster but produces less
/// perceptually accurate results than the gamut mapping algorithm.
///
/// For CSS-compliant gamut mapping, use oklch_to_rgb/1 instead.
pub fn oklch_to_rgb_clamped(color: Oklch) -> Rgb {
  let Rgb(r: r, g: g, b: b, alpha: alpha) = oklch_to_rgb_raw(color)
  Rgb(
    r: float.clamp(r, 0.0, 1.0),
    g: float.clamp(g, 0.0, 1.0),
    b: float.clamp(b, 0.0, 1.0),
    alpha: alpha,
  )
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

  let l = 0.4122214708 *. r +. 0.5363325363 *. g +. 0.0514459929 *. b
  let m = 0.2119034982 *. r +. 0.6806995451 *. g +. 0.1073969566 *. b
  let s = 0.0883024619 *. r +. 0.2817188376 *. g +. 0.6299787005 *. b

  let l_root = cube_root(l)
  let m_root = cube_root(m)
  let s_root = cube_root(s)

  let l =
    0.2104542553 *. l_root +. 0.793617785 *. m_root -. 0.0040720468 *. s_root
  let a_val =
    1.9779984951 *. l_root -. 2.428592205 *. m_root +. 0.4505937099 *. s_root
  let b_val =
    0.0259040371 *. l_root +. 0.7827717662 *. m_root -. 0.808675766 *. s_root

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

/// Convert an OKLCH color to a hex string.
///
/// Output is `#RRGGBB` when alpha is 1.0, otherwise `#RRGGBBAA`.
/// Channel bytes are rounded and uppercase.
pub fn oklch_to_hex(color: Oklch) -> String {
  let rgb = oklch_to_rgb(color)
  rgb_to_hex(rgb)
}

/// Convert an RGB color to a hex string.
///
/// Output is `#RRGGBB` when alpha is 1.0, otherwise `#RRGGBBAA`.
/// Channel bytes are rounded and uppercase.
pub fn rgb_to_hex(color: Rgb) -> String {
  let Rgb(r: r, g: g, b: b, alpha: alpha) = color

  let r_hex = to_hex_2(float.round(r *. 255.0))
  let g_hex = to_hex_2(float.round(g *. 255.0))
  let b_hex = to_hex_2(float.round(b *. 255.0))

  let hex_string = r_hex <> g_hex <> b_hex

  case alpha <. 1.0 {
    True -> "#" <> hex_string <> to_hex_2(float.round(alpha *. 255.0))
    False -> "#" <> hex_string
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
/// Values below 0.0 are clamped to 0.0, no upper bound.
pub fn saturate(color: Oklch, amount: Float) -> Oklch {
  let Oklch(l: l, c: c, h: h, alpha: alpha) = color
  let new_c = c +. amount
  Oklch(l: l, c: float.max(new_c, 0.0), h: h, alpha: alpha)
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
  let new_h = clamp_h(h +. degrees)
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
/// Values below 0.0 are clamped to 0.0, no upper bound.
pub fn set_c(color: Oklch, c: Float) -> Oklch {
  let Oklch(l: l, c: _, h: h, alpha: alpha) = color
  Oklch(l: l, c: float.max(c, 0.0), h: h, alpha: alpha)
}

/// Set the hue channel.
pub fn set_h(color: Oklch, h: Float) -> Oklch {
  let Oklch(l: l, c: c, h: _, alpha: alpha) = color
  let h = clamp_h(h)
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

/// Get the complementary color (hue + 180deg).
///
/// Lightness, chroma, and alpha are preserved.
pub fn complementary(color: Oklch) -> Oklch {
  rotate_hue(color, 180.0)
}

/// Get the two triadic colors (hue + 120deg and +240deg).
///
/// Lightness, chroma, and alpha are preserved.
pub fn triadic(color: Oklch) -> #(Oklch, Oklch) {
  #(rotate_hue(color, 120.0), rotate_hue(color, 240.0))
}

/// Get split complementary colors around the complement.
///
/// For an angle of 30deg, this returns hues at +150deg and +210deg.
/// Lightness, chroma, and alpha are preserved.
pub fn split_complementary(color: Oklch, angle: Float) -> #(Oklch, Oklch) {
  let angle = clamp_h(angle)
  #(rotate_hue(color, 180.0 -. angle), rotate_hue(color, 180.0 +. angle))
}

/// Get analogous colors on both sides of the hue wheel.
///
/// For an angle of 30deg, this returns hues at -30deg and +30deg.
/// Lightness, chroma, and alpha are preserved.
pub fn analogous(color: Oklch, angle: Float) -> #(Oklch, Oklch) {
  let angle = clamp_h(angle)
  #(rotate_hue(color, 0.0 -. angle), rotate_hue(color, angle))
}

/// Get the relative luminance of a color.
/// In OKLCH, lightness (L) directly corresponds to relative luminance.
pub fn luminance(color: Oklch) -> Float {
  let Oklch(l: l, c: _, h: _, alpha: _) = color
  l
}

/// Check if the color has a meaningful hue.
/// Returns False when chroma is 0 (achromatic colors like grays).
/// Per CSS spec, hue is "none" when chroma is 0.
pub fn has_hue(color: Oklch) -> Bool {
  let Oklch(c: c, ..) = color
  c >. 0.0
}

/// Check whether an OKLCH color is directly representable in sRGB gamut.
///
/// Returns `True` only when the converted RGB channels are all in `[0.0, 1.0]`
/// before clamping.
pub fn in_gamut(color: Oklch) -> Bool {
  is_in_gamut(color)
}

/// Map an OKLCH color into sRGB gamut and return it as OKLCH.
///
/// In-gamut colors are returned unchanged. Out-of-gamut colors are converted
/// through the CSS-style gamut mapping path used by `oklch_to_rgb/1`.
pub fn gamut_map(color: Oklch) -> Oklch {
  case is_in_gamut(color) {
    True -> color
    False -> oklch_to_rgb(color) |> rgb_to_oklch
  }
}

/// Calculate perceptual distance (deltaE OK) between two colors.
///
/// A value of `0.0` means the colors are identical in OKLab coordinates.
pub fn distance(color1: Oklch, color2: Oklch) -> Float {
  delta_e_ok(color1, color2)
}

/// Serialize OKLCH color to CSS string format.
/// 
/// Output format: "oklch(50% 0.2 180deg)" or "oklch(50% 0.2 180deg / 0.5)"
/// - Lightness is shown as percentage (0% - 100%)
/// - Chroma is shown as a number (no unit, can exceed 0.4)
/// - Hue is shown as degrees or "none" when chroma is 0
/// - Alpha is only shown when less than 1.0
/// 
/// ## Examples
/// ```gleam
/// oklch_to_css(oklch(0.5, 0.2, 180.0, 1.0))
/// // -> "oklch(50% 0.2 180deg)"
/// 
/// oklch_to_css(oklch(0.5, 0.0, 0.0, 1.0))
/// // -> "oklch(50% 0 none)"
/// 
/// oklch_to_css(oklch(0.5, 0.2, 180.0, 0.5))
/// // -> "oklch(50% 0.2 180deg / 0.5)"
/// ```
pub fn oklch_to_css(color: Oklch) -> String {
  let Oklch(l: l, c: c, h: h, alpha: alpha) = color

  // Format lightness as percentage
  let l_pct = float.round(l *. 100.0)

  // Format chroma (2 decimal places max)
  let c_str = format_chroma(c)

  // Format hue or "none" when achromatic
  let h_str = case has_hue(color) {
    True -> float.round(h) |> int.to_string() <> "deg"
    False -> "none"
  }

  // Build base string
  let base = "oklch(" <> int.to_string(l_pct) <> "% " <> c_str <> " " <> h_str

  // Add alpha if not fully opaque
  case alpha <. 1.0 {
    True -> {
      let alpha_str = format_alpha(alpha)
      base <> " / " <> alpha_str <> ")"
    }
    False -> base <> ")"
  }
}

fn format_chroma(c: Float) -> String {
  format_decimal_2(c)
}

fn format_alpha(alpha: Float) -> String {
  format_decimal_2(alpha)
}

fn format_decimal_2(value: Float) -> String {
  let rounded = float.round(value *. 100.0)
  let whole = rounded / 100
  let decimal = rounded % 100

  case decimal {
    0 -> int.to_string(whole)
    _ ->
      case decimal % 10 {
        0 -> int.to_string(whole) <> "." <> int.to_string(decimal / 10)
        _ -> int.to_string(whole) <> "." <> pad_2(decimal)
      }
  }
}

fn pad_2(value: Int) -> String {
  case value < 10 {
    True -> "0" <> int.to_string(value)
    False -> int.to_string(value)
  }
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
  // Only enforce lower bound (0.0), no upper bound per CSS spec
  float.max(c, 0.0)
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

fn srgb_to_linear(c: Float) -> Float {
  let c = case c <. 0.0 {
    True -> 0.0
    False ->
      case c >. 1.0 {
        True -> 1.0
        False -> c
      }
  }
  let threshold = 0.04045
  case c <. threshold {
    True -> c /. 12.92
    False -> {
      let c = { c +. 0.055 } /. 1.055
      case float.power(c, 2.4) {
        Ok(v) -> v
        Error(_) -> 0.0
      }
    }
  }
}

fn linear_to_srgb(c: Float) -> Float {
  case c <. 0.0031308 {
    True -> c *. 12.92
    False -> {
      case float.power(c, 1.0 /. 2.4) {
        Ok(tmp) -> {
          tmp *. 1.055 -. 0.055
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

fn to_hex_2(value: Int) -> String {
  let hex = int.clamp(value, 0, 255) |> int.to_base16 |> string.uppercase
  case string.length(hex) == 1 {
    True -> "0" <> hex
    False -> hex
  }
}

fn cube_root(x: Float) -> Float {
  case x <. 0.0 {
    True -> {
      case float.power(0.0 -. x, 1.0 /. 3.0) {
        Ok(v) -> 0.0 -. v
        Error(_) -> 0.0
      }
    }
    False -> {
      case float.power(x, 1.0 /. 3.0) {
        Ok(v) -> v
        Error(_) -> 0.0
      }
    }
  }
}

fn oklch_to_rgb_raw(color: Oklch) -> Rgb {
  let Oklch(l: l, c: c, h: h, alpha: alpha) = color
  let h_rad = h *. pi /. 180.0

  let a = c *. cos(h_rad)
  let b_val = c *. sin(h_rad)

  let l_dash = l +. 0.3963377774 *. a +. 0.2158037573 *. b_val
  let m_dash = l -. 0.1055613458 *. a -. 0.0638541728 *. b_val
  let s_dash = l -. 0.0894841775 *. a -. 1.291485548 *. b_val

  let l_linear = l_dash *. l_dash *. l_dash
  let m_linear = m_dash *. m_dash *. m_dash
  let s_linear = s_dash *. s_dash *. s_dash

  let r_linear =
    4.0767416621
    *. l_linear
    -. 3.3077115913
    *. m_linear
    +. 0.2309699292
    *. s_linear
  let g_linear =
    2.6097574011
    *. m_linear
    -. 1.2684380046
    *. l_linear
    -. 0.3413193965
    *. s_linear
  let b_linear =
    1.707614701
    *. s_linear
    -. 0.0041960863
    *. l_linear
    -. 0.7034186147
    *. m_linear

  Rgb(
    r: linear_to_srgb(r_linear),
    g: linear_to_srgb(g_linear),
    b: linear_to_srgb(b_linear),
    alpha: alpha,
  )
}

// =============================================================================
// GAMUT MAPPING HELPER FUNCTIONS
// =============================================================================
// These functions implement CSS Color Module Level 4 gamut mapping:
// https://www.w3.org/TR/css-color-4/#gamut-mapping

const jnd = 0.02

const epsilon = 0.0001

/// Check if an OKLCH color is within the sRGB gamut.
/// Returns true if all RGB components are in the range [0.0, 1.0].
fn is_in_gamut(color: Oklch) -> Bool {
  let rgb = oklch_to_rgb_raw(color)
  let Rgb(r: r, g: g, b: b, ..) = rgb
  r >=. 0.0 && r <=. 1.0 && g >=. 0.0 && g <=. 1.0 && b >=. 0.0 && b <=. 1.0
}

/// Clip an OKLCH color to the sRGB gamut.
/// Simply clamps RGB components to [0.0, 1.0].
fn clip_to_gamut(color: Oklch) -> Oklch {
  let rgb = oklch_to_rgb_raw(color)
  let Rgb(r: r, g: g, b: b, alpha: alpha) = rgb
  // Clamp each component to [0.0, 1.0]
  let r = float.clamp(r, 0.0, 1.0)
  let g = float.clamp(g, 0.0, 1.0)
  let b = float.clamp(b, 0.0, 1.0)
  // Convert back to OKLCH
  rgb_to_oklch(Rgb(r: r, g: g, b: b, alpha: alpha))
}

/// Calculate the deltaEOK (color difference) between two OKLCH colors.
/// This is the perceptual color difference metric used in OKLCH.
fn delta_e_ok(color1: Oklch, color2: Oklch) -> Float {
  let Oklch(l: l1, c: c1, h: h1, ..) = color1
  let Oklch(l: l2, c: c2, h: h2, ..) = color2

  // Convert to Oklab (rectangular) coordinates for deltaE calculation
  let h1_rad = h1 *. pi /. 180.0
  let h2_rad = h2 *. pi /. 180.0

  let a1 = c1 *. cos(h1_rad)
  let b1 = c1 *. sin(h1_rad)

  let a2 = c2 *. cos(h2_rad)
  let b2 = c2 *. sin(h2_rad)

  // Euclidean distance in Oklab space
  let dl = l1 -. l2
  let da = a1 -. a2
  let db = b1 -. b2

  case float.square_root(dl *. dl +. da *. da +. db *. db) {
    Ok(v) -> v
    Error(_) -> 0.0
  }
}

/// Gamut map an OKLCH color to RGB using CSS algorithm.
/// Uses binary search with Local MINDE to find optimal chroma reduction.
fn gamut_map_oklch_to_rgb(color: Oklch) -> Rgb {
  let Oklch(l: l, c: original_c, h: h, alpha: alpha) = color

  // Initialize binary search bounds
  let min_chroma = 0.0
  let max_chroma = original_c
  let min_in_gamut = True

  // Get the clipped version of the original color
  let clipped = clip_to_gamut(color)
  let e = delta_e_ok(clipped, color)

  // If already within JND, return the clipped version
  case e <. jnd {
    True -> oklch_to_rgb_clamped(clipped)
    False -> {
      // Binary search for optimal chroma
      let result =
        binary_search_chroma(
          color,
          min_chroma,
          max_chroma,
          min_in_gamut,
          l,
          h,
          alpha,
        )
      oklch_to_rgb_clamped(result)
    }
  }
}

fn binary_search_chroma(
  original: Oklch,
  min_chroma: Float,
  max_chroma: Float,
  min_in_gamut: Bool,
  l: Float,
  h: Float,
  alpha: Float,
) -> Oklch {
  // Check if we've reached the desired precision
  case max_chroma -. min_chroma <=. epsilon {
    True -> {
      let Oklch(h: h, alpha: alpha, ..) = original
      clip_to_gamut(Oklch(l: l, c: min_chroma, h: h, alpha: alpha))
    }
    False -> {
      let chroma = { min_chroma +. max_chroma } /. 2.0
      let current = Oklch(l: l, c: chroma, h: h, alpha: alpha)

      case min_in_gamut {
        True -> {
          // Check if current is in gamut
          case is_in_gamut(current) {
            True -> {
              // Still in gamut, can increase chroma
              binary_search_chroma(
                original,
                chroma,
                max_chroma,
                True,
                l,
                h,
                alpha,
              )
            }
            False -> {
              // Out of gamut, need to reduce
              let clipped = clip_to_gamut(current)
              let e = delta_e_ok(clipped, current)

              case e <. jnd {
                True -> {
                  case jnd -. e <=. epsilon {
                    True -> clipped
                    False ->
                      binary_search_chroma(
                        original,
                        chroma,
                        max_chroma,
                        False,
                        l,
                        h,
                        alpha,
                      )
                  }
                }
                False -> {
                  // E >= JND, reduce max
                  binary_search_chroma(
                    original,
                    min_chroma,
                    chroma,
                    min_in_gamut,
                    l,
                    h,
                    alpha,
                  )
                }
              }
            }
          }
        }
        False -> {
          // min_in_gamut is false, always do local MINDE check
          let clipped = clip_to_gamut(current)
          let e = delta_e_ok(clipped, current)

          case e <. jnd {
            True -> {
              case jnd -. e <=. epsilon {
                True -> clipped
                False ->
                  binary_search_chroma(
                    original,
                    chroma,
                    max_chroma,
                    False,
                    l,
                    h,
                    alpha,
                  )
              }
            }
            False -> {
              // E >= JND, reduce max
              binary_search_chroma(
                original,
                min_chroma,
                chroma,
                min_in_gamut,
                l,
                h,
                alpha,
              )
            }
          }
        }
      }
    }
  }
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

// =============================================================================
// GLEAM_COMMUNITY_COLOUR INTEGRATION
// =============================================================================

/// Convert a gleam_community_colour Colour to OKLCH.
/// This conversion always succeeds.
pub fn from_colour(colour: Colour) -> Oklch {
  let #(r, g, b, a) = colour.to_rgba(colour)
  rgb_to_oklch(Rgb(r: r, g: g, b: b, alpha: a))
}

/// Convert OKLCH to a gleam_community_colour Colour.
pub fn to_colour(oklch_color: Oklch) -> Result(Colour, Nil) {
  let Rgb(r: r, g: g, b: b, alpha: alpha) = oklch_to_rgb(oklch_color)
  colour.from_rgba(r, g, b, alpha)
}
