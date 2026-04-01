import gleam/float
import gleam/result
import gleam/string
import gleam_community/colour
import gleeunit
import oklch.{Oklch, Rgb}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn oklch_type_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = color
  assert l == 0.5
  assert c == 0.2
  assert h == 180.0
  assert alpha == 1.0
}

pub fn oklch_clamp_l_test() {
  let color = oklch.oklch(1.5, 0.2, 180.0, 1.0)
  let Oklch(l: l, ..) = color
  assert l == 1.0

  let color = oklch.oklch(-0.5, 0.2, 180.0, 1.0)
  let Oklch(l: l, ..) = color
  assert l == 0.0
}

pub fn oklch_clamp_c_test() {
  // High chroma values are NOT clamped (CSS allows values > 0.4)
  let color = oklch.oklch(0.5, 0.5, 180.0, 1.0)
  let Oklch(c: c, ..) = color
  assert c == 0.5

  // Negative chroma is still clamped to 0.0
  let color = oklch.oklch(0.5, -0.1, 180.0, 1.0)
  let Oklch(c: c, ..) = color
  assert c == 0.0
}

pub fn oklch_clamp_h_test() {
  let color = oklch.oklch(0.5, 0.2, 400.0, 1.0)
  let Oklch(h: h, ..) = color
  assert h == 40.0

  let color = oklch.oklch(0.5, 0.2, -30.0, 1.0)
  let Oklch(h: h, ..) = color
  assert h == 330.0
}

pub fn oklch_clamp_alpha_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.5)
  let Oklch(alpha: alpha, ..) = color
  assert alpha == 1.0

  let color = oklch.oklch(0.5, 0.2, 180.0, -0.1)
  let Oklch(alpha: alpha, ..) = color
  assert alpha == 0.0
}

pub fn rgb_type_test() {
  let color = oklch.rgb(0.5, 0.6, 0.7, 1.0)
  let Rgb(r: r, g: g, b: b, alpha: alpha) = color
  assert r == 0.5
  assert g == 0.6
  assert b == 0.7
  assert alpha == 1.0
}

pub fn rgb_from_ints_test() {
  let color = oklch.rgb_from_ints(255, 128, 64, 1.0)
  let Rgb(r: r, g: g, b: b, ..) = color
  assert float.loosely_equals(r, with: 1.0, tolerating: 0.01)
  assert float.loosely_equals(g, with: 0.502, tolerating: 0.01)
  assert float.loosely_equals(b, with: 0.251, tolerating: 0.01)
}

pub fn oklch_to_rgb_basic_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let rgb = oklch.oklch_to_rgb(color)
  let Rgb(r: _, g: _, b: _, alpha: alpha) = rgb
  assert alpha == 1.0
}

pub fn rgb_to_oklch_basic_test() {
  let color = oklch.rgb(0.5, 0.6, 0.7, 1.0)
  let oklch_color = oklch.rgb_to_oklch(color)
  let Oklch(l: l, c: c, h: _h, alpha: alpha) = oklch_color
  assert alpha == 1.0
  assert l >=. 0.0
  assert l <=. 1.0
  assert c >=. 0.0
  assert c <=. 0.45
}

pub fn round_trip_oklch_rgb_test() {
  let original = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let rgb = oklch.oklch_to_rgb(original)
  let result = oklch.rgb_to_oklch(rgb)
  let Oklch(l: _l, c: _c, h: _h, alpha: alpha) = result

  assert float.loosely_equals(alpha, with: 1.0, tolerating: 0.001)
}

pub fn oklch_to_hex_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let hex = oklch.oklch_to_hex(color)
  assert string.length(hex) == 7
}

pub fn hex_to_oklch_test() {
  let result = oklch.hex_to_oklch("#FF0000")
  assert result |> result.is_ok
}

pub fn hex_to_rgb_test() {
  let result = oklch.hex_to_rgb("#FF0000")
  assert result |> result.is_ok
}

pub fn rgb_to_hex_test() {
  let color = oklch.rgb(1.0, 0.0, 0.0, 1.0)
  let hex = oklch.rgb_to_hex(color)
  assert hex == "#FF0000"
}

pub fn hex_short_form_test() {
  let result = oklch.hex_to_rgb("#F00")
  assert result |> result.is_ok

  let result = oklch.hex_to_rgb("#F00F")
  assert result |> result.is_ok
}

pub fn hex_invalid_length_test() {
  let result = oklch.hex_to_rgb("#FFFFFFF")
  assert result |> result.is_error
}

pub fn lighten_test() {
  let color = oklch.oklch(0.3, 0.2, 180.0, 1.0)
  let lightened = oklch.lighten(color, 0.2)
  let Oklch(l: l, ..) = lightened
  assert float.loosely_equals(l, with: 0.5, tolerating: 0.001)
}

pub fn darken_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let darkened = oklch.darken(color, 0.2)
  let Oklch(l: l, ..) = darkened
  assert float.loosely_equals(l, with: 0.3, tolerating: 0.001)
}

pub fn saturate_test() {
  let color = oklch.oklch(0.5, 0.1, 180.0, 1.0)
  let saturated = oklch.saturate(color, 0.1)
  let Oklch(c: c, ..) = saturated
  assert float.loosely_equals(c, with: 0.2, tolerating: 0.001)

  // Saturation has no upper bound (can exceed 0.4)
  let color = oklch.oklch(0.5, 0.3, 180.0, 1.0)
  let saturated = oklch.saturate(color, 0.3)
  let Oklch(c: c, ..) = saturated
  assert float.loosely_equals(c, with: 0.6, tolerating: 0.001)
}

pub fn desaturate_test() {
  let color = oklch.oklch(0.5, 0.3, 180.0, 1.0)
  let desaturated = oklch.desaturate(color, 0.1)
  let Oklch(c: c, ..) = desaturated
  assert float.loosely_equals(c, with: 0.2, tolerating: 0.001)
}

pub fn rotate_hue_test() {
  let color = oklch.oklch(0.5, 0.2, 0.0, 1.0)
  let rotated = oklch.rotate_hue(color, 90.0)
  let Oklch(h: h, ..) = rotated
  assert float.loosely_equals(h, with: 90.0, tolerating: 0.001)
}

pub fn rotate_hue_wrap_test() {
  let color = oklch.oklch(0.5, 0.2, 350.0, 1.0)
  let rotated = oklch.rotate_hue(color, 30.0)
  let Oklch(h: h, ..) = rotated
  assert float.loosely_equals(h, with: 20.0, tolerating: 0.001)
}

pub fn set_alpha_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let result = oklch.set_alpha(color, 0.5)
  let Oklch(alpha: alpha, ..) = result
  assert alpha == 0.5
}

pub fn set_l_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let result = oklch.set_l(color, 0.8)
  let Oklch(l: l, ..) = result
  assert l == 0.8
}

pub fn set_c_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let result = oklch.set_c(color, 0.35)
  let Oklch(c: c, ..) = result
  assert c == 0.35

  // Values above 0.4 are allowed (no upper clamp)
  let result = oklch.set_c(color, 0.6)
  let Oklch(c: c, ..) = result
  assert c == 0.6

  // Negative values clamp to 0.0
  let result = oklch.set_c(color, -0.1)
  let Oklch(c: c, ..) = result
  assert c == 0.0
}

pub fn set_h_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let result = oklch.set_h(color, 270.0)
  let Oklch(h: h, ..) = result
  assert h == 270.0
}

pub fn mix_test() {
  let color1 = oklch.oklch(0.5, 0.2, 0.0, 1.0)
  let color2 = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let mixed = oklch.mix(color1, color2, 0.5)
  let Oklch(l: l, ..) = mixed
  assert float.loosely_equals(l, with: 0.5, tolerating: 0.001)
}

pub fn mix_weight_0_test() {
  let color1 = oklch.oklch(0.5, 0.2, 0.0, 1.0)
  let color2 = oklch.oklch(0.8, 0.3, 180.0, 1.0)
  let mixed = oklch.mix(color1, color2, 0.0)
  let Oklch(l: l, ..) = mixed
  assert float.loosely_equals(l, with: 0.5, tolerating: 0.001)
}

pub fn mix_weight_1_test() {
  let color1 = oklch.oklch(0.5, 0.2, 0.0, 1.0)
  let color2 = oklch.oklch(0.8, 0.3, 180.0, 1.0)
  let mixed = oklch.mix(color1, color2, 1.0)
  let Oklch(l: l, ..) = mixed
  assert float.loosely_equals(l, with: 0.8, tolerating: 0.001)
}

pub fn luminance_test() {
  let color = oklch.oklch(0.7, 0.2, 180.0, 1.0)
  let l = oklch.luminance(color)
  assert l == 0.7
}

pub fn contrast_ratio_test() {
  let color1 = oklch.oklch(0.95, 0.0, 0.0, 1.0)
  let color2 = oklch.oklch(0.1, 0.0, 0.0, 1.0)
  let ratio = oklch.contrast_ratio(color1, color2)
  assert ratio >. 5.0
}

pub fn wcag_aa_pass_test() {
  assert oklch.wcag_aa(4.5) == True
  assert oklch.wcag_aa(4.4) == False
}

pub fn wcag_aaa_pass_test() {
  assert oklch.wcag_aaa(7.0) == True
  assert oklch.wcag_aaa(6.9) == False
}

pub fn wcag_aa_large_text_pass_test() {
  assert oklch.wcag_aa_large_text(3.0) == True
  assert oklch.wcag_aa_large_text(2.9) == False
}

pub fn wcag_aaa_large_text_pass_test() {
  assert oklch.wcag_aaa_large_text(4.5) == True
  assert oklch.wcag_aaa_large_text(4.4) == False
}

pub fn ansi_fg_test() {
  let color = oklch.oklch(0.6, 0.2, 180.0, 1.0)
  let result = oklch.ansi(color, "Hello")
  assert string.contains(result, "Hello")
  assert string.contains(result, "\u{001b}[38;2;")
  assert string.contains(result, "\u{001b}[0m")
}

pub fn ansi_bg_test() {
  let color = oklch.oklch(0.6, 0.2, 180.0, 1.0)
  let result = oklch.ansi_bg(color, "Hello")
  assert string.contains(result, "Hello")
  assert string.contains(result, "\u{001b}[48;2;")
  assert string.contains(result, "\u{001b}[0m")
}

pub fn ansi_fg_bg_test() {
  let fg = oklch.oklch(0.6, 0.2, 180.0, 1.0)
  let bg = oklch.oklch(0.95, 0.0, 0.0, 1.0)
  let result = oklch.ansi_fg_bg(fg, bg, "Hello")
  assert string.contains(result, "Hello")
  assert string.contains(result, "\u{001b}[38;2;")
  assert string.contains(result, "\u{001b}[48;2;")
  assert string.contains(result, "\u{001b}[0m")
}

pub fn ansi_black_and_white_test() {
  let black = oklch.oklch(0.0, 0.0, 0.0, 1.0)
  let white = oklch.oklch(1.0, 0.0, 0.0, 1.0)

  let result = oklch.ansi_fg_bg(black, white, "X")
  assert string.contains(result, "X")
  assert string.contains(result, "\u{001b}[38;2;")
  assert string.contains(result, "\u{001b}[48;2;")
}

pub fn from_colour_test() {
  let oklch_color = oklch.from_colour(colour.red)
  let Oklch(l: l, c: c, h: h, alpha: alpha) = oklch_color
  assert alpha == 1.0
  assert l >. 0.0
  assert l <. 1.0
  assert c >=. 0.0
  assert h >=. 0.0
  assert h <. 360.0
}

pub fn to_colour_test() {
  let oklch_color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let result = oklch.to_colour(oklch_color)
  assert result |> result.is_ok
}

pub fn round_trip_colour_test() {
  let original = colour.light_blue
  let oklch_color = oklch.from_colour(original)
  let assert Ok(converted_back) = oklch.to_colour(oklch_color)
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
  let color = oklch.oklch(0.5, 0.6, 180.0, 1.0)
  let Oklch(c: c, ..) = color
  assert c == 0.6
}

pub fn very_high_chroma_test() {
  let color = oklch.oklch(0.5, 1.0, 180.0, 1.0)
  let Oklch(c: c, ..) = color
  assert c == 1.0
}

// =============================================================================
// HAS_HUE TESTS
// =============================================================================

pub fn has_hue_with_chroma_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  assert oklch.has_hue(color) == True
}

pub fn has_hue_no_chroma_test() {
  let color = oklch.oklch(0.5, 0.0, 180.0, 1.0)
  // Gray color has no meaningful hue
  assert oklch.has_hue(color) == False
}

pub fn has_hue_almost_zero_chroma_test() {
  let color = oklch.oklch(0.5, 0.0001, 180.0, 1.0)
  // Very small chroma still has a hue
  assert oklch.has_hue(color) == True
}

// =============================================================================
// CSS SERIALIZATION TESTS
// =============================================================================

pub fn oklch_to_css_basic_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let css = oklch.oklch_to_css(color)
  assert css == "oklch(50% 0.2 180deg)"
}

pub fn oklch_to_css_high_chroma_test() {
  // Chroma can exceed 0.4 (no clamping)
  let color = oklch.oklch(0.5, 0.6, 180.0, 1.0)
  let css = oklch.oklch_to_css(color)
  assert css == "oklch(50% 0.6 180deg)"
}

pub fn oklch_to_css_with_alpha_test() {
  let color = oklch.oklch(0.5, 0.2, 180.0, 0.5)
  let css = oklch.oklch_to_css(color)
  assert css == "oklch(50% 0.2 180deg / 0.5)"
}

pub fn oklch_to_css_no_hue_test() {
  // Gray color has no hue, outputs "none"
  let color = oklch.oklch(0.5, 0.0, 0.0, 1.0)
  let css = oklch.oklch_to_css(color)
  assert css == "oklch(50% 0 none)"
}

pub fn oklch_to_css_no_hue_with_alpha_test() {
  let color = oklch.oklch(0.5, 0.0, 0.0, 0.5)
  let css = oklch.oklch_to_css(color)
  assert css == "oklch(50% 0 none / 0.5)"
}

pub fn oklch_to_css_white_test() {
  let color = oklch.oklch(1.0, 0.0, 0.0, 1.0)
  let css = oklch.oklch_to_css(color)
  assert css == "oklch(100% 0 none)"
}

pub fn oklch_to_css_black_test() {
  let color = oklch.oklch(0.0, 0.0, 0.0, 1.0)
  let css = oklch.oklch_to_css(color)
  assert css == "oklch(0% 0 none)"
}

pub fn oklch_to_css_precision_test() {
  // Test with values that require rounding
  let color = oklch.oklch(0.7534, 0.2567, 45.3, 1.0)
  let css = oklch.oklch_to_css(color)
  assert css == "oklch(75% 0.26 45deg)"
}

// =============================================================================
// GAMUT MAPPING TESTS
// =============================================================================

pub fn oklch_to_rgb_in_gamut_test() {
  // Color already in gamut should return reasonable RGB values
  let color = oklch.oklch(0.5, 0.2, 180.0, 1.0)
  let rgb = oklch.oklch_to_rgb(color)
  // Verify RGB values are in valid range
  let Rgb(r, g, b, a) = rgb
  assert r >=. 0.0 && r <=. 1.0
  assert g >=. 0.0 && g <=. 1.0
  assert b >=. 0.0 && b <=. 1.0
  assert a == 1.0
}

pub fn oklch_to_rgb_out_of_gamut_test() {
  // High chroma color that exceeds sRGB should be gamut mapped
  let color = oklch.oklch(0.5, 0.5, 180.0, 1.0)
  let rgb = oklch.oklch_to_rgb(color)
  // All RGB components should be in valid range
  let Rgb(r, g, b, a) = rgb
  assert r >=. 0.0 && r <=. 1.0
  assert g >=. 0.0 && g <=. 1.0
  assert b >=. 0.0 && b <=. 1.0
  assert a == 1.0
}

pub fn oklch_to_rgb_white_test() {
  // Lightness >= 100% should return white
  let color = oklch.oklch(1.0, 0.5, 180.0, 1.0)
  let rgb = oklch.oklch_to_rgb(color)
  let Rgb(r, g, b, a) = rgb
  assert r == 1.0
  assert g == 1.0
  assert b == 1.0
  assert a == 1.0
}

pub fn oklch_to_rgb_black_test() {
  // Lightness <= 0% should return black
  let color = oklch.oklch(0.0, 0.5, 180.0, 1.0)
  let rgb = oklch.oklch_to_rgb(color)
  let Rgb(r, g, b, a) = rgb
  assert r == 0.0
  assert g == 0.0
  assert b == 0.0
  assert a == 1.0
}

pub fn oklch_to_rgb_clamped_test() {
  // Old behavior: simple clamp should work
  let color = oklch.oklch(0.5, 0.5, 180.0, 1.0)
  let rgb = oklch.oklch_to_rgb_clamped(color)
  // Just verify it works and returns valid RGB
  let Rgb(r, g, b, a) = rgb
  assert r >=. 0.0 && r <=. 1.0
  assert g >=. 0.0 && g <=. 1.0
  assert b >=. 0.0 && b <=. 1.0
  assert a == 1.0
}

pub fn gamut_mapping_preserves_hue_test() {
  // Verify that gamut mapping preserves hue approximately
  let color = oklch.oklch(0.5, 0.6, 120.0, 1.0)
  let rgb = oklch.oklch_to_rgb(color)
  let back_to_oklch = oklch.rgb_to_oklch(rgb)
  // Hue should be approximately preserved (within 30 degrees tolerance)
  assert float.loosely_equals(back_to_oklch.h, with: 120.0, tolerating: 30.0)
}

pub fn gamut_mapping_preserves_lightness_test() {
  // Verify that gamut mapping preserves lightness
  let color = oklch.oklch(0.7, 0.5, 180.0, 1.0)
  let rgb = oklch.oklch_to_rgb(color)
  let back_to_oklch = oklch.rgb_to_oklch(rgb)
  // Lightness should be approximately preserved
  assert float.loosely_equals(back_to_oklch.l, with: 0.7, tolerating: 0.1)
}

pub fn gamut_mapping_with_alpha_test() {
  // Gamut mapping should preserve alpha
  let color = oklch.oklch(0.5, 0.6, 180.0, 0.5)
  let rgb = oklch.oklch_to_rgb(color)
  let Rgb(r: _, g: _, b: _, alpha: a) = rgb
  assert a == 0.5
}
