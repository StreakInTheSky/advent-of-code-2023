import gleam/string
import gleam/list
import gleam/int
import gleam/result
//import gleam/io

pub fn pt_1(input: String) {
  let lines = string.split(input, "\n")
  lines
  |> list.map(get_digits)
  |> list.reduce(int.add)
}

fn get_digits(line: String) {
  let assert Ok(start) = string.first(line)
  let assert Ok(last) = string.last(line)
  case int.parse(start), int.parse(last) {
    Ok(first), Ok(second) -> first * 10 + second
    Ok(_), Error(_) -> get_digits(string.drop_right(line, 1))
    Error(_), Ok(_) -> get_digits(string.drop_left(line, 1))
    _, _ -> {
      line
      |> string.drop_right(1)
      |> string.drop_left(1)
      |> get_digits
    }
  }
}

pub fn pt_2(input: String) {
  let words = [#("one", 1), #("two", 2), #("three", 3), #("four", 4), #("five", 5), #("six", 6), #("seven", 7), #("eight", 8), #("nine", 9)]
  let lines = string.split(input, "\n")
  lines
  |> list.map(fn(line){get_digits_two(line, words)})
  |> list.reduce(int.add)
}

fn get_digits_two(line: String, words) {
  case check_start(line, words), check_end(line, words) {
    Ok(first), Ok(second) -> first * 10 + second
    Ok(_), Error(_) -> get_digits_two(string.drop_right(line, 1), words)
    Error(_), Ok(_) -> get_digits_two(string.drop_left(line, 1), words)
    _, _ -> {
      line
      |> string.drop_right(1)
      |> string.drop_left(1)
      |> get_digits_two(words)
    }
  }
}

fn check_end(line, words: List(#(String, Int))) {
  let assert Ok(end) = string.last(line)
  case int.parse(end) {
    Ok(end) -> Ok(end)
    Error(_) -> {
      list.find(words, fn(word) { string.ends_with(line, word.0) })
      |> result.map(fn(word){word.1})
    }
  }
} 

fn check_start(line, words: List(#(String, Int))) {
  let assert Ok(start) = string.first(line)
  case int.parse(start) {
    Ok(start) -> Ok(start)
    Error(_) -> {
      list.find(words, fn(word) { string.starts_with(line, word.0) })
      |> result.map(fn(word){word.1})
    }
  }
}
