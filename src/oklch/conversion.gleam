/// Color conversion functions between OKLCH, RGB, and hex formats.
/// 
/// Uses the OKLAB color space matrices from CSS Color Module Level 4 spec
/// with proper sRGB gamma correction.
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import oklch/types.{
  type Oklch, type ParseError, type Rgb, InvalidHexLength, InvalidHexValue,
  Oklch, Rgb,
}

const pi = 3.141592653589793

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
  let c = float.square_root(a_val *. a_val +. b_val *. b_val)
  let c = case c {
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

pub fn oklch_to_hex(color: Oklch) -> String {
  let rgb = oklch_to_rgb(color)
  rgb_to_hex(rgb)
}

pub fn hex_to_oklch(hex: String) -> Result(Oklch, ParseError) {
  case hex_to_rgb(hex) {
    Ok(rgb) -> Ok(rgb_to_oklch(rgb))
    Error(e) -> Error(e)
  }
}

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
      Ok(types.rgb_from_ints(r, g, b, int.to_float(a) /. 255.0))
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
      let tmp = float.power(c, 1.0 /. 3.0)
      let tmp = case tmp {
        Ok(v) -> v
        Error(_) -> 0.0
      }
      let c = tmp *. 1.055 -. 0.055
      case c >. 1.0 {
        True -> 1.0
        False -> c
      }
    }
  }
}

@external(erlang, "math", "cos")
@external(javascript, "Math", "cos")
pub fn cos(x: Float) -> Float

@external(erlang, "math", "sin")
@external(javascript, "Math", "sin")
pub fn sin(x: Float) -> Float

@external(erlang, "math", "atan2")
@external(javascript, "Math", "atan2")
pub fn atan2(y: Float, x: Float) -> Float
