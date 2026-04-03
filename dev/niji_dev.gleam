import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam_community/colour
import niji

pub fn main() {
  let assert Ok(a) =
    colour.from_rgb_hex_string("#660000")
    |> result.map(niji.from_colour)
    |> result.map(niji.rotate_hue(_, 180.0))
  let assert Ok(b) =
    colour.from_rgb_hex_string("#000066")
    |> result.map(niji.from_colour)

  niji.ansi_bg(a, "HELLO WORLD")
  |> io.println()

  niji.ansi_bg(b, "HELLO WORLD")
  |> io.println()

  gradient(
    "This is a very long line that should show off the gradient pretty well",
    a,
    b,
  )
  |> io.println()

  let assert Ok(colors) = palette("#993399", 7)
  colors
  |> list.map(fn(color) { niji.ansi_bg(color, "  ") })
  |> string.concat()
  |> io.println()
}

fn gradient(text: String, col1: niji.Oklch, col2: niji.Oklch) -> String {
  let chars = string.to_graphemes(text)
  let splits = list.length(chars) - 1

  list.index_map(chars, fn(char, index) {
    let alpha = int.to_float(index) /. int.to_float(splits)
    let color = niji.mix(col1, col2, alpha)
    niji.ansi_bg(color, char)
  })
  |> string.join("")
}

fn palette(hex: String, number_of_colors: Int) -> Result(List(niji.Oklch), Nil) {
  use parsed <- result.try(colour.from_rgb_hex_string(hex))
  let color = niji.from_colour(parsed)

  let diff = 360.0 /. int.to_float(number_of_colors)

  int.range(0, number_of_colors - 1, [], fn(acc, index) {
    [niji.rotate_hue(color, int.to_float(index) *. diff), ..acc]
  })
  |> list.reverse
  |> Ok
}
