import gleam/float
import gleam/result
import gleam/string
import gleam_community/colour
import gleeunit
import niji.{Oklch, Rgb}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn oklch_type_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = color
  assert l == 0.5
  assert c == 0.2
  assert h == 180.0
  assert alpha == 1.0
}

pub fn oklch_clamp_l_test() {
  let color = niji.oklch(1.5, 0.2, 180.0, 1.0)
  let Oklch(l: l, ..) = color
  assert l == 1.0

  let color = niji.oklch(-0.5, 0.2, 180.0, 1.0)
  let Oklch(l: l, ..) = color
  assert l == 0.0
}

pub fn oklch_clamp_c_test() {
  // High chroma values are NOT clamped (CSS allows values > 0.4)
  let color = niji.oklch(0.5, 0.5, 180.0, 1.0)
  let Oklch(c: c, ..) = color
  assert c == 0.5

  // Negative chroma is still clamped to 0.0
  let color = niji.oklch(0.5, -0.1, 180.0, 1.0)
  let Oklch(c: c, ..) = color
  assert c == 0.0
}

pub fn oklch_clamp_h_test() {
  let color = niji.oklch(0.5, 0.2, 400.0, 1.0)
  let Oklch(h: h, ..) = color
  assert h == 40.0

  let color = niji.oklch(0.5, 0.2, -30.0, 1.0)
  let Oklch(h: h, ..) = color
  assert h == 330.0
}

pub fn oklch_clamp_alpha_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.5)
  let Oklch(alpha: alpha, ..) = color
  assert alpha == 1.0

  let color = niji.oklch(0.5, 0.2, 180.0, -0.1)
  let Oklch(alpha: alpha, ..) = color
  assert alpha == 0.0
}

pub fn rgb_type_test() {
  let color = niji.rgb(0.5, 0.6, 0.7, 1.0)
  let Rgb(r: r, g: g, b: b, alpha: alpha) = color
  assert r == 0.5
  assert g == 0.6
  assert b == 0.7
  assert alpha == 1.0
}

pub fn rgb_from_ints_test() {
  let color = niji.rgb_from_ints(255, 128, 64, 1.0)
  let Rgb(r: r, g: g, b: b, ..) = color
  assert float.loosely_equals(r, with: 1.0, tolerating: 0.01)
  assert float.loosely_equals(g, with: 0.502, tolerating: 0.01)
  assert float.loosely_equals(b, with: 0.251, tolerating: 0.01)
}

pub fn oklch_to_rgb_basic_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let rgb = niji.to_rgb(color)
  let Rgb(r: _, g: _, b: _, alpha: alpha) = rgb
  assert alpha == 1.0
}

pub fn rgb_to_oklch_basic_test() {
  let color = niji.rgb(0.5, 0.6, 0.7, 1.0)
  let niji_color = niji.rgb_to_oklch(color)
  let Oklch(l: l, c: c, h: _h, alpha: alpha) = niji_color
  assert alpha == 1.0
  assert l >=. 0.0
  assert l <=. 1.0
  assert c >=. 0.0
  assert c <=. 0.45
}

pub fn round_trip_oklch_rgb_test() {
  let original = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let rgb = niji.to_rgb(original)
  let result = niji.rgb_to_oklch(rgb)
  let Oklch(l: _l, c: _c, h: _h, alpha: alpha) = result

  assert float.loosely_equals(alpha, with: 1.0, tolerating: 0.001)
}

pub fn oklch_to_hex_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let hex = niji.to_hex(color)
  assert string.length(hex) == 7
}

pub fn rgb_to_hex_test() {
  let color = niji.rgb(1.0, 0.0, 0.0, 1.0)
  let hex = niji.rgb_to_hex(color)
  assert hex == "#FF0000"
}

pub fn rgb_to_hex_alpha_padding_test() {
  let color = niji.rgb(1.0, 0.0, 0.0, 0.03)
  let hex = niji.rgb_to_hex(color)
  assert hex == "#FF000008"
}

pub fn lighten_test() {
  let color = niji.oklch(0.3, 0.2, 180.0, 1.0)
  let lightened = niji.lighten(color, 0.2)
  let Oklch(l: l, ..) = lightened
  assert float.loosely_equals(l, with: 0.5, tolerating: 0.001)
}

pub fn darken_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let darkened = niji.darken(color, 0.2)
  let Oklch(l: l, ..) = darkened
  assert float.loosely_equals(l, with: 0.3, tolerating: 0.001)
}

pub fn saturate_test() {
  let color = niji.oklch(0.5, 0.1, 180.0, 1.0)
  let saturated = niji.saturate(color, 0.1)
  let Oklch(c: c, ..) = saturated
  assert float.loosely_equals(c, with: 0.2, tolerating: 0.001)

  // Saturation has no upper bound (can exceed 0.4)
  let color = niji.oklch(0.5, 0.3, 180.0, 1.0)
  let saturated = niji.saturate(color, 0.3)
  let Oklch(c: c, ..) = saturated
  assert float.loosely_equals(c, with: 0.6, tolerating: 0.001)
}

pub fn desaturate_test() {
  let color = niji.oklch(0.5, 0.3, 180.0, 1.0)
  let desaturated = niji.desaturate(color, 0.1)
  let Oklch(c: c, ..) = desaturated
  assert float.loosely_equals(c, with: 0.2, tolerating: 0.001)
}

pub fn rotate_hue_test() {
  let color = niji.oklch(0.5, 0.2, 0.0, 1.0)
  let rotated = niji.rotate_hue(color, 90.0)
  let Oklch(h: h, ..) = rotated
  assert float.loosely_equals(h, with: 90.0, tolerating: 0.001)
}

pub fn rotate_hue_wrap_test() {
  let color = niji.oklch(0.5, 0.2, 350.0, 1.0)
  let rotated = niji.rotate_hue(color, 30.0)
  let Oklch(h: h, ..) = rotated
  assert float.loosely_equals(h, with: 20.0, tolerating: 0.001)
}

pub fn set_alpha_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let result = niji.set_alpha(color, 0.5)
  let Oklch(alpha: alpha, ..) = result
  assert alpha == 0.5
}

pub fn set_l_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let result = niji.set_l(color, 0.8)
  let Oklch(l: l, ..) = result
  assert l == 0.8
}

pub fn set_c_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let result = niji.set_c(color, 0.35)
  let Oklch(c: c, ..) = result
  assert c == 0.35

  // Values above 0.4 are allowed (no upper clamp)
  let result = niji.set_c(color, 0.6)
  let Oklch(c: c, ..) = result
  assert c == 0.6

  // Negative values clamp to 0.0
  let result = niji.set_c(color, -0.1)
  let Oklch(c: c, ..) = result
  assert c == 0.0
}

pub fn set_h_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let result = niji.set_h(color, 270.0)
  let Oklch(h: h, ..) = result
  assert h == 270.0
}

pub fn mix_test() {
  let color1 = niji.oklch(0.5, 0.2, 0.0, 1.0)
  let color2 = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let mixed = niji.mix(color1, color2, 0.5)
  let Oklch(l: l, ..) = mixed
  assert float.loosely_equals(l, with: 0.5, tolerating: 0.001)
}

pub fn mix_weight_0_test() {
  let color1 = niji.oklch(0.5, 0.2, 0.0, 1.0)
  let color2 = niji.oklch(0.8, 0.3, 180.0, 1.0)
  let mixed = niji.mix(color1, color2, 0.0)
  let Oklch(l: l, ..) = mixed
  assert float.loosely_equals(l, with: 0.5, tolerating: 0.001)
}

pub fn mix_weight_1_test() {
  let color1 = niji.oklch(0.5, 0.2, 0.0, 1.0)
  let color2 = niji.oklch(0.8, 0.3, 180.0, 1.0)
  let mixed = niji.mix(color1, color2, 1.0)
  let Oklch(l: l, ..) = mixed
  assert float.loosely_equals(l, with: 0.8, tolerating: 0.001)
}

pub fn luminance_test() {
  let color = niji.oklch(0.7, 0.2, 180.0, 1.0)
  let l = niji.luminance(color)
  assert l == 0.7
}

pub fn contrast_ratio_test() {
  let color1 = niji.oklch(0.95, 0.0, 0.0, 1.0)
  let color2 = niji.oklch(0.1, 0.0, 0.0, 1.0)
  let ratio = niji.contrast_ratio(color1, color2)
  assert ratio >. 5.0
}

pub fn wcag_aa_pass_test() {
  assert niji.wcag_aa(4.5) == True
  assert niji.wcag_aa(4.4) == False
}

pub fn wcag_aaa_pass_test() {
  assert niji.wcag_aaa(7.0) == True
  assert niji.wcag_aaa(6.9) == False
}

pub fn wcag_aa_large_text_pass_test() {
  assert niji.wcag_aa_large_text(3.0) == True
  assert niji.wcag_aa_large_text(2.9) == False
}

pub fn wcag_aaa_large_text_pass_test() {
  assert niji.wcag_aaa_large_text(4.5) == True
  assert niji.wcag_aaa_large_text(4.4) == False
}

pub fn ansi_fg_test() {
  let color = niji.oklch(0.6, 0.2, 180.0, 1.0)
  let result = niji.ansi(color, "Hello")
  assert string.contains(result, "Hello")
  assert string.contains(result, "\u{001b}[38;2;")
  assert string.contains(result, "\u{001b}[0m")
}

pub fn ansi_bg_test() {
  let color = niji.oklch(0.6, 0.2, 180.0, 1.0)
  let result = niji.ansi_bg(color, "Hello")
  assert string.contains(result, "Hello")
  assert string.contains(result, "\u{001b}[48;2;")
  assert string.contains(result, "\u{001b}[0m")
}

pub fn ansi_fg_bg_test() {
  let fg = niji.oklch(0.6, 0.2, 180.0, 1.0)
  let bg = niji.oklch(0.95, 0.0, 0.0, 1.0)
  let result = niji.ansi_fg_bg(fg, bg, "Hello")
  assert string.contains(result, "Hello")
  assert string.contains(result, "\u{001b}[38;2;")
  assert string.contains(result, "\u{001b}[48;2;")
  assert string.contains(result, "\u{001b}[0m")
}

pub fn ansi_black_and_white_test() {
  let black = niji.oklch(0.0, 0.0, 0.0, 1.0)
  let white = niji.oklch(1.0, 0.0, 0.0, 1.0)

  let result = niji.ansi_fg_bg(black, white, "X")
  assert string.contains(result, "X")
  assert string.contains(result, "\u{001b}[38;2;")
  assert string.contains(result, "\u{001b}[48;2;")
}

pub fn from_colour_test() {
  let niji_color = niji.from_colour(colour.red)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = niji_color
  assert alpha == 1.0
  assert l >. 0.0
  assert l <. 1.0
  assert c >=. 0.0
  assert h >=. 0.0
  assert h <. 360.0
}

pub fn to_colour_test() {
  let niji_color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let result = niji.to_colour(niji_color)
  assert result |> result.is_ok
}

pub fn round_trip_colour_test() {
  let original = colour.light_blue
  let niji_color = niji.from_colour(original)
  let assert Ok(converted_back) = niji.to_colour(niji_color)
  let #(r1, g1, b1, a1) = colour.to_rgba(original)
  let #(r2, g2, b2, a2) = colour.to_rgba(converted_back)
  assert float.loosely_equals(r1, with: r2, tolerating: 0.01)
  assert float.loosely_equals(g1, with: g2, tolerating: 0.01)
  assert float.loosely_equals(b1, with: b2, tolerating: 0.01)
  assert float.loosely_equals(a1, with: a2, tolerating: 0.001)
}

// =============================================================================
// HIGH CHROMA TESTS (no upper clamp)
// =============================================================================

pub fn high_chroma_test() {
  let color = niji.oklch(0.5, 0.6, 180.0, 1.0)
  let Oklch(c: c, ..) = color
  assert c == 0.6
}

pub fn very_high_chroma_test() {
  let color = niji.oklch(0.5, 1.0, 180.0, 1.0)
  let Oklch(c: c, ..) = color
  assert c == 1.0
}

// =============================================================================
// HAS_HUE TESTS
// =============================================================================

pub fn has_hue_with_chroma_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  assert niji.has_hue(color) == True
}

pub fn has_hue_no_chroma_test() {
  let color = niji.oklch(0.5, 0.0, 180.0, 1.0)
  // Gray color has no meaningful hue
  assert niji.has_hue(color) == False
}

pub fn has_hue_almost_zero_chroma_test() {
  let color = niji.oklch(0.5, 0.0001, 180.0, 1.0)
  // Very small chroma still has a hue
  assert niji.has_hue(color) == True
}

// =============================================================================
// CSS SERIALIZATION TESTS
// =============================================================================

pub fn oklch_to_css_basic_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let css = niji.to_css(color)
  assert css == "oklch(50% 0.2 180deg)"
}

pub fn oklch_to_css_high_chroma_test() {
  // Chroma can exceed 0.4 (no clamping)
  let color = niji.oklch(0.5, 0.6, 180.0, 1.0)
  let css = niji.to_css(color)
  assert css == "oklch(50% 0.6 180deg)"
}

pub fn oklch_to_css_with_alpha_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 0.5)
  let css = niji.to_css(color)
  assert css == "oklch(50% 0.2 180deg / 0.5)"
}

pub fn oklch_to_css_no_hue_test() {
  // Gray color has no hue, outputs "none"
  let color = niji.oklch(0.5, 0.0, 0.0, 1.0)
  let css = niji.to_css(color)
  assert css == "oklch(50% 0 none)"
}

pub fn oklch_to_css_no_hue_with_alpha_test() {
  let color = niji.oklch(0.5, 0.0, 0.0, 0.5)
  let css = niji.to_css(color)
  assert css == "oklch(50% 0 none / 0.5)"
}

pub fn oklch_to_css_white_test() {
  let color = niji.oklch(1.0, 0.0, 0.0, 1.0)
  let css = niji.to_css(color)
  assert css == "oklch(100% 0 none)"
}

pub fn oklch_to_css_black_test() {
  let color = niji.oklch(0.0, 0.0, 0.0, 1.0)
  let css = niji.to_css(color)
  assert css == "oklch(0% 0 none)"
}

pub fn oklch_to_css_precision_test() {
  // Test with values that require rounding
  let color = niji.oklch(0.7534, 0.2567, 45.3, 1.0)
  let css = niji.to_css(color)
  assert css == "oklch(75% 0.26 45deg)"
}

pub fn oklch_to_css_leading_zero_chroma_test() {
  let color = niji.oklch(0.5, 0.05, 180.0, 1.0)
  let css = niji.to_css(color)
  assert css == "oklch(50% 0.05 180deg)"
}

pub fn oklch_to_css_leading_zero_alpha_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 0.05)
  let css = niji.to_css(color)
  assert css == "oklch(50% 0.2 180deg / 0.05)"
}

pub fn rotate_hue_large_negative_test() {
  let color = niji.oklch(0.5, 0.2, 10.0, 1.0)
  let rotated = niji.rotate_hue(color, -730.0)
  let Oklch(h: h, ..) = rotated
  assert float.loosely_equals(h, with: 0.0, tolerating: 0.001)
}

pub fn set_h_large_negative_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let updated = niji.set_h(color, -725.0)
  let Oklch(h: h, ..) = updated
  assert float.loosely_equals(h, with: 355.0, tolerating: 0.001)
}

pub fn rgb_to_oklch_red_reference_test() {
  let color = niji.rgb(1.0, 0.0, 0.0, 1.0)
  let converted = niji.rgb_to_oklch(color)
  assert float.loosely_equals(converted.l, with: 0.628, tolerating: 0.003)
  assert float.loosely_equals(converted.c, with: 0.258, tolerating: 0.003)
  assert float.loosely_equals(converted.h, with: 29.23, tolerating: 0.2)
}

pub fn rgb_to_oklch_green_reference_test() {
  let color = niji.rgb(0.0, 1.0, 0.0, 1.0)
  let converted = niji.rgb_to_oklch(color)
  assert float.loosely_equals(converted.l, with: 0.866, tolerating: 0.003)
  assert float.loosely_equals(converted.c, with: 0.295, tolerating: 0.003)
  assert float.loosely_equals(converted.h, with: 142.5, tolerating: 0.3)
}

pub fn rgb_to_oklch_blue_reference_test() {
  let color = niji.rgb(0.0, 0.0, 1.0, 1.0)
  let converted = niji.rgb_to_oklch(color)
  assert float.loosely_equals(converted.l, with: 0.452, tolerating: 0.003)
  assert float.loosely_equals(converted.c, with: 0.313, tolerating: 0.003)
  assert float.loosely_equals(converted.h, with: 264.05, tolerating: 0.3)
}

pub fn rgb_round_trip_reference_test() {
  let original = niji.rgb(0.2, 0.4, 0.9, 1.0)
  let converted = original |> niji.rgb_to_oklch |> niji.to_rgb
  assert float.loosely_equals(converted.r, with: 0.2, tolerating: 0.01)
  assert float.loosely_equals(converted.g, with: 0.4, tolerating: 0.01)
  assert float.loosely_equals(converted.b, with: 0.9, tolerating: 0.01)
}

// =============================================================================
// PALETTE HELPER TESTS
// =============================================================================

pub fn complementary_test() {
  let color = niji.oklch(0.5, 0.2, 350.0, 0.8)
  let result = niji.complementary(color)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = result
  assert float.loosely_equals(l, with: 0.5, tolerating: 0.001)
  assert float.loosely_equals(c, with: 0.2, tolerating: 0.001)
  assert float.loosely_equals(h, with: 170.0, tolerating: 0.001)
  assert float.loosely_equals(alpha, with: 0.8, tolerating: 0.001)
}

pub fn triadic_test() {
  let color = niji.oklch(0.6, 0.15, 10.0, 1.0)
  let #(a, b) = niji.triadic(color)
  assert float.loosely_equals(a.h, with: 130.0, tolerating: 0.001)
  assert float.loosely_equals(b.h, with: 250.0, tolerating: 0.001)
}

pub fn split_complementary_test() {
  let color = niji.oklch(0.5, 0.2, 20.0, 1.0)
  let #(a, b) = niji.split_complementary(color, 30.0)
  assert float.loosely_equals(a.h, with: 170.0, tolerating: 0.001)
  assert float.loosely_equals(b.h, with: 230.0, tolerating: 0.001)
}

pub fn analogous_test() {
  let color = niji.oklch(0.5, 0.2, 10.0, 1.0)
  let #(a, b) = niji.analogous(color, 30.0)
  assert float.loosely_equals(a.h, with: 340.0, tolerating: 0.001)
  assert float.loosely_equals(b.h, with: 40.0, tolerating: 0.001)
}

// =============================================================================
// PUBLIC GAMUT + DISTANCE TESTS
// =============================================================================

pub fn in_gamut_test() {
  let inside = niji.oklch(0.5, 0.05, 180.0, 1.0)
  let outside = niji.oklch(0.5, 0.6, 180.0, 1.0)
  assert niji.in_gamut(inside)
  assert !niji.in_gamut(outside)
}

pub fn gamut_map_test() {
  let outside = niji.oklch(0.5, 0.6, 180.0, 0.7)
  let mapped = niji.gamut_map(outside)
  assert niji.in_gamut(mapped)
  assert float.loosely_equals(mapped.alpha, with: 0.7, tolerating: 0.001)
}

pub fn distance_test() {
  let a = niji.oklch(0.5, 0.2, 120.0, 1.0)
  let b = niji.oklch(0.5, 0.2, 120.0, 1.0)
  let c = niji.oklch(0.6, 0.25, 200.0, 1.0)

  let d_ab = niji.distance(a, b)
  let d_ac = niji.distance(a, c)
  let d_ca = niji.distance(c, a)

  assert float.loosely_equals(d_ab, with: 0.0, tolerating: 0.000001)
  assert d_ac >. 0.0
  assert float.loosely_equals(d_ac, with: d_ca, tolerating: 0.000001)
}

// =============================================================================
// GAMUT MAPPING TESTS
// =============================================================================

pub fn oklch_to_rgb_in_gamut_test() {
  // Color already in gamut should return reasonable RGB values
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let rgb = niji.to_rgb(color)
  // Verify RGB values are in valid range
  let Rgb(r, g, b, a) = rgb
  assert r >=. 0.0 && r <=. 1.0
  assert g >=. 0.0 && g <=. 1.0
  assert b >=. 0.0 && b <=. 1.0
  assert a == 1.0
}

pub fn oklch_to_rgb_out_of_gamut_test() {
  // High chroma color that exceeds sRGB should be gamut mapped
  let color = niji.oklch(0.5, 0.5, 180.0, 1.0)
  let rgb = niji.to_rgb(color)
  // All RGB components should be in valid range
  let Rgb(r, g, b, a) = rgb
  assert r >=. 0.0 && r <=. 1.0
  assert g >=. 0.0 && g <=. 1.0
  assert b >=. 0.0 && b <=. 1.0
  assert a == 1.0
}

pub fn oklch_to_rgb_white_test() {
  // Lightness >= 100% should return white
  let color = niji.oklch(1.0, 0.5, 180.0, 1.0)
  let rgb = niji.to_rgb(color)
  let Rgb(r, g, b, a) = rgb
  assert r == 1.0
  assert g == 1.0
  assert b == 1.0
  assert a == 1.0
}

pub fn oklch_to_rgb_black_test() {
  // Lightness <= 0% should return black
  let color = niji.oklch(0.0, 0.5, 180.0, 1.0)
  let rgb = niji.to_rgb(color)
  let Rgb(r, g, b, a) = rgb
  assert r == 0.0
  assert g == 0.0
  assert b == 0.0
  assert a == 1.0
}

pub fn oklch_to_rgb_clamped_test() {
  // Old behavior: simple clamp should work
  let color = niji.oklch(0.5, 0.5, 180.0, 1.0)
  let rgb = niji.to_rgb_clamped(color)
  // Just verify it works and returns valid RGB
  let Rgb(r, g, b, a) = rgb
  assert r >=. 0.0 && r <=. 1.0
  assert g >=. 0.0 && g <=. 1.0
  assert b >=. 0.0 && b <=. 1.0
  assert a == 1.0
}

pub fn gamut_mapping_differs_from_simple_clamp_test() {
  let color = niji.oklch(0.5, 0.5, 180.0, 1.0)
  let mapped = niji.to_rgb(color)
  let clamped = niji.to_rgb_clamped(color)
  // For out-of-gamut color, CSS gamut mapping should differ from simple clamping
  assert mapped.r != clamped.r || mapped.g != clamped.g || mapped.b != clamped.b
}

pub fn gamut_mapping_preserves_hue_test() {
  // Verify that gamut mapping preserves hue approximately
  let color = niji.oklch(0.5, 0.6, 120.0, 1.0)
  let rgb = niji.to_rgb(color)
  let back_to_oklch = niji.rgb_to_oklch(rgb)
  // Hue should be approximately preserved (within 30 degrees tolerance)
  assert float.loosely_equals(back_to_oklch.h, with: 120.0, tolerating: 30.0)
}

pub fn gamut_mapping_preserves_lightness_test() {
  // Verify that gamut mapping preserves lightness
  let color = niji.oklch(0.7, 0.5, 180.0, 1.0)
  let rgb = niji.to_rgb(color)
  let back_to_oklch = niji.rgb_to_oklch(rgb)
  // Lightness should be approximately preserved
  assert float.loosely_equals(back_to_oklch.l, with: 0.7, tolerating: 0.15)
}

pub fn gamut_mapping_with_alpha_test() {
  // Gamut mapping should preserve alpha
  let color = niji.oklch(0.5, 0.6, 180.0, 0.5)
  let rgb = niji.to_rgb(color)
  let Rgb(r: _, g: _, b: _, alpha: a) = rgb
  assert a == 0.5
}
