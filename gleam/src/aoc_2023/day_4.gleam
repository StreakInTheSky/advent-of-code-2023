import gleam/set
import gleam/list
import gleam/int
import gleam/string
import gleam/result
import gleam/option.{Some, None}
import gleam/float
import gleam/dict.{type Dict}

type Card {
  Card(id: Int, match_count: Int)
}

fn parse_card(line: String) -> Card {
  let assert "Card" <> game_str = line
  let assert [id_str, numbers_str] = string.split(game_str, ": ")
  let assert [winning_str, player_str] = string.split(numbers_str, " | ")

  let assert Ok(id) = id_str
  |> string.trim_left
  |> int.parse

  let winning_numbers = winning_str
  |> string.split(" ")
  |> list.map(int.parse)
  |> result.values
  |> set.from_list

  let player_numbers = player_str
  |> string.split(" ")
  |> list.map(int.parse)
  |> result.values
  |> set.from_list
  
  let match_count = set.intersection(winning_numbers, player_numbers)
  |> set.size

  Card(id, match_count)
}

fn get_score(card: Card) -> Result(Int, Nil) {
  card.match_count
  |> int.to_float
  |> fn(count){int.power(2, of: count -. 1.0)}
  |> result.map(float.round)
}

fn update_count(counts: Dict(Int, Int), id: Int, by amount_to_add: Int) -> Dict(Int, Int) {
  dict.update(counts, id, fn(count) {
    case count {
      Some(count) -> count+amount_to_add
      None -> amount_to_add
    }
  })
}

fn get_duplicates(cards: List(Card), counts: Dict(Int, Int)) -> Dict(Int, Int) {
  case cards {
    [card] -> update_count(counts, card.id, 1)
    [card, ..rest] -> {
      let with_current = update_count(counts, card.id, 1)

      let to_add = case card.match_count {
        0 -> []
        _ -> list.range(card.id+1, card.id + card.match_count)
      }

      let new_counts = list.fold(to_add, with_current, fn(counts, id) {
        let assert Ok(duplicate_count) = dict.get(counts, card.id)
        update_count(counts, id, duplicate_count)
      })

      get_duplicates(rest, new_counts)
    }
  }
}

pub fn pt_1(input: String) {
  input
  |> string.split("\n")
  |> list.map(parse_card)
  |> list.filter(fn(card){card.match_count>0})
  |> list.map(get_score)
  |> result.values
  |> int.sum
}

pub fn pt_2(input: String) {
  input
  |> string.split("\n")
  |> list.map(parse_card)
  |> get_duplicates(dict.new())
  |> dict.values
  |> int.sum 
}
