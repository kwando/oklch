import gleam/io
import gleam/result
import oklch

pub fn main() {
  let assert Ok(a) =
    oklch.hex_to_rgb("#00FF00")
    |> echo
    |> result.map(oklch.rgb_to_oklch)
  let assert Ok(b) =
    oklch.hex_to_rgb("#0000FF")
    |> echo
    |> result.map(oklch.rgb_to_oklch)

  oklch.ansi_bg(a, "HELLO WORLD")
  |> io.println()

  oklch.ansi_bg(b, "HELLO WORLD")
  |> io.println()
}
