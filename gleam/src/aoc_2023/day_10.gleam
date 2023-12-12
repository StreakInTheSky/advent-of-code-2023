import gleam/int
import gleam/result
import gleam/list
import gleam/string
import gleam/set.{type Set}
import gleam/dict.{type Dict}
import gleam/order.{Lt, Gt, Eq}

type Coordinate = #(Int, Int)

type Grid =
  Dict(Coordinate, String)

type Direction {
  N
  E
  W
  S
  Start
}

type Position {
  Position(coordinate: Coordinate, direction: Direction)
}

type State {
  State(
    grid: Grid,
    current_position: Position,
    visited: Set(Coordinate),
    right: Set(Coordinate),
    left: Set(Coordinate),
  )
}


fn init_state(input: String) -> State {
  let grid = parse_grid(input)

  let assert Ok(start_coordinate) =
    grid
    |> dict.keys
    |> list.find(fn(key) {
      case dict.get(grid, key) {
        Ok("S") -> True
        _ -> False
      }
    })

  State(grid: grid, current_position: Position(start_coordinate, Start), visited: set.new(), right: set.new(), left: set.new())
}

fn parse_grid(input: String) -> Grid {
  input
  |> string.split("\n")
  |> list.index_fold(
    dict.new(),
    fn(grid, row, i) {
      row
      |> string.to_graphemes
      |> list.index_map(fn(j, pipe) {#(#(i, j), pipe)})
      |> dict.from_list
      |> dict.merge(grid)
    },
  )
}

fn step(state: State) -> State {
  let State(grid, current_position, ..) = state
  let Position(current_coordinate, direction) = current_position
  let assert Ok(pipe) = dict.get(grid, current_coordinate)
  case pipe, direction{
    "|", N -> move_n(state)
    "|", S -> move_s(state)
    "-", E -> move_e(state)
    "-", W -> move_w(state)
    "L", S -> move_e(state)
    "L", W -> move_n(state)
    "J", S -> move_w(state)
    "J", E -> move_n(state)
    "7", E -> move_s(state)
    "7", N -> move_w(state)
    "F", W -> move_s(state)
    "F", N -> move_e(state)
    _, _ -> panic
  }
}

fn move(movement: #(Int, Int, Direction)) {
  fn(state: State) -> State {
    let State(grid: grid, current_position: current_position, visited: visited, ..) = state
    let Position(current_coordinate, ..) = current_position

    let visited = set.insert(visited, current_coordinate)
    let #(left_neighbors, right_neighbors) =
      state
      |> add_neighbors
      |> fn(neighbors: #(Set(Coordinate), Set(Coordinate))) {
        // add neighbors when turning
        let exit_position = Position(current_coordinate, movement.2)
        State(..state, current_position: exit_position, left: neighbors.0, right: neighbors.1)
      }
      |> add_neighbors

    let #(i, j) = current_coordinate
    let new_position = Position(#(i + movement.0, j + movement.1), movement.2)
    State(grid: grid, current_position: new_position, visited: visited, left: left_neighbors, right: right_neighbors)
  }
}

const n = #(-1, 0, N)

const s = #(1, 0, S)

const e = #(0, 1, E)

const w = #(0, -1, W)

fn move_n(state) {
  move(n)(state)
}

fn move_e(state) {
  move(e)(state)
}

fn move_w(state) {
  move(w)(state)
}

fn move_s(state) {
  move(s)(state)
}


fn add_neighbors(state: State) {
  let State(grid: grid, current_position: position, left: left, right: right, ..) = state
  let Position(coordinate, direction) = position

  case direction {
    N -> #(add_neighbor(grid, left, coordinate, w), add_neighbor(grid, right, coordinate, e))
    E -> #(add_neighbor(grid, left, coordinate, n), add_neighbor(grid, right, coordinate, s))
    W -> #(add_neighbor(grid, left, coordinate, s), add_neighbor(grid, right, coordinate, n))
    S -> #(add_neighbor(grid, left, coordinate, e), add_neighbor(grid, right, coordinate, w))
    _ -> #(left, right)
  }
}

fn add_neighbor(grid: Grid, neighbors: Set(Coordinate), coordinate: Coordinate, direction: #(Int, Int, Direction)) {
  let neighbor = #(coordinate.0 + direction.0, coordinate.1 + direction.1)
  case dict.has_key(grid, neighbor) {
    True -> set.insert(neighbors, neighbor)
    False -> neighbors
  }
}

fn start(state: State) -> State {
  let State(grid, current_position, ..) = state
  let Position(#(i, j), ..) = current_position
  let n_pipe = result.unwrap(dict.get(grid, #(i + n.0, j + n.1)), ".")
  let s_pipe = result.unwrap(dict.get(grid, #(i + s.0, j + s.1)), ".")
  let e_pipe = result.unwrap(dict.get(grid, #(i + e.0, j + e.1)), ".")
  let w_pipe = result.unwrap(dict.get(grid, #(i + w.0, j + w.1)), ".")

  case n_pipe, s_pipe, e_pipe, w_pipe {
    p, _, _, _ if p == "|" || p == "7" || p == "F" -> go(move_n(state))
    _, p, _, _ if p == "|" || p == "J" || p == "L" -> go(move_s(state))
    _, _, p, _ if p == "-" || p == "7" || p == "J" -> go(move_e(state))
    _, _, _, p if p == "-" || p == "F" || p == "L" -> go(move_w(state))
    _, _, _, _ -> panic
  }
}

fn go(state: State) -> State {
  let next_step = step(state)
  let State(grid, current_position: next_position, ..) = next_step
  let Position(coordinate: next_coordinate, ..) = next_position
  let assert Ok(next_pipe) = dict.get(grid, next_coordinate)
  case next_pipe {
    "S" -> next_step
    _ -> go(next_step)
  }
}

fn max_distance(state: State) -> Int {
  state
  |> fn(state: State) { set.size(state.visited) }
  |> fn(steps) { steps / 2 }
}

fn count_enclosed(state: State) {
  let State(grid: grid, visited: visited, left: left, right: right, ..) = state

  let left = set.filter(left, fn(v){!set.contains(visited,v)})
  let right = set.filter(right, fn(v){!set.contains(visited,v)})
  let grid_right_bound = 
    grid
    |> dict.keys
    |> list.fold(0, fn(max, coordinate){ int.max(max, coordinate.1)})
  let grid_lower_bound =
    grid
    |> dict.keys
    |> list.fold(0, fn(max, coordinate){ int.max(max, coordinate.0)})

  let enclosed =
    left
    |> set.to_list
    |> list.filter(fn(coordinate) {
      coordinate.0 == 0 || coordinate.0 == grid_right_bound || coordinate.1 == 0 || coordinate.1 == grid_lower_bound
    })
    |> list.length
    |> fn(length){
      case length {
        0 -> left
        _ -> right
      }
    }

  set.size(fill(enclosed, visited))
}

fn fill(coordinates: Set(Coordinate), visited: Set(Coordinate)) -> Set(Coordinate){
  coordinates
  |> set.to_list
  |> list.sort(fn(a,b){
    case int.compare(a.0, b.0) {
      Lt -> Lt
      Gt -> Gt
      Eq -> int.compare(a.1, b.1)
    }
  })
  |> list.group(fn(coordinate) {coordinate.0})
  |> dict.to_list
  |> list.fold(coordinates, fn(enclosed, row){
    row.1
    |> list.fold(enclosed, fn(enclosed, coordinate){
      fill_row(#(coordinate.0, coordinate.1 + 1), enclosed, visited)
    })
  })
}

fn fill_row(coordinate: Coordinate, enclosed: Set(Coordinate), visited: Set(Coordinate)) {
  case set.contains(visited, coordinate) {
    True -> enclosed
    False -> fill_row(#(coordinate.0, coordinate.1 + 1), set.insert(enclosed, coordinate), visited)
  }
}


pub fn pt_1(input: String) {
  input
  |> init_state
  |> start
  |> max_distance
}

pub fn pt_2(input: String) {
  input
  |> init_state
  |> start
  |> count_enclosed
}
