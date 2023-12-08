import gleam/result
import gleam/function
import gleam/list
import gleam/regex
import gleam/string
import gleam/dict.{type Dict}

type Instructions =
  #(List(String), Dict(String, #(String, String)))

fn parse_instructions(input: String) -> Instructions {
  let [directions_string, map_string] = string.split(input, "\n\n")

  let directions = string.to_graphemes(directions_string)

  let map =
    map_string
    |> string.split("\n")
    |> list.map(fn(line) {
      let [key, directions_string] = string.split(line, " = ")

      let assert Ok(re) = regex.from_string("[A-Z|0-9]+")
      let [left, right] =
        re
        |> regex.scan(directions_string)
        |> list.map(fn(match) { match.content })

      #(key, #(left, right))
    })
    |> dict.from_list

  #(directions, map)
}

fn steps_to_z(instructions: Instructions) -> Int {
  count_to_z(instructions, 0, 0, "AAA")
}

fn count_to_z(instructions, directions_index, steps, current) {
  case string.to_graphemes(current) {
    [_, _, "Z"] -> steps
    _ -> {
      let #(directions, map) = instructions
      let n = list.length(directions)
      let move_next =
        function.curry4(count_to_z)(instructions)({ directions_index + 1 } % n)(
          steps + 1,
        )
      case list.at(directions, directions_index) {
        Ok("L") -> move_next(move_left(map, current))
        Ok("R") -> move_next(move_right(map, current))
        _ -> panic
      }
    }
  }
}

fn move_left(map: Dict(String, #(String, String)), current: String) {
  let assert Ok(next) =
    map
    |> dict.get(current)
    |> result.map(fn(value) { value.0 })

  next
}

fn move_right(map: Dict(String, #(String, String)), current: String) {
  let assert Ok(next) =
    map
    |> dict.get(current)
    |> result.map(fn(value) { value.1 })

  next
}

fn ghost_steps_to_z(instructions: Instructions) -> Int {
  instructions.1
  |> dict.keys
  |> list.filter(fn(node) {
    case string.to_graphemes(node) {
      [_, _, "A"] -> True
      _ -> False
    }
  })
  |> list.map(fn(node) { count_to_z(instructions, 0, 0, node) })
  |> lcm
}

fn lcm(nums: List(Int)) -> Int {
  let assert Ok(n) = list.reduce(nums, fn(a, b) { a * b / gcd(a, b) })
  n
}

fn gcd(a: Int, b: Int) -> Int {
  case a {
    0 -> b
    _ -> gcd(b % a, a)
  }
}

pub fn pt_1(input: String) {
  input
  |> parse_instructions
  |> steps_to_z
}

pub fn pt_2(input: String) {
  input
  |> parse_instructions
  |> ghost_steps_to_z
}
