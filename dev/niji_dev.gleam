import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam_community/colour
import niji

pub fn main() {
  let a = niji.oklch(0.4, 0.2, 0.0, 1.0)
  let #(b, c) = niji.triadic(a)

  io.println("Light / Darken")
  darken_lighten(a)
  darken_lighten(b)
  darken_lighten(c)

  darken_lighten(colour.pink |> niji.oklch_from_colour)
  darken_lighten(colour.red |> niji.oklch_from_colour)
  darken_lighten(colour.blue |> niji.oklch_from_colour)
  darken_lighten(colour.green |> niji.oklch_from_colour |> niji.darken(0.2))

  io.println("Hue rotation")

  hue_rotatation(a |> niji.darken(0.2))
  hue_rotatation(a |> niji.darken(0.1))
  hue_rotatation(a |> niji.darken(0.0))
  hue_rotatation(a |> niji.lighten(0.1))
  hue_rotatation(a |> niji.lighten(0.2))
  hue_rotatation(a |> niji.lighten(0.3))
  hue_rotatation(a |> niji.lighten(0.4))
  hue_rotatation(a |> niji.lighten(0.5))

  // ----------------------------------------------------------------
  io.println("Gradients")
  let text =
    "This is a very long line that should show off the gradient pretty well"
  let grardient_length = 80
  let tokens = string.to_graphemes(text)

  niji.gradient_fold(c, a, grardient_length, [], fn(tokens, color) {
    [niji.ansi_bg(" ", color), ..tokens]
  })
  |> string.concat
  |> io.println

  niji.gradient_fold(
    c,
    niji.invert_full(c) |> niji.desaturate(0.5) |> niji.lighten(-0.3),
    grardient_length,
    [],
    fn(tokens, color) { [niji.ansi_bg(" ", color), ..tokens] },
  )
  |> string.concat
  |> io.println

  let text = string.repeat(" ", grardient_length)
  { gradient(text, from_hex("#FC5C7D"), from_hex("#6A82FB")) |> io.println }
  { gradient(text, from_hex("#23074d"), from_hex("#cc5333")) |> io.println }
  { gradient(text, from_hex("#fffbd5"), from_hex("#b20a2c")) |> io.println }
  { gradient(text, from_hex("#D3CCE3"), from_hex("#b20a2c")) |> io.println }
  { gradient(text, from_hex("#00F260"), from_hex("#0575E6")) |> io.println }
  { gradient(text, from_hex("#fc4a1a"), from_hex("#f7b733")) |> io.println }
  { gradient(text, from_hex("#22c1c3"), from_hex("#fdbb2d")) |> io.println }
  { gradient(text, from_hex("#159957"), from_hex("#155799")) |> io.println }
  { gradient(text, from_hex("#000046"), from_hex("#1CB5E0")) |> io.println }

  // ----------------------------------------------------------------
  io.println("Temperature")
  let colors =
    int.range(1, 40, [], fn(acc, i) {
      [niji.temperature(int.to_float(i * 1000)), ..acc]
    })
    |> list.reverse
  colors
  |> list.map(fn(color) { niji.ansi_bg("  ", color) })
  |> string.concat()
  |> io.println()
}

fn gradient(text: String, col1: niji.Oklch, col2: niji.Oklch) -> String {
  let chars = string.to_graphemes(text)
  let splits = list.length(chars) - 1

  list.index_map(chars, fn(char, index) {
    let alpha = int.to_float(index) /. int.to_float(splits)
    let color = niji.mix(col1, col2, alpha)
    niji.ansi_bg(char, color)
  })
  |> string.join("")
}

fn from_hex(hex) {
  let assert Ok(colour) = colour.from_rgb_hex_string(hex)
  niji.oklch_from_colour(colour)
}

fn darken_lighten(color: niji.Oklch) {
  let steps = 7
  let step_size = 0.05
  int.range(-steps, steps + 1, [], fn(acc, x) {
    let amount =
      x
      |> int.to_float()
      |> float.multiply(step_size)

    [#(amount, niji.lighten(color, amount)), ..acc]
  })
  |> list.map(fn(color) {
    niji.ansi_bg(
      case float.loosely_equals(color.0, 0.0, 0.001) {
        True -> " " <> niji.to_hex(color.1) <> " "
        False ->
          " "
          <> color.0
          |> float.to_precision(2)
          |> float.to_string()
          <> " "
      },
      color.1,
    )
  })
  |> list.reverse
  |> string.concat
  |> io.println
}

fn hue_rotatation(color) {
  let steps = 40
  let step_size = 360.0 /. int.to_float(steps)
  int.range(0, steps, [], fn(acc, degree) {
    [
      niji.ansi_bg(
        "  ",
        color |> niji.rotate_hue({ degree |> int.to_float } *. step_size),
      ),
      ..acc
    ]
  })
  |> string.concat
  |> io.println
}
