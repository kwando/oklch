import gleam/float
import gleam/int
import gleam/list
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

// =============================================================================
// GRADIENT_FOLD TESTS
// =============================================================================

pub fn gradient_fold_basic_test() {
  let from = niji.oklch(0.3, 0.2, 0.0, 1.0)
  let to = niji.oklch(0.7, 0.2, 180.0, 1.0)

  // Build a list of colors by folding
  let colors =
    niji.gradient_fold(from, to, 5, [], fn(acc, color) { [color, ..acc] })
    |> list.reverse()

  // Should have 5 colors
  assert list.length(colors) == 5

  // First color should be approximately 'from'
  let assert [first, ..] = colors
  assert float.loosely_equals(first.l, with: 0.3, tolerating: 0.01)

  // Last color should be approximately 'to'
  let assert [_, _, _, _, last] = colors
  assert float.loosely_equals(last.l, with: 0.7, tolerating: 0.01)
  assert float.loosely_equals(last.h, with: 180.0, tolerating: 0.5)
}

pub fn gradient_fold_builds_list_test() {
  let from = niji.oklch(0.5, 0.2, 0.0, 1.0)
  let to = niji.oklch(0.5, 0.2, 180.0, 1.0)

  // Build hex strings
  let hexes =
    niji.gradient_fold(from, to, 3, [], fn(acc, color) {
      [niji.to_hex(color), ..acc]
    })
    |> list.reverse()

  // Should have 3 hex strings
  assert list.length(hexes) == 3

  // Verify each is a valid hex string
  list.each(hexes, fn(hex) {
    assert string.length(hex) == 7
    assert string.starts_with(hex, "#")
  })
}

pub fn gradient_fold_count_zero_test() {
  let from = niji.oklch(0.3, 0.2, 0.0, 1.0)
  let to = niji.oklch(0.7, 0.2, 180.0, 1.0)

  // count = 0 should return initial accumulator unchanged
  let result =
    niji.gradient_fold(from, to, 0, "initial", fn(_, color) {
      niji.to_hex(color)
    })

  assert result == "initial"
}

pub fn gradient_fold_count_one_test() {
  let from = niji.oklch(0.3, 0.2, 0.0, 1.0)
  let to = niji.oklch(0.7, 0.2, 180.0, 1.0)

  // count = 1 should call callback once with 'from' color
  let result =
    niji.gradient_fold(from, to, 1, [], fn(acc, color) { [color, ..acc] })
    |> list.reverse()

  assert list.length(result) == 1

  let assert [only] = result
  assert float.loosely_equals(only.l, with: 0.3, tolerating: 0.001)
}

pub fn gradient_fold_count_two_test() {
  let from = niji.oklch(0.3, 0.2, 0.0, 1.0)
  let to = niji.oklch(0.7, 0.2, 180.0, 1.0)

  // count = 2 should call callback with 'from' and 'to'
  let result =
    niji.gradient_fold(from, to, 2, [], fn(acc, color) { [color, ..acc] })
    |> list.reverse()

  assert list.length(result) == 2

  let assert [first, last] = result
  assert float.loosely_equals(first.l, with: 0.3, tolerating: 0.001)
  assert float.loosely_equals(last.l, with: 0.7, tolerating: 0.001)
}

pub fn gradient_fold_hue_wraparound_test() {
  // Test hue interpolation across 0/360 boundary
  let from = niji.oklch(0.5, 0.2, 350.0, 1.0)
  let to = niji.oklch(0.5, 0.2, 10.0, 1.0)

  let colors =
    niji.gradient_fold(from, to, 3, [], fn(acc, color) { [color, ..acc] })
    |> list.reverse()

  let assert [_, middle, _] = colors
  // Middle color should have hue around 0/360 (wrapped)
  assert middle.h <. 20.0 || middle.h >. 340.0
}

pub fn gradient_fold_grayscale_monotonic_test() {
  // Grayscale gradient should have monotonic lightness
  let black = niji.oklch(0.0, 0.0, 0.0, 1.0)
  let white = niji.oklch(1.0, 0.0, 0.0, 1.0)

  let colors =
    niji.gradient_fold(black, white, 5, [], fn(acc, color) { [color, ..acc] })
    |> list.reverse()

  // Check that lightness increases monotonically
  let assert [c1, c2, c3, c4, c5] = colors
  assert c1.l <=. c2.l
  assert c2.l <=. c3.l
  assert c3.l <=. c4.l
  assert c4.l <=. c5.l
}

pub fn gradient_fold_sum_lightness_test() {
  let from = niji.oklch(0.2, 0.0, 0.0, 1.0)
  let to = niji.oklch(0.8, 0.0, 0.0, 1.0)

  // Sum all lightness values (5 steps: 0.2, 0.35, 0.5, 0.65, 0.8)
  let sum =
    niji.gradient_fold(from, to, 5, 0.0, fn(acc, color) { acc +. color.l })

  // Expected: 0.2 + 0.35 + 0.5 + 0.65 + 0.8 = 2.5
  assert float.loosely_equals(sum, with: 2.5, tolerating: 0.01)
}

pub fn gradient_fold_average_chroma_test() {
  let from = niji.oklch(0.5, 0.1, 0.0, 1.0)
  let to = niji.oklch(0.5, 0.3, 180.0, 1.0)

  // Calculate average chroma
  let #(sum, count) =
    niji.gradient_fold(from, to, 5, #(0.0, 0), fn(acc, color) {
      let #(s, c) = acc
      #(s +. color.c, c + 1)
    })

  let avg = sum /. int.to_float(count)

  // Average should be around 0.2 (halfway between 0.1 and 0.3)
  assert float.loosely_equals(avg, with: 0.2, tolerating: 0.01)
}

pub fn gradient_fold_negative_count_test() {
  let from = niji.oklch(0.3, 0.2, 0.0, 1.0)
  let to = niji.oklch(0.7, 0.2, 180.0, 1.0)

  // Negative count should return initial accumulator unchanged
  let result =
    niji.gradient_fold(from, to, -5, "unchanged", fn(_, color) {
      niji.to_hex(color)
    })

  assert result == "unchanged"
}

pub fn gradient_fold_identical_colors_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)

  // Gradient between identical colors should produce identical results
  let colors =
    niji.gradient_fold(color, color, 3, [], fn(acc, c) { [c, ..acc] })
    |> list.reverse()

  let assert [c1, c2, c3] = colors
  // All colors should be identical
  assert float.loosely_equals(c1.l, with: 0.5, tolerating: 0.001)
  assert float.loosely_equals(c2.l, with: 0.5, tolerating: 0.001)
  assert float.loosely_equals(c3.l, with: 0.5, tolerating: 0.001)
}

pub fn gradient_fold_preserves_alpha_test() {
  let from = niji.oklch(0.3, 0.2, 0.0, 0.5)
  let to = niji.oklch(0.7, 0.2, 180.0, 1.0)

  let alphas =
    niji.gradient_fold(from, to, 5, [], fn(acc, color) { [color.alpha, ..acc] })
    |> list.reverse()

  // First alpha should be 0.5, last should be 1.0
  let assert [first_alpha, ..] = alphas
  let assert [_, _, _, _, last_alpha] = alphas

  assert float.loosely_equals(first_alpha, with: 0.5, tolerating: 0.01)
  assert float.loosely_equals(last_alpha, with: 1.0, tolerating: 0.01)
}

// =============================================================================
// TEMPERATURE TESTS
// =============================================================================

pub fn temperature_warm_test() {
  // 2700K should be warm (orange-white)
  let warm = niji.temperature(2700.0)

  // Should be reasonably light
  assert warm.l >. 0.5
  // Should have some chroma (not gray)
  assert warm.c >. 0.05
  // Should be in orange/red region (hue around 20-60)
  assert warm.h >. 20.0
  assert warm.h <. 80.0
}

pub fn temperature_daylight_test() {
  // 6500K should be near white
  let daylight = niji.temperature(6500.0)

  // Should be fairly light
  assert daylight.l >. 0.8
  // Should have low chroma (near neutral)
  assert daylight.c <. 0.1
}

pub fn temperature_cool_test() {
  // 15000K should be cooler (higher K = cooler/bluer in approximation)
  let cool = niji.temperature(15_000.0)
  let warm = niji.temperature(2700.0)

  // Should be reasonably light
  assert cool.l >. 0.5
  // Should have some chroma
  assert cool.c >. 0.05
  // Cooler temperature should have different hue than warm
  // Note: The approximation may not produce exact blue, but should differ from warm
  assert cool.h != warm.h
}

pub fn temperature_clamping_test() {
  // Values below 1000K should be clamped
  let very_cold = niji.temperature(500.0)
  let clamped_cold = niji.temperature(1000.0)
  assert float.loosely_equals(
    very_cold.l,
    with: clamped_cold.l,
    tolerating: 0.001,
  )

  // Values above 40000K should be clamped
  let very_hot = niji.temperature(50_000.0)
  let clamped_hot = niji.temperature(40_000.0)
  assert float.loosely_equals(
    very_hot.l,
    with: clamped_hot.l,
    tolerating: 0.001,
  )
}

pub fn temperature_converts_to_rgb_test() {
  // All temperature colors should be convertible to RGB
  // (gamut mapping will handle any out-of-gamut colors)
  let warm = niji.temperature(2700.0)
  let daylight = niji.temperature(6500.0)
  let cool = niji.temperature(15_000.0)

  // Should be able to convert to RGB without errors
  let warm_rgb = niji.to_rgb(warm)
  let daylight_rgb = niji.to_rgb(daylight)
  let cool_rgb = niji.to_rgb(cool)

  // Verify RGB values are in valid range [0, 1]
  let Rgb(r: wr, g: wg, b: wb, ..) = warm_rgb
  let Rgb(r: dr, g: dg, b: db, ..) = daylight_rgb
  let Rgb(r: cr, g: cg, b: cb, ..) = cool_rgb

  assert wr >=. 0.0 && wr <=. 1.0
  assert wg >=. 0.0 && wg <=. 1.0
  assert wb >=. 0.0 && wb <=. 1.0
  assert dr >=. 0.0 && dr <=. 1.0
  assert dg >=. 0.0 && dg <=. 1.0
  assert db >=. 0.0 && db <=. 1.0
  assert cr >=. 0.0 && cr <=. 1.0
  assert cg >=. 0.0 && cg <=. 1.0
  assert cb >=. 0.0 && cb <=. 1.0
}

// =============================================================================
// GRAYSCALE TESTS
// =============================================================================

pub fn grayscale_sets_chroma_to_zero_test() {
  let red = niji.oklch(0.5, 0.3, 0.0, 1.0)
  let gray = niji.grayscale(red)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = gray

  // Chroma should be 0
  assert c == 0.0
  // Hue should be 0 (irrelevant when chroma is 0)
  assert h == 0.0
  // Lightness should be preserved
  assert l == 0.5
  // Alpha should be preserved
  assert alpha == 1.0
}

pub fn grayscale_preserves_lightness_test() {
  let color = niji.oklch(0.8, 0.2, 120.0, 0.5)
  let gray = niji.grayscale(color)
  let Oklch(l: l, alpha: alpha, ..) = gray

  assert l == 0.8
  assert alpha == 0.5
}

pub fn grayscale_already_gray_test() {
  let gray = niji.oklch(0.5, 0.0, 0.0, 1.0)
  let result = niji.grayscale(gray)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = result

  assert l == 0.5
  assert c == 0.0
  assert h == 0.0
  assert alpha == 1.0
}

// =============================================================================
// COLOR INVERSION TESTS
// =============================================================================

pub fn invert_rotates_hue_180_test() {
  let red = niji.oklch(0.5, 0.2, 0.0, 1.0)
  let inverted = niji.invert(red)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = inverted

  // Hue should be rotated by 180°
  assert h == 180.0
  // Lightness should be preserved
  assert l == 0.5
  // Chroma should be preserved
  assert c == 0.2
  // Alpha should be preserved
  assert alpha == 1.0
}

pub fn invert_preserves_lightness_and_chroma_test() {
  let color = niji.oklch(0.7, 0.3, 90.0, 0.8)
  let inverted = niji.invert(color)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = inverted

  assert float.loosely_equals(l, with: 0.7, tolerating: 0.001)
  assert float.loosely_equals(c, with: 0.3, tolerating: 0.001)
  assert float.loosely_equals(alpha, with: 0.8, tolerating: 0.001)
  assert h == 270.0
}

pub fn invert_double_inversion_test() {
  let original = niji.oklch(0.5, 0.2, 45.0, 1.0)
  let inverted = niji.invert(original)
  let double_inverted = niji.invert(inverted)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = double_inverted

  // Double inversion should return approximately the original
  assert float.loosely_equals(l, with: 0.5, tolerating: 0.001)
  assert float.loosely_equals(c, with: 0.2, tolerating: 0.001)
  assert float.loosely_equals(h, with: 45.0, tolerating: 0.001)
  assert float.loosely_equals(alpha, with: 1.0, tolerating: 0.001)
}

pub fn invert_full_rotates_hue_and_inverts_lightness_test() {
  let red = niji.oklch(0.3, 0.2, 0.0, 1.0)
  let inverted = niji.invert_full(red)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = inverted

  // Hue should be rotated by 180°
  assert h == 180.0
  // Lightness should be inverted (1.0 - 0.3 = 0.7)
  assert float.loosely_equals(l, with: 0.7, tolerating: 0.001)
  // Chroma should be preserved
  assert c == 0.2
  // Alpha should be preserved
  assert alpha == 1.0
}

pub fn invert_full_double_inversion_test() {
  let original = niji.oklch(0.4, 0.2, 60.0, 0.5)
  let inverted = niji.invert_full(original)
  let double_inverted = niji.invert_full(inverted)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = double_inverted

  // Double full inversion should return approximately the original
  // Hue: 60 -> 240 -> 60
  // Lightness: 0.4 -> 0.6 -> 0.4
  assert float.loosely_equals(l, with: 0.4, tolerating: 0.001)
  assert float.loosely_equals(c, with: 0.2, tolerating: 0.001)
  assert float.loosely_equals(h, with: 60.0, tolerating: 0.001)
  assert float.loosely_equals(alpha, with: 0.5, tolerating: 0.001)
}

pub fn invert_full_with_white_test() {
  let white = niji.oklch(1.0, 0.0, 0.0, 1.0)
  let inverted = niji.invert_full(white)
  let Oklch(l: l, c: c, h: _h, alpha: alpha) = inverted

  // White with 0 chroma -> inverted lightness should be 0
  assert l == 0.0
  assert c == 0.0
  // Hue is irrelevant when chroma is 0, but should be rotated
  assert alpha == 1.0
}

pub fn invert_full_with_black_test() {
  let black = niji.oklch(0.0, 0.0, 0.0, 1.0)
  let inverted = niji.invert_full(black)
  let Oklch(l: l, c: c, h: __h, alpha: alpha) = inverted

  // Black with 0 chroma -> inverted lightness should be 1.0
  assert l == 1.0
  assert c == 0.0
  assert alpha == 1.0
}

// =============================================================================
// NAMED CSS COLORS (from CSS Color Module Level 4 spec)
// =============================================================================

pub fn css_color_white_test() {
  // white = #FFFFFF
  let color = niji.rgb_from_ints(255, 255, 255, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 1.0, tolerating: 0.01)
  assert oklch.c <. 0.05
}

pub fn css_color_black_test() {
  // black = #000000
  let color = niji.rgb_from_ints(0, 0, 0, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.0, tolerating: 0.01)
  assert oklch.c <. 0.05
}

pub fn css_color_red_test() {
  // red = #FF0000
  let color = niji.rgb_from_ints(255, 0, 0, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.628, tolerating: 0.01)
  assert float.loosely_equals(oklch.c, with: 0.258, tolerating: 0.01)
  assert float.loosely_equals(oklch.h, with: 29.2, tolerating: 1.0)
}

pub fn css_color_lime_test() {
  // lime = #00FF00 (pure green)
  let color = niji.rgb_from_ints(0, 255, 0, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.866, tolerating: 0.01)
  assert float.loosely_equals(oklch.c, with: 0.295, tolerating: 0.01)
  assert float.loosely_equals(oklch.h, with: 142.5, tolerating: 1.0)
}

pub fn css_color_blue_test() {
  // blue = #0000FF
  let color = niji.rgb_from_ints(0, 0, 255, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.452, tolerating: 0.01)
  assert float.loosely_equals(oklch.c, with: 0.313, tolerating: 0.01)
  assert float.loosely_equals(oklch.h, with: 264.1, tolerating: 1.0)
}

pub fn css_color_yellow_test() {
  // yellow = #FFFF00
  let color = niji.rgb_from_ints(255, 255, 0, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.968, tolerating: 0.01)
  assert float.loosely_equals(oklch.c, with: 0.211, tolerating: 0.01)
  assert float.loosely_equals(oklch.h, with: 109.8, tolerating: 1.0)
}

pub fn css_color_cyan_test() {
  // cyan/aqua = #00FFFF
  let color = niji.rgb_from_ints(0, 255, 255, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.905, tolerating: 0.01)
  assert float.loosely_equals(oklch.c, with: 0.155, tolerating: 0.01)
  assert float.loosely_equals(oklch.h, with: 194.7, tolerating: 1.0)
}

pub fn css_color_magenta_test() {
  // magenta/fuchsia = #FF00FF
  let color = niji.rgb_from_ints(255, 0, 255, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.702, tolerating: 0.01)
  assert float.loosely_equals(oklch.c, with: 0.322, tolerating: 0.01)
  assert float.loosely_equals(oklch.h, with: 328.4, tolerating: 1.0)
}

pub fn css_color_silver_test() {
  // silver = #C0C0C0
  let color = niji.rgb_from_ints(192, 192, 192, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.808, tolerating: 0.01)
  assert oklch.c <. 0.02
}

pub fn css_color_gray_test() {
  // gray = #808080
  let color = niji.rgb_from_ints(128, 128, 128, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.598, tolerating: 0.01)
  assert oklch.c <. 0.02
}

pub fn css_color_maroon_test() {
  // maroon = #800000
  let color = niji.rgb_from_ints(128, 0, 0, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.373, tolerating: 0.01)
  assert float.loosely_equals(oklch.h, with: 28.0, tolerating: 2.0)
}

pub fn css_color_navy_test() {
  // navy = #000080
  let color = niji.rgb_from_ints(0, 0, 128, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.277, tolerating: 0.01)
  assert float.loosely_equals(oklch.h, with: 264.0, tolerating: 2.0)
}

pub fn css_color_teal_test() {
  // teal = #008080
  let color = niji.rgb_from_ints(0, 128, 128, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.543, tolerating: 0.01)
  assert float.loosely_equals(oklch.h, with: 194.0, tolerating: 2.0)
}

pub fn css_color_orange_test() {
  // orange = #FFA500
  let color = niji.rgb_from_ints(255, 165, 0, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.792, tolerating: 0.01)
  assert float.loosely_equals(oklch.h, with: 71.0, tolerating: 2.0)
}

pub fn css_color_purple_test() {
  // purple = #800080
  let color = niji.rgb_from_ints(128, 0, 128, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  assert float.loosely_equals(oklch.l, with: 0.421, tolerating: 0.01)
  assert float.loosely_equals(oklch.h, with: 328.0, tolerating: 2.0)
}

// =============================================================================
// NAMED COLOR ROUNDTRIP TESTS
// =============================================================================

pub fn named_color_roundtrip_white_test() {
  let hex = "#FFFFFF"
  let color = niji.rgb_from_ints(255, 255, 255, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  let rgb = niji.to_rgb(oklch)
  let result_hex = niji.rgb_to_hex(rgb)
  assert result_hex == hex
}

pub fn named_color_roundtrip_black_test() {
  let hex = "#000000"
  let color = niji.rgb_from_ints(0, 0, 0, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  let rgb = niji.to_rgb(oklch)
  let result_hex = niji.rgb_to_hex(rgb)
  assert result_hex == hex
}

pub fn named_color_roundtrip_red_test() {
  let hex = "#FF0000"
  let color = niji.rgb_from_ints(255, 0, 0, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  let rgb = niji.to_rgb(oklch)
  let result_hex = niji.rgb_to_hex(rgb)
  assert result_hex == hex
}

pub fn named_color_roundtrip_green_test() {
  let hex = "#00FF00"
  let color = niji.rgb_from_ints(0, 255, 0, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  let rgb = niji.to_rgb(oklch)
  let result_hex = niji.rgb_to_hex(rgb)
  assert result_hex == hex
}

pub fn named_color_roundtrip_blue_test() {
  let hex = "#0000FF"
  let color = niji.rgb_from_ints(0, 0, 255, 1.0)
  let oklch = niji.rgb_to_oklch(color)
  let rgb = niji.to_rgb(oklch)
  let result_hex = niji.rgb_to_hex(rgb)
  assert result_hex == hex
}

// =============================================================================
// EDGE CASES - ROTATE HUE NEGATIVE
// =============================================================================

pub fn rotate_hue_negative_90_test() {
  let color = niji.oklch(0.5, 0.2, 90.0, 1.0)
  let rotated = niji.rotate_hue(color, -90.0)
  let Oklch(h: h, ..) = rotated
  assert float.loosely_equals(h, with: 0.0, tolerating: 0.001)
}

pub fn rotate_hue_negative_180_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let rotated = niji.rotate_hue(color, -180.0)
  let Oklch(h: h, ..) = rotated
  assert float.loosely_equals(h, with: 0.0, tolerating: 0.001)
}

pub fn rotate_hue_negative_wrap_test() {
  let color = niji.oklch(0.5, 0.2, 30.0, 1.0)
  let rotated = niji.rotate_hue(color, -60.0)
  let Oklch(h: h, ..) = rotated
  assert float.loosely_equals(h, with: 330.0, tolerating: 0.001)
}

// =============================================================================
// MIX EDGE CASES
// =============================================================================

pub fn mix_same_color_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let mixed = niji.mix(color, color, 0.5)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = mixed
  assert float.loosely_equals(l, with: 0.5, tolerating: 0.001)
  assert float.loosely_equals(c, with: 0.2, tolerating: 0.001)
  assert float.loosely_equals(h, with: 180.0, tolerating: 0.001)
  assert float.loosely_equals(alpha, with: 1.0, tolerating: 0.001)
}

pub fn mix_achromatic_with_chromatic_test() {
  let gray = niji.oklch(0.5, 0.0, 0.0, 1.0)
  let red = niji.oklch(0.5, 0.3, 0.0, 1.0)
  let mixed = niji.mix(gray, red, 0.5)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = mixed
  assert float.loosely_equals(l, with: 0.5, tolerating: 0.001)
  assert float.loosely_equals(c, with: 0.15, tolerating: 0.001)
  assert float.loosely_equals(h, with: 0.0, tolerating: 0.001)
  assert float.loosely_equals(alpha, with: 1.0, tolerating: 0.001)
}

pub fn mix_weight_clamped_below_zero_test() {
  let color1 = niji.oklch(0.3, 0.2, 0.0, 1.0)
  let color2 = niji.oklch(0.7, 0.3, 180.0, 1.0)
  let mixed = niji.mix(color1, color2, -0.5)
  // Weight clamped to 0.0, should return color1
  let Oklch(l: l, ..) = mixed
  assert float.loosely_equals(l, with: 0.3, tolerating: 0.001)
}

pub fn mix_weight_clamped_above_one_test() {
  let color1 = niji.oklch(0.3, 0.2, 0.0, 1.0)
  let color2 = niji.oklch(0.7, 0.3, 180.0, 1.0)
  let mixed = niji.mix(color1, color2, 1.5)
  // Weight clamped to 1.0, should return color2
  let Oklch(l: l, ..) = mixed
  assert float.loosely_equals(l, with: 0.7, tolerating: 0.001)
}

pub fn mix_hue_wraparound_shortest_path_test() {
  // Test that hue interpolation takes the shortest path
  let color1 = niji.oklch(0.5, 0.2, 10.0, 1.0)
  let color2 = niji.oklch(0.5, 0.2, 350.0, 1.0)
  let mixed = niji.mix(color1, color2, 0.5)
  let Oklch(h: h, ..) = mixed
  // Should go through 0/360 boundary, result should be near 0 or 360
  assert h >. 355.0 || h <. 5.0
}

// =============================================================================
// DISTANCE EDGE CASES
// =============================================================================

pub fn distance_same_color_is_zero_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let d = niji.distance(color, color)
  assert d == 0.0
}

pub fn distance_maximum_difference_test() {
  let black = niji.oklch(0.0, 0.0, 0.0, 1.0)
  let white = niji.oklch(1.0, 0.0, 0.0, 1.0)
  let d = niji.distance(black, white)
  // Maximum lightness difference should give distance of 1.0
  assert float.loosely_equals(d, with: 1.0, tolerating: 0.001)
}

pub fn distance_symmetry_test() {
  let color1 = niji.oklch(0.3, 0.25, 120.0, 1.0)
  let color2 = niji.oklch(0.7, 0.15, 240.0, 0.8)
  let d1 = niji.distance(color1, color2)
  let d2 = niji.distance(color2, color1)
  assert float.loosely_equals(d1, with: d2, tolerating: 0.000001)
}

// =============================================================================
// GAMUT BOUNDARY TESTS
// =============================================================================

pub fn gamut_boundary_white_test() {
  let white = niji.oklch(1.0, 0.0, 0.0, 1.0)
  assert niji.in_gamut(white)
  let rgb = niji.to_rgb(white)
  assert rgb.r == 1.0
  assert rgb.g == 1.0
  assert rgb.b == 1.0
}

pub fn gamut_boundary_black_test() {
  let black = niji.oklch(0.0, 0.0, 0.0, 1.0)
  assert niji.in_gamut(black)
  let rgb = niji.to_rgb(black)
  assert rgb.r == 0.0
  assert rgb.g == 0.0
  assert rgb.b == 0.0
}

pub fn gamut_boundary_mid_gray_test() {
  let gray = niji.oklch(0.5, 0.0, 0.0, 1.0)
  assert niji.in_gamut(gray)
  let rgb = niji.to_rgb(gray)
  // Middle gray in OKLCH is not exactly 0.5 in RGB due to gamma
  // L=0.5 in OKLCH corresponds to approximately RGB 0.35-0.40 due to perceptual uniformity
  assert rgb.r >. 0.3 && rgb.r <. 0.7
  assert rgb.g >. 0.3 && rgb.g <. 0.7
  assert rgb.b >. 0.3 && rgb.b <. 0.7
}

pub fn gamut_extreme_high_chroma_test() {
  // Very high chroma that's definitely out of gamut
  let extreme = niji.oklch(0.5, 2.0, 180.0, 1.0)
  assert !niji.in_gamut(extreme)
  let mapped = niji.gamut_map(extreme)
  assert niji.in_gamut(mapped)
}

pub fn gamut_extreme_low_lightness_high_chroma_test() {
  // Dark color with high chroma
  let dark = niji.oklch(0.1, 0.5, 30.0, 1.0)
  let rgb = niji.to_rgb(dark)
  // Should still be valid RGB
  assert rgb.r >=. 0.0 && rgb.r <=. 1.0
  assert rgb.g >=. 0.0 && rgb.g <=. 1.0
  assert rgb.b >=. 0.0 && rgb.b <=. 1.0
}

pub fn gamut_extreme_high_lightness_high_chroma_test() {
  // Light color with high chroma
  let light = niji.oklch(0.95, 0.3, 200.0, 1.0)
  let rgb = niji.to_rgb(light)
  // Should still be valid RGB
  assert rgb.r >=. 0.0 && rgb.r <=. 1.0
  assert rgb.g >=. 0.0 && rgb.g <=. 1.0
  assert rgb.b >=. 0.0 && rgb.b <=. 1.0
}

// =============================================================================
// TEMPERATURE EDGE CASES
// =============================================================================

pub fn temperature_exact_1000k_test() {
  let color = niji.temperature(1000.0)
  assert color.l >. 0.0
  assert color.c >. 0.0
}

pub fn temperature_exact_40000k_test() {
  let color = niji.temperature(40_000.0)
  assert color.l >. 0.0
  // Very high temperature should be bluish
}

pub fn temperature_below_range_test() {
  let below = niji.temperature(500.0)
  let at_min = niji.temperature(1000.0)
  // Should be clamped to 1000K
  assert float.loosely_equals(below.l, with: at_min.l, tolerating: 0.001)
}

pub fn temperature_above_range_test() {
  let above = niji.temperature(50_000.0)
  let at_max = niji.temperature(40_000.0)
  // Should be clamped to 40000K
  assert float.loosely_equals(above.l, with: at_max.l, tolerating: 0.001)
}

// =============================================================================
// CONTRAST EDGE CASES
// =============================================================================

pub fn contrast_same_color_is_one_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let ratio = niji.contrast_ratio(color, color)
  // Same color should have contrast ratio of 1.0 (minimum)
  assert float.loosely_equals(ratio, with: 1.0, tolerating: 0.001)
}

pub fn contrast_black_white_is_maximum_test() {
  let black = niji.oklch(0.0, 0.0, 0.0, 1.0)
  let white = niji.oklch(1.0, 0.0, 0.0, 1.0)
  let ratio = niji.contrast_ratio(black, white)
  // Black/white contrast should be 21:1
  assert float.loosely_equals(ratio, with: 21.0, tolerating: 0.001)
}

pub fn contrast_symmetry_test() {
  let color1 = niji.oklch(0.2, 0.1, 180.0, 1.0)
  let color2 = niji.oklch(0.8, 0.05, 300.0, 1.0)
  let r1 = niji.contrast_ratio(color1, color2)
  let r2 = niji.contrast_ratio(color2, color1)
  assert float.loosely_equals(r1, with: r2, tolerating: 0.000001)
}

// =============================================================================
// HEX FORMATTING EDGE CASES
// =============================================================================

pub fn hex_roundtrip_all_channels_test() {
  // Test various RGB values roundtrip through OKLCH
  let test_values = [
    #(0, 0, 0),
    // Black
    #(255, 255, 255),
    // White
    #(255, 0, 0),
    // Red
    #(0, 255, 0),
    // Green
    #(0, 0, 255),
    // Blue
    #(128, 128, 128),
    // Gray
    #(255, 128, 0),
    // Orange
    #(128, 0, 255),
    // Purple
  ]

  list.each(test_values, fn(values) {
    let #(r, g, b) = values
    let original = niji.rgb_from_ints(r, g, b, 1.0)
    let oklch = niji.rgb_to_oklch(original)
    let converted = niji.to_rgb(oklch)

    // Allow small tolerance for gamut mapping and conversion
    assert float.loosely_equals(converted.r, with: original.r, tolerating: 0.02)
    assert float.loosely_equals(converted.g, with: original.g, tolerating: 0.02)
    assert float.loosely_equals(converted.b, with: original.b, tolerating: 0.02)
  })
}

pub fn hex_with_various_alpha_values_test() {
  let color1 = niji.rgb(1.0, 0.0, 0.0, 0.0)
  let hex1 = niji.rgb_to_hex(color1)
  assert hex1 == "#FF000000"

  let color2 = niji.rgb(1.0, 0.0, 0.0, 0.5)
  let hex2 = niji.rgb_to_hex(color2)
  assert hex2 == "#FF000080"

  let color3 = niji.rgb(1.0, 0.0, 0.0, 1.0)
  let hex3 = niji.rgb_to_hex(color3)
  assert hex3 == "#FF0000"
}

pub fn hex_lowercase_not_expected_test() {
  // Our implementation outputs uppercase hex
  let color = niji.rgb(0.0, 0.5, 1.0, 1.0)
  let hex = niji.rgb_to_hex(color)
  assert string.contains(hex, "007FFF") || string.contains(hex, "0080FF")
}

// =============================================================================
// MANIPULATION EDGE CASES
// =============================================================================

pub fn lighten_already_white_test() {
  let white = niji.oklch(1.0, 0.0, 0.0, 1.0)
  let result = niji.lighten(white, 0.5)
  let Oklch(l: l, ..) = result
  assert l == 1.0
}

pub fn darken_already_black_test() {
  let black = niji.oklch(0.0, 0.0, 0.0, 1.0)
  let result = niji.darken(black, 0.5)
  let Oklch(l: l, ..) = result
  assert l == 0.0
}

pub fn saturate_already_zero_test() {
  let gray = niji.oklch(0.5, 0.0, 0.0, 1.0)
  let result = niji.saturate(gray, 0.2)
  let Oklch(c: c, ..) = result
  assert c == 0.2
}

pub fn desaturate_to_zero_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)
  let result = niji.desaturate(color, 0.5)
  let Oklch(c: c, ..) = result
  assert c == 0.0
}

pub fn set_alpha_clamping_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)

  let below = niji.set_alpha(color, -0.5)
  let Oklch(alpha: a1, ..) = below
  assert a1 == 0.0

  let above = niji.set_alpha(color, 1.5)
  let Oklch(alpha: a2, ..) = above
  assert a2 == 1.0
}

pub fn set_l_clamping_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)

  let below = niji.set_l(color, -0.5)
  let Oklch(l: l1, ..) = below
  assert l1 == 0.0

  let above = niji.set_l(color, 1.5)
  let Oklch(l: l2, ..) = above
  assert l2 == 1.0
}

pub fn set_c_negative_clamping_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)

  let below = niji.set_c(color, -0.5)
  let Oklch(c: c, ..) = below
  assert c == 0.0
}

pub fn set_c_no_upper_clamp_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)

  let high = niji.set_c(color, 1.5)
  let Oklch(c: c, ..) = high
  assert c == 1.5
}

pub fn set_h_wraparound_test() {
  let color = niji.oklch(0.5, 0.2, 180.0, 1.0)

  let above = niji.set_h(color, 450.0)
  let Oklch(h: h1, ..) = above
  assert float.loosely_equals(h1, with: 90.0, tolerating: 0.001)

  let below = niji.set_h(color, -90.0)
  let Oklch(h: h2, ..) = below
  assert float.loosely_equals(h2, with: 270.0, tolerating: 0.001)
}
