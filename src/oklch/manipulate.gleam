/// Color manipulation functions for OKLCH colors.
import gleam/float
import oklch/types.{type Oklch, Oklch}

/// Lighten a color by increasing lightness.
/// Clamps to 1.0 if the result exceeds.
pub fn lighten(color: Oklch, amount: Float) -> Oklch {
  let Oklch(l: l, c: c, h: h, alpha: alpha) = color
  let new_l = l +. amount
  let new_l = case new_l >. 1.0 {
    True -> 1.0
    False -> new_l
  }
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
  let alpha = case alpha <. 0.0 {
    True -> 0.0
    False ->
      case alpha >. 1.0 {
        True -> 1.0
        False -> alpha
      }
  }
  Oklch(l: l, c: c, h: h, alpha: alpha)
}

/// Set the lightness channel.
pub fn set_l(color: Oklch, l: Float) -> Oklch {
  let Oklch(l: _, c: c, h: h, alpha: alpha) = color
  let l = case l <. 0.0 {
    True -> 0.0
    False ->
      case l >. 1.0 {
        True -> 1.0
        False -> l
      }
  }
  Oklch(l: l, c: c, h: h, alpha: alpha)
}

/// Set the chroma (saturation) channel.
pub fn set_c(color: Oklch, c: Float) -> Oklch {
  let Oklch(l: l, c: _, h: h, alpha: alpha) = color
  let c = case c <. 0.0 {
    True -> 0.0
    False ->
      case c >. 0.4 {
        True -> 0.4
        False -> c
      }
  }
  Oklch(l: l, c: c, h: h, alpha: alpha)
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
