import oklch/ansi
import oklch/conversion
import oklch/manipulate
import oklch/types
import oklch/util

pub type Oklch =
  types.Oklch

pub type Rgb =
  types.Rgb

pub type ParseError =
  types.ParseError

pub fn oklch(l: Float, c: Float, h: Float, alpha: Float) -> Oklch {
  types.oklch(l, c, h, alpha)
}

pub fn rgb(r: Float, g: Float, b: Float, alpha: Float) -> Rgb {
  types.rgb(r, g, b, alpha)
}

pub fn rgb_from_ints(r: Int, g: Int, b: Int, alpha: Float) -> Rgb {
  types.rgb_from_ints(r, g, b, alpha)
}

pub fn oklch_to_rgb(color: Oklch) -> Rgb {
  conversion.oklch_to_rgb(color)
}

pub fn rgb_to_oklch(color: Rgb) -> Oklch {
  conversion.rgb_to_oklch(color)
}

pub fn oklch_to_hex(color: Oklch) -> String {
  conversion.oklch_to_hex(color)
}

pub fn hex_to_oklch(hex: String) -> Result(Oklch, ParseError) {
  conversion.hex_to_oklch(hex)
}

pub fn rgb_to_hex(color: Rgb) -> String {
  conversion.rgb_to_hex(color)
}

pub fn hex_to_rgb(hex: String) -> Result(Rgb, ParseError) {
  conversion.hex_to_rgb(hex)
}

pub fn lighten(color: Oklch, amount: Float) -> Oklch {
  manipulate.lighten(color, amount)
}

pub fn darken(color: Oklch, amount: Float) -> Oklch {
  manipulate.darken(color, amount)
}

pub fn saturate(color: Oklch, amount: Float) -> Oklch {
  manipulate.saturate(color, amount)
}

pub fn desaturate(color: Oklch, amount: Float) -> Oklch {
  manipulate.desaturate(color, amount)
}

pub fn rotate_hue(color: Oklch, degrees: Float) -> Oklch {
  manipulate.rotate_hue(color, degrees)
}

pub fn set_alpha(color: Oklch, alpha: Float) -> Oklch {
  manipulate.set_alpha(color, alpha)
}

pub fn set_l(color: Oklch, l: Float) -> Oklch {
  manipulate.set_l(color, l)
}

pub fn set_c(color: Oklch, c: Float) -> Oklch {
  manipulate.set_c(color, c)
}

pub fn set_h(color: Oklch, h: Float) -> Oklch {
  manipulate.set_h(color, h)
}

pub fn mix(color1: Oklch, color2: Oklch, weight: Float) -> Oklch {
  util.mix(color1, color2, weight)
}

pub fn luminance(color: Oklch) -> Float {
  util.luminance(color)
}

pub fn contrast_ratio(color1: Oklch, color2: Oklch) -> Float {
  util.contrast_ratio(color1, color2)
}

pub fn wcag_aa(ratio: Float) -> Bool {
  util.wcag_aa(ratio)
}

pub fn wcag_aaa(ratio: Float) -> Bool {
  util.wcag_aaa(ratio)
}

pub fn wcag_aa_large_text(ratio: Float) -> Bool {
  util.wcag_aa_large_text(ratio)
}

pub fn wcag_aaa_large_text(ratio: Float) -> Bool {
  util.wcag_aaa_large_text(ratio)
}

pub fn ansi(color: Oklch, text: String) -> String {
  ansi.ansi(color, text)
}

pub fn ansi_bg(color: Oklch, text: String) -> String {
  ansi.ansi_bg(color, text)
}

pub fn ansi_fg_bg(fg: Oklch, bg: Oklch, text: String) -> String {
  ansi.ansi_fg_bg(fg, bg, text)
}
