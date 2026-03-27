import gleam/float
import gleam/int
import oklch/conversion
import oklch/types.{type Oklch, Rgb}

const ansi_reset = "\u{001b}[0m"

const ansi_fg_prefix = "\u{001b}[38;2;"

const ansi_bg_prefix = "\u{001b}[48;2;"

pub fn ansi(color: Oklch, text: String) -> String {
  let rgb = conversion.oklch_to_rgb(color)
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

pub fn ansi_bg(color: Oklch, text: String) -> String {
  let rgb = conversion.oklch_to_rgb(color)
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

pub fn ansi_fg_bg(fg: Oklch, bg: Oklch, text: String) -> String {
  let fg_rgb = conversion.oklch_to_rgb(fg)
  let Rgb(r: fg_r, g: fg_g, b: fg_b, alpha: _) = fg_rgb

  let bg_rgb = conversion.oklch_to_rgb(bg)
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

fn float_to_256(f: Float) -> Int {
  let f = case f <. 0.0 {
    True -> 0.0
    False ->
      case f >. 1.0 {
        True -> 1.0
        False -> f
      }
  }
  f *. 255.0 |> float.round
}
