import gleam/option.{Some}
import gleam/result
import gleam/function
import gleam/list
import gleam/dict.{type Dict}
import gleam/regex
import gleam/string
import gleam/int

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
  let starting_nodes =
    instructions.1
    |> dict.keys
    |> list.filter(fn(node) {
      case string.to_graphemes(node) {
        [_, _, "A"] -> True
        _ -> False
      }
    })

  starting_nodes
  |> list.map(fn(node) { count_to_z(instructions, 0, 0, node) })
  |> lcm
}

fn lcm(nums) -> Int {
  nums
  |> list.map(fn(n) { #(n, n) })
  |> dict.from_list
  |> do_lcm
}

fn do_lcm(nums: Dict(Int, Int)) -> Int {
  let values = dict.values(nums)
  let assert Ok(max) = list.reduce(values, fn(a, b) { int.max(a, b) })
  case
    values
    |> list.all(fn(value) { max % value == 0 })
  {
    True -> max
    False -> {
      nums
      |> fn(nums) {
        let assert Ok(max_key) =
          list.find(
            dict.keys(nums),
            fn(key) {
              let assert Ok(value) = dict.get(nums, key)
              value == max
            },
          )

        dict.update(
          nums,
          max_key,
          fn(value) {
            let assert Some(value) = value
            value + max_key
          },
        )
      }
      |> do_lcm
    }
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
