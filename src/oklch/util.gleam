import oklch/types.{type Oklch, Oklch}

pub fn mix(color1: Oklch, color2: Oklch, weight: Float) -> Oklch {
  let Oklch(l: l1, c: c1, h: h1, alpha: a1) = color1
  let Oklch(l: l2, c: c2, h: h2, alpha: a2) = color2

  let weight = case weight <. 0.0 {
    True -> 0.0
    False ->
      case weight >. 1.0 {
        True -> 1.0
        False -> weight
      }
  }

  let w1 = 1.0 -. weight
  let w2 = weight

  let l = l1 *. w1 +. l2 *. w2
  let c = c1 *. w1 +. c2 *. w2
  let h = lerp_angle(h1, h2, weight)
  let alpha = a1 *. w1 +. a2 *. w2

  Oklch(l: l, c: c, h: h, alpha: alpha)
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

pub fn luminance(color: Oklch) -> Float {
  let Oklch(l: l, c: _, h: _, alpha: _) = color
  l
}

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

pub fn wcag_aa(ratio: Float) -> Bool {
  ratio >=. 4.5
}

pub fn wcag_aaa(ratio: Float) -> Bool {
  ratio >=. 7.0
}

pub fn wcag_aa_large_text(ratio: Float) -> Bool {
  ratio >=. 3.0
}

pub fn wcag_aaa_large_text(ratio: Float) -> Bool {
  ratio >=. 4.5
}
