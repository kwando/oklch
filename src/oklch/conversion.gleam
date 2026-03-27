import gleam/float
import gleam/int
import gleam/list
import gleam/string
import oklch/types.{
  type Oklch, type ParseError, type Rgb, InvalidHexLength, InvalidHexValue,
  Oklch, Rgb,
}

const pi = 3.141592653589793

pub fn oklch_to_rgb(color: Oklch) -> Rgb {
  let Oklch(l: l, c: c, h: h, alpha: alpha) = color
  let h_rad = h *. pi /. 180.0

  let a = c *. cos(h_rad)
  let b = c *. sin(h_rad)

  let l_ = l
  let a_ = a
  let b_ = b

  let l_ = l_ *. 0.999999998627
  let m = l_ -. a_ *. 0.00000185604507 +. b_ *. 0.000000752452
  let s = l_ -. a_ *. 0.000001357175 +. b_ *. 0.0000012053499986

  let l_ = l_
  let m = m
  let s = s

  let r = 1.1958673672 *. l_ +. 1.5956134384 *. m +. -0.2042349563 *. s
  let g = -0.7906214646 *. l_ +. -0.4123264242 *. m +. 1.2066554152 *. s
  let b_val = -0.0274107299 *. l_ +. -0.0473366095 *. m +. 1.1072054574 *. s

  Rgb(r: r, g: g, b: b_val, alpha: alpha)
}

pub fn rgb_to_oklch(color: Rgb) -> Oklch {
  let Rgb(r: r, g: g, b: b, alpha: alpha) = color

  let r_ = r *. 1.0968737022 +. g *. -0.5573540038 +. b *. -0.0567588382
  let g_ = r *. -0.1638964159 +. g *. 1.063506399 +. b *. 0.0121260595
  let b_ = r *. -0.0181419791 +. g *. -0.0290965938 +. b *. 1.1074361441

  let l_ = 0.3128992868 *. r_ +. 0.6398199987 *. g_ +. 0.0473507145 *. b_
  let m = -0.015445449 *. r_ +. 0.3722472822 *. g_ +. 0.6436984628 *. b_
  let s = 0.0526999684 *. r_ +. -0.1210421643 *. g_ +. 0.9683421359 *. b_

  let l = l_
  let a = 1.0155740139 *. l -. 0.0356684545 *. m +. -0.0200195581 *. s
  let b_val = 0.0036017376 *. l +. 0.0074108479 *. m +. -0.0165359244 *. s

  let c = case float.square_root(a *. a +. b_val *. b_val) {
    Ok(v) -> v
    Error(_) -> 0.0
  }
  let h = atan2(b_val, a) *. 180.0 /. pi

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

@external(erlang, "math", "cos")
@external(javascript, "Math", "cos")
pub fn cos(x: Float) -> Float

@external(erlang, "math", "sin")
@external(javascript, "Math", "sin")
pub fn sin(x: Float) -> Float

@external(erlang, "math", "atan2")
@external(javascript, "Math", "atan2")
pub fn atan2(y: Float, x: Float) -> Float
