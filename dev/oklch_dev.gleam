import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import oklch

pub fn main() {
  let assert Ok(a) =
    oklch.hex_to_rgb("#660000")
    |> result.map(oklch.rgb_to_oklch)
    |> result.map(oklch.rotate_hue(_, 180.0))
  let assert Ok(b) =
    oklch.hex_to_rgb("#000066")
    |> result.map(oklch.rgb_to_oklch)

  oklch.ansi_bg(a, "HELLO WORLD")
  |> io.println()

  oklch.ansi_bg(b, "HELLO WORLD")
  |> io.println()

  gradient(
    "This is a very long line that should show off the gradient pretty well",
    a,
    b,
  )
  |> io.println()

  let assert Ok(colors) = palette("#993399", 7)
  colors
  |> list.map(fn(color) { oklch.ansi_bg(color, "  ") })
  |> string.concat()
  |> io.println()
}

fn gradient(text, col1, col2) {
  let chars = string.to_graphemes(text)
  let splits = list.length(chars) - 1

  list.index_map(chars, fn(char, index) {
    let alpha = int.to_float(index) /. int.to_float(splits)
    let color = oklch.mix(col1, col2, alpha)
    oklch.ansi_bg(color, char)
  })
  |> string.join("")
}

fn palette(hex, number_of_colors: Int) {
  use color <- result.try(oklch.hex_to_oklch(hex))

  let diff = 360.0 /. int.to_float(number_of_colors)

  int.range(0, number_of_colors - 1, [], fn(acc, index) {
    [oklch.rotate_hue(color, int.to_float(index) *. diff), ..acc]
  })
  |> Ok
}
