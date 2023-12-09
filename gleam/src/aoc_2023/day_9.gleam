import gleam/result
import gleam/int
import gleam/regex
import gleam/string
import gleam/list

fn parse_data(input: String) {
  let assert Ok(re) = regex.from_string("\\s+")

  input
  |> string.split("\n")
  |> list.map(fn(line) {
    re
    |> regex.split(line)
    |> list.map(int.parse)
    |> result.values
  })
}

fn calculate(data: List(Int)) -> Int {
  case list.all(data, fn(v) { v == 0 }) {
    True -> 0
    False -> {
      let assert Ok(first) = list.first(data)
      let assert Ok(rest) = list.rest(data)
      let diffs = get_diffs(rest, first, list.new())
      let to_add =
        diffs
        |> list.reverse
        |> calculate

      first + to_add
    }
  }
}

fn get_diffs(data: List(Int), prev: Int, diffs: List(Int)) -> List(Int) {
  case data {
    [last] -> [prev - last, ..diffs]
    [first, ..rest] -> get_diffs(rest, first, [prev - first, ..diffs])
  }
}

pub fn pt_1(input: String) {
  input
  |> parse_data
  |> list.map(list.reverse)
  |> list.map(calculate)
  |> int.sum
}

pub fn pt_2(input: String) {
  input
  |> parse_data
  |> list.map(calculate)
  |> int.sum
}
