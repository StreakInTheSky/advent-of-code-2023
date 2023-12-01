import gleam/string
import gleam/list
import gleam/int
import gleam/result

pub fn pt_1(input: String) {
  input
  |> string.split("\n")
  |> list.map(fn(line) { 10 * get_first(line) + get_last(line) })
  |> int.sum
}

fn get_first(line: String) {
  let assert Ok(start) = string.first(line)
  case int.parse(start) {
    Ok(digit) -> digit
    _ -> get_first(string.drop_left(line, 1))
  }
}

fn get_last(line: String) {
  let assert Ok(last) = string.last(line)
  case int.parse(last) {
    Ok(digit) -> digit
    _ -> get_last(string.drop_right(line, 1))
  }
}

pub fn pt_2(input: String) {
  let words = [
    #("one", 1),
    #("two", 2),
    #("three", 3),
    #("four", 4),
    #("five", 5),
    #("six", 6),
    #("seven", 7),
    #("eight", 8),
    #("nine", 9),
  ]

  input
  |> string.split("\n")
  |> list.map(fn(line) {
    10 * get_first_2(line, words) + get_last_2(line, words)
  })
  |> int.sum
}

fn get_first_2(line, words: List(#(String, Int))) {
  let assert Ok(start) = string.first(line)
  use <- result.lazy_unwrap(int.parse(start))
  use <- result.lazy_unwrap(
    words
    |> list.find(fn(word) { string.starts_with(line, word.0) })
    |> result.map(fn(word) { word.1 }),
  )
  get_first_2(string.drop_left(line, 1), words)
}

fn get_last_2(line, words: List(#(String, Int))) {
  let assert Ok(end) = string.last(line)
  use <- result.lazy_unwrap(int.parse(end))
  use <- result.lazy_unwrap(
    words
    |> list.find(fn(word) { string.ends_with(line, word.0) })
    |> result.map(fn(word) { word.1 }),
  )
  get_last_2(string.drop_right(line, 1), words)
}
