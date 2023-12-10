import gleam/result
import gleam/list
import gleam/string
import gleam/set.{type Set}
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}

type Coordinate =
  #(Int, Int)

type Grid =
  Dict(Coordinate, String)

type State {
  State(
    grid: Grid,
    current_position: Coordinate,
    visited: Set(Coordinate),
    steps: Int,
  )
}

fn init_state(input: String) -> State {
  let grid = parse_grid(input)

  let assert Ok(start_position) =
    grid
    |> dict.keys
    |> list.find(fn(key) {
      case dict.get(grid, key) {
        Ok("S") -> True
        _ -> False
      }
    })

  State(grid, start_position, set.new(), 0)
}

fn parse_grid(input: String) -> Grid {
  input
  |> string.split("\n")
  |> list.index_fold(
    dict.new(),
    fn(grid, row, i) {
      row
      |> string.to_graphemes
      |> list.index_map(fn(j, pipe) {
        case pipe {
          "." -> #(#(-1, -1), ".")
          _ -> #(#(i, j), pipe)
        }
      })
      |> dict.from_list
      |> dict.merge(grid)
    },
  )
}

fn step(state: State) -> State {
  let State(grid, current_position, ..) = state
  let assert Ok(pipe) = dict.get(grid, current_position)
  case pipe {
    "|" -> n_or_s(state)
    "-" -> e_or_w(state)
    "L" -> n_or_e(state)
    "J" -> n_or_w(state)
    "7" -> s_or_w(state)
    "F" -> s_or_e(state)
  }
}

fn move(direction1: Coordinate, or direction2: Option(Coordinate)) {
  fn(state: State) -> State {
    let State(grid, current_position, visited, steps) = state

    let visited = set.insert(visited, current_position)

    let #(i, j) = current_position
    let a = #(i + direction1.0, j + direction1.1)

    case set.contains(visited, a), direction2 {
      True, Some(#(di, dj)) -> {
        let b = #(i + di, j + dj)
        case set.contains(visited, b) {
          // back at start
          True -> go_to_start(state, a, b)
          False -> State(grid, b, visited, steps + 1)
        }
      }
      False, _ -> State(grid, a, visited, steps + 1)
      True, None -> panic
    }
  }
}

const n = #(-1, 0)

const s = #(1, 0)

const e = #(0, 1)

const w = #(0, -1)

fn n_or_s(state) {
  move(n, Some(s))(state)
}

fn e_or_w(state) {
  move(e, Some(w))(state)
}

fn n_or_e(state) {
  move(n, Some(e))(state)
}

fn n_or_w(state) {
  move(n, Some(w))(state)
}

fn s_or_w(state) {
  move(s, Some(w))(state)
}

fn s_or_e(state) {
  move(s, Some(e))(state)
}

fn start(state: State) -> Int {
  let State(grid, current_position, ..) = state
  let #(i, j) = current_position
  let n_pipe = result.unwrap(dict.get(grid, #(i + n.0, j + n.1)), ".")
  let s_pipe = result.unwrap(dict.get(grid, #(i + s.0, j + s.1)), ".")
  let e_pipe = result.unwrap(dict.get(grid, #(i + e.0, j + e.1)), ".")
  let w_pipe = result.unwrap(dict.get(grid, #(i + w.0, j + w.1)), ".")

  case n_pipe, s_pipe, e_pipe, w_pipe {
    p, _, _, _ if p == "|" || p == "7" || p == "F" -> go(move(n, None)(state))
    _, p, _, _ if p == "|" || p == "J" || p == "L" -> go(move(s, None)(state))
    _, _, p, _ if p == "-" || p == "7" || p == "J" -> go(move(e, None)(state))
    _, _, _, p if p == "-" || p == "F" || p == "L" -> go(move(w, None)(state))
    _, _, _, _ -> panic
  }
}

fn go(state: State) -> Int {
  let next_step = step(state)
  let State(grid, current_position: next_position, ..) = next_step
  let assert Ok(next_pipe) = dict.get(grid, next_position)
  case next_pipe {
    "S" -> next_step.steps
    _ -> go(next_step)
  }
}

fn go_to_start(state: State, a: Coordinate, b: Coordinate) -> State {
  let State(grid, steps: steps, ..) = state

  let a_pipe = dict.get(grid, a)
  let b_pipe = dict.get(grid, b)
  case a_pipe, b_pipe {
    Ok("S"), _ -> State(..state, current_position: a, steps: steps + 1)
    _, Ok("S") -> State(..state, current_position: b, steps: steps + 1)
  }
}

pub fn pt_1(input: String) {
  input
  |> init_state
  |> start
  |> fn(steps) { steps / 2 }
}

pub fn pt_2(input: String) {
  todo
}
