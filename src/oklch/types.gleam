import gleam/float
import gleam/int

pub type Oklch {
  Oklch(l: Float, c: Float, h: Float, alpha: Float)
}

pub type Rgb {
  Rgb(r: Float, g: Float, b: Float, alpha: Float)
}

pub type ParseError {
  InvalidHexLength
  InvalidHexValue
  InvalidChannelValue
}

pub fn oklch(l: Float, c: Float, h: Float, alpha: Float) -> Oklch {
  Oklch(l: clamp_l(l), c: clamp_c(c), h: clamp_h(h), alpha: clamp_alpha(alpha))
}

pub fn rgb(r: Float, g: Float, b: Float, alpha: Float) -> Rgb {
  Rgb(
    r: clamp_channel(r),
    g: clamp_channel(g),
    b: clamp_channel(b),
    alpha: clamp_alpha(alpha),
  )
}

pub fn rgb_from_ints(r: Int, g: Int, b: Int, alpha: Float) -> Rgb {
  let r = case r < 0 {
    True -> 0
    False ->
      case r > 255 {
        True -> 255
        False -> r
      }
  }
  let g = case g < 0 {
    True -> 0
    False ->
      case g > 255 {
        True -> 255
        False -> g
      }
  }
  let b = case b < 0 {
    True -> 0
    False ->
      case b > 255 {
        True -> 255
        False -> b
      }
  }
  Rgb(
    r: int_to_float(r) /. 255.0,
    g: int_to_float(g) /. 255.0,
    b: int_to_float(b) /. 255.0,
    alpha: clamp_alpha(alpha),
  )
}

fn clamp_l(l: Float) -> Float {
  case l <. 0.0 {
    True -> 0.0
    False ->
      case l >. 1.0 {
        True -> 1.0
        False -> l
      }
  }
}

fn clamp_c(c: Float) -> Float {
  case c <. 0.0 {
    True -> 0.0
    False ->
      case c >. 0.4 {
        True -> 0.4
        False -> c
      }
  }
}

fn clamp_h(h: Float) -> Float {
  let normalized = float_modulo(h, 360.0)
  case normalized <. 0.0 {
    True -> normalized +. 360.0
    False -> normalized
  }
}

fn clamp_alpha(alpha: Float) -> Float {
  case alpha <. 0.0 {
    True -> 0.0
    False ->
      case alpha >. 1.0 {
        True -> 1.0
        False -> alpha
      }
  }
}

fn clamp_channel(c: Float) -> Float {
  case c <. 0.0 {
    True -> 0.0
    False ->
      case c >. 1.0 {
        True -> 1.0
        False -> c
      }
  }
}

fn int_to_float(i: Int) -> Float {
  i |> int.to_float
}

fn float_modulo(a: Float, b: Float) -> Float {
  let quotient = a /. b
  let truncated = float.floor(quotient)
  a -. truncated *. b
}
