import oklch/ansi
import oklch/conversion
import oklch/manipulate
import oklch/types
import oklch/util

/// OKLCH color type with Lightness, Chroma, Hue, and Alpha components.
///
/// ## Parameters
/// - `l`: Lightness from 0.0 (black) to 1.0 (white)
/// - `c`: Chroma (saturation) from 0.0 (neutral) to 0.4 (maximum)
/// - `h`: Hue angle in degrees from 0 to 360
/// - `alpha`: Alpha from 0.0 (transparent) to 1.0 (opaque)
pub type Oklch =
  types.Oklch

/// RGB color type with Red, Green, Blue, and Alpha components.
///
/// ## Parameters
/// - `r`: Red channel from 0.0 to 1.0
/// - `g`: Green channel from 0.0 to 1.0
/// - `b`: Blue channel from 0.0 to 1.0
/// - `alpha`: Alpha from 0.0 (transparent) to 1.0 (opaque)
pub type Rgb =
  types.Rgb

/// Error type for parsing hex color strings.
///
/// ## Variants
/// - `InvalidHexLength`: The hex string has an invalid length
/// - `InvalidHexValue`: The hex string contains invalid characters
pub type ParseError =
  types.ParseError

/// Create an OKLCH color with automatic clamping.
///
/// ## Arguments
/// - `l`: Lightness (0.0-1.0, clamped)
/// - `c`: Chroma (0.0-0.4, clamped)
/// - `h`: Hue in degrees (0-360, wrapped)
/// - `alpha`: Alpha (0.0-1.0, clamped)
///
/// ## Example
///     let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
pub fn oklch(l: Float, c: Float, h: Float, alpha: Float) -> Oklch {
  types.oklch(l, c, h, alpha)
}

/// Create an RGB color with automatic clamping.
///
/// ## Arguments
/// - `r`: Red channel (0.0-1.0, clamped)
/// - `g`: Green channel (0.0-1.0, clamped)
/// - `b`: Blue channel (0.0-1.0, clamped)
/// - `alpha`: Alpha (0.0-1.0, clamped)
///
/// ## Example
///     let color = oklch.rgb(1.0, 0.0, 0.0, 1.0)
pub fn rgb(r: Float, g: Float, b: Float, alpha: Float) -> Rgb {
  types.rgb(r, g, b, alpha)
}

/// Create an RGB color from integer values (0-255).
///
/// ## Arguments
/// - `r`: Red channel (0-255, clamped)
/// - `g`: Green channel (0-255, clamped)
/// - `b`: Blue channel (0-255, clamped)
/// - `alpha`: Alpha (0.0-1.0, clamped)
///
/// ## Example
///     let color = oklch.rgb_from_ints(255, 0, 0, 1.0)
pub fn rgb_from_ints(r: Int, g: Int, b: Int, alpha: Float) -> Rgb {
  types.rgb_from_ints(r, g, b, alpha)
}

/// Convert OKLCH color to RGB.
///
/// ## Arguments
/// - `color`: An OKLCH color
///
/// ## Returns
/// An RGB color with values in the sRGB color space.
///
/// ## Example
///     let oklch_color = oklch.oklch(0.6, 0.2, 20.0, 1.0)
///     let rgb_color = oklch.oklch_to_rgb(oklch_color)
pub fn oklch_to_rgb(color: Oklch) -> Rgb {
  conversion.oklch_to_rgb(color)
}

/// Convert RGB color to OKLCH.
///
/// ## Arguments
/// - `color`: An RGB color in sRGB color space
///
/// ## Returns
/// An OKLCH color.
///
/// ## Example
///     let rgb_color = oklch.rgb(1.0, 0.0, 0.0, 1.0)
///     let oklch_color = oklch.rgb_to_oklch(rgb_color)
pub fn rgb_to_oklch(color: Rgb) -> Oklch {
  conversion.rgb_to_oklch(color)
}

/// Convert OKLCH color to hex string.
///
/// ## Arguments
/// - `color`: An OKLCH color
///
/// ## Returns
/// A hex string in the format "#RRGGBB" or "#RRGGBBAA" if alpha < 1.0.
///
/// ## Example
///     let color = oklch.oklch(0.6, 0.2, 20.0, 1.0)
///     let hex = oklch.oklch_to_hex(color)
pub fn oklch_to_hex(color: Oklch) -> String {
  conversion.oklch_to_hex(color)
}

/// Parse a hex string to OKLCH color.
///
/// ## Arguments
/// - `hex`: A hex string (supports #RGB, #RGBA, #RRGGBB, #RRGGBBAA)
///
/// ## Returns
/// `Ok(Oklch)` on success, or `Error(ParseError)` on failure.
///
/// ## Example
///     let result = oklch.hex_to_oklch("#FF0000")
pub fn hex_to_oklch(hex: String) -> Result(Oklch, ParseError) {
  conversion.hex_to_oklch(hex)
}

/// Convert RGB color to hex string.
///
/// ## Arguments
/// - `color`: An RGB color
///
/// ## Returns
/// A hex string in the format "#RRGGBB" or "#RRGGBBAA" if alpha < 1.0.
///
/// ## Example
///     let color = oklch.rgb(1.0, 0.0, 0.0, 1.0)
///     let hex = oklch.rgb_to_hex(color)
pub fn rgb_to_hex(color: Rgb) -> String {
  conversion.rgb_to_hex(color)
}

/// Parse a hex string to RGB color.
///
/// ## Arguments
/// - `hex`: A hex string (supports #RGB, #RGBA, #RRGGBB, #RRGGBBAA)
///
/// ## Returns
/// `Ok(Rgb)` on success, or `Error(ParseError)` on failure.
///
/// ## Example
///     let result = oklch.hex_to_rgb("#FF0000")
pub fn hex_to_rgb(hex: String) -> Result(Rgb, ParseError) {
  conversion.hex_to_rgb(hex)
}

/// Lighten a color by increasing its lightness.
///
/// ## Arguments
/// - `color`: The OKLCH color to lighten
/// - `amount`: The amount to lighten (0.0-1.0)
///
/// ## Returns
/// A new color with increased lightness (clamped to 1.0).
///
/// ## Example
///     let lightened = oklch.lighten(color, 0.2)
pub fn lighten(color: Oklch, amount: Float) -> Oklch {
  manipulate.lighten(color, amount)
}

/// Darken a color by decreasing its lightness.
///
/// ## Arguments
/// - `color`: The OKLCH color to darken
/// - `amount`: The amount to darken (0.0-1.0)
///
/// ## Returns
/// A new color with decreased lightness (clamped to 0.0).
///
/// ## Example
///     let darkened = oklch.darken(color, 0.2)
pub fn darken(color: Oklch, amount: Float) -> Oklch {
  manipulate.darken(color, amount)
}

/// Saturate a color by increasing its chroma.
///
/// ## Arguments
/// - `color`: The OKLCH color to saturate
/// - `amount`: The amount to saturate (0.0-0.4)
///
/// ## Returns
/// A new color with increased chroma (clamped to 0.4).
///
/// ## Example
///     let saturated = oklch.saturate(color, 0.1)
pub fn saturate(color: Oklch, amount: Float) -> Oklch {
  manipulate.saturate(color, amount)
}

/// Desaturate a color by decreasing its chroma.
///
/// ## Arguments
/// - `color`: The OKLCH color to desaturate
/// - `amount`: The amount to desaturate (0.0-0.4)
///
/// ## Returns
/// A new color with decreased chroma (clamped to 0.0).
///
/// ## Example
///     let desaturated = oklch.desaturate(color, 0.1)
pub fn desaturate(color: Oklch, amount: Float) -> Oklch {
  manipulate.desaturate(color, amount)
}

/// Rotate the hue of a color by the given degrees.
///
/// ## Arguments
/// - `color`: The OKLCH color to rotate
/// - `degrees`: Degrees to rotate (positive or negative, wraps around)
///
/// ## Returns
/// A new color with rotated hue (0-360 range).
///
/// ## Example
///     let rotated = oklch.rotate_hue(color, 30.0)
pub fn rotate_hue(color: Oklch, degrees: Float) -> Oklch {
  manipulate.rotate_hue(color, degrees)
}

/// Set the alpha of a color.
///
/// ## Arguments
/// - `color`: The OKLCH color
/// - `alpha`: New alpha value (0.0-1.0, clamped)
///
/// ## Returns
/// A new color with the specified alpha.
///
/// ## Example
///     let transparent = oklch.set_alpha(color, 0.5)
pub fn set_alpha(color: Oklch, alpha: Float) -> Oklch {
  manipulate.set_alpha(color, alpha)
}

/// Set the lightness of a color.
///
/// ## Arguments
/// - `color`: The OKLCH color
/// - `l`: New lightness value (0.0-1.0, clamped)
///
/// ## Returns
/// A new color with the specified lightness.
///
/// ## Example
///     let lighter = oklch.set_l(color, 0.8)
pub fn set_l(color: Oklch, l: Float) -> Oklch {
  manipulate.set_l(color, l)
}

/// Set the chroma (saturation) of a color.
///
/// ## Arguments
/// - `color`: The OKLCH color
/// - `c`: New chroma value (0.0-0.4, clamped)
///
/// ## Returns
/// A new color with the specified chroma.
///
/// ## Example
///     let saturated = oklch.set_c(color, 0.35)
pub fn set_c(color: Oklch, c: Float) -> Oklch {
  manipulate.set_c(color, c)
}

/// Set the hue of a color.
///
/// ## Arguments
/// - `color`: The OKLCH color
/// - `h`: New hue value in degrees (0-360, wrapped)
///
/// ## Returns
/// A new color with the specified hue.
///
/// ## Example
///     let red_hue = oklch.set_h(color, 0.0)
pub fn set_h(color: Oklch, h: Float) -> Oklch {
  manipulate.set_h(color, h)
}

/// Mix two colors together.
///
/// ## Arguments
/// - `color1`: First OKLCH color
/// - `color2`: Second OKLCH color
/// - `weight`: Mix weight (0.0 = color1, 1.0 = color2, 0.5 = equal blend)
///
/// ## Returns
/// A new color that is a blend of the two input colors.
/// The hue interpolates using the shortest path around the color wheel.
///
/// ## Example
///     let blended = oklch.mix(red, blue, 0.5)
pub fn mix(color1: Oklch, color2: Oklch, weight: Float) -> Oklch {
  util.mix(color1, color2, weight)
}

/// Get the relative luminance of a color.
///
/// ## Arguments
/// - `color`: An OKLCH color
///
/// ## Returns
/// The lightness value (L), which represents relative luminance.
/// 0.0 is black, 1.0 is white.
///
/// ## Example
///     let l = oklch.luminance(color)
pub fn luminance(color: Oklch) -> Float {
  util.luminance(color)
}

/// Calculate the WCAG contrast ratio between two colors.
///
/// ## Arguments
/// - `color1`: First OKLCH color
/// - `color2`: Second OKLCH color
///
/// ## Returns
/// The contrast ratio (ranges from 1:1 to 21:1).
/// Higher values mean better contrast.
///
/// ## Example
///     let ratio = oklch.contrast_ratio(black, white)
///     // ratio ≈ 21:1
pub fn contrast_ratio(color1: Oklch, color2: Oklch) -> Float {
  util.contrast_ratio(color1, color2)
}

/// Check if a contrast ratio meets WCAG AA requirements for normal text.
///
/// ## Arguments
/// - `ratio`: A contrast ratio
///
/// ## Returns
/// `True` if ratio >= 4.5:1, `False` otherwise.
///
/// ## Example
///     let passes = oklch.wcag_aa(4.5)
pub fn wcag_aa(ratio: Float) -> Bool {
  util.wcag_aa(ratio)
}

/// Check if a contrast ratio meets WCAG AAA requirements for normal text.
///
/// ## Arguments
/// - `ratio`: A contrast ratio
///
/// ## Returns
/// `True` if ratio >= 7:1, `False` otherwise.
///
/// ## Example
///     let passes = oklch.wcag_aaa(7.0)
pub fn wcag_aaa(ratio: Float) -> Bool {
  util.wcag_aaa(ratio)
}

/// Check if a contrast ratio meets WCAG AA requirements for large text.
///
/// ## Arguments
/// - `ratio`: A contrast ratio
///
/// ## Returns
/// `True` if ratio >= 3:1, `False` otherwise.
///
/// ## Example
///     let passes = oklch.wcag_aa_large_text(3.0)
pub fn wcag_aa_large_text(ratio: Float) -> Bool {
  util.wcag_aa_large_text(ratio)
}

/// Check if a contrast ratio meets WCAG AAA requirements for large text.
///
/// ## Arguments
/// - `ratio`: A contrast ratio
///
/// ## Returns
/// `True` if ratio >= 4.5:1, `False` otherwise.
///
/// ## Example
///     let passes = oklch.wcag_aaa_large_text(4.5)
pub fn wcag_aaa_large_text(ratio: Float) -> Bool {
  util.wcag_aaa_large_text(ratio)
}

/// Wrap text in ANSI escape codes for foreground color.
///
/// ## Arguments
/// - `color`: An OKLCH color
/// - `text`: The text to colorize
///
/// ## Returns
/// The text wrapped with ANSI 24-bit color escape codes.
///
/// ## Example
///     io.println(oklch.ansi(red, "Hello, World!"))
pub fn ansi(color: Oklch, text: String) -> String {
  ansi.ansi(color, text)
}

/// Wrap text in ANSI escape codes for background color.
///
/// ## Arguments
/// - `color`: An OKLCH color
/// - `text`: The text to colorize
///
/// ## Returns
/// The text wrapped with ANSI 24-bit background color escape codes.
///
/// ## Example
///     io.println(oklch.ansi_bg(blue, "Hello, World!"))
pub fn ansi_bg(color: Oklch, text: String) -> String {
  ansi.ansi_bg(color, text)
}

/// Wrap text in ANSI escape codes for both foreground and background color.
///
/// ## Arguments
/// - `fg`: Foreground OKLCH color
/// - `bg`: Background OKLCH color
/// - `text`: The text to colorize
///
/// ## Returns
/// The text wrapped with ANSI 24-bit color escape codes.
///
/// ## Example
///     io.println(oklch.ansi_fg_bg(white, blue, "Hello"))
pub fn ansi_fg_bg(fg: Oklch, bg: Oklch, text: String) -> String {
  ansi.ansi_fg_bg(fg, bg, text)
}
