import gleam/result
import gleam/string
import gleam/list
import gleam/regex
import gleam/int
import gleam/function
import gleam/order.{type Order, Gt, Lt, Eq}
import gleam/dict.{type Dict}
import gleam/option.{type Option, Some, None}

pub opaque type Hand{
  Five(cards: List(String))
  Four(cards: List(String))
  Full(cards: List(String))
  Three(cards: List(String))
  TwoPair(cards: List(String))
  OnePair(cards: List(String))
  High(cards: List(String))
}

fn rank_hand(hand: Hand) -> Int {
  case hand {
    Five(_) -> 6
    Four(_) -> 5
    Full(_) -> 4
    Three(_) -> 3
    TwoPair(_) -> 2
    OnePair(_) -> 1
    High(_) -> 0
  }
}

fn rank_card(card: String, joker: Bool) -> Int {
  case card {
    "A" -> 14
    "K" -> 13
    "Q" -> 12
    "J" -> {
      case joker {
        True -> 1
        False -> 11
      }
    }
    "T" -> 10
    n   -> {
      let assert Ok(n) = int.parse(n)
      n
    }
  }
}

fn compare_hand(hand1: Hand, hand2: Hand, wild joker: Bool) -> Order {
  case int.compare(rank_hand(hand1), rank_hand(hand2)) {
    Eq -> compare_cards(hand1.cards, hand2.cards, joker)
    Lt -> Lt
    Gt -> Gt
  }
}

fn compare_cards(cards1: List(String), cards2: List(String),joker: Bool) -> Order {
  case cards1, cards2 {
    [one, ..rest1], [two, ..rest2] -> {
      case int.compare(rank_card(one, joker), rank_card(two , joker)) {
        Eq -> compare_cards(rest1, rest2, joker)
        Lt -> Lt
        Gt -> Gt
      }
    }
  }
}

fn get_hand(cards: List(String), wild joker: Bool) -> Hand {
  count_cards(cards)
  |> five
  |> result.try_recover(four)
  |> result.try_recover(full)
  |> result.try_recover(three)
  |> result.try_recover(two_pair)
  |> result.try_recover(one_pair)
  |> result.map_error(high)
  |> result.map(upgrade(joker))
  |> result.map_error(upgrade(joker))
  |> result.unwrap_both
}

fn count_cards(cards: List(String)) -> #(Dict(String, Int), List(String)) {
  let counts = {
    use counts, card <- list.fold(cards, dict.new())
    use value <- dict.update(counts, card)
    case value {
      Some(n) -> n+1
      None -> 1
    }
  }

  #(counts, cards)
}

fn upgrade(joker: Bool) -> fn(Hand) -> Hand { 
  case joker {
    False -> function.identity
    True -> upgrade_hand
  }
}

fn upgrade_hand(hand: Hand) -> Hand {
  case hand {
    Four(cards) -> upgrade_four(count_cards(cards))
    Full(cards) -> upgrade_full(count_cards(cards))
    Three(cards) -> upgrade_three(count_cards(cards))
    TwoPair(cards) -> upgrade_two_pair(count_cards(cards))
    OnePair(cards) -> upgrade_one_pair(count_cards(cards))
    High(cards) -> upgrade_high(count_cards(cards))
    Five(_) -> hand
  }
}

fn five(card_counts: #(Dict(String, Int), List(String))) -> Result(Hand, #(Dict(String, Int), List(String))) {
  case card_counts.0 |> dict.values |> list.contains(5) {
    True -> Ok(Five(card_counts.1))
    False -> Error(card_counts)
  }
}

fn four(card_counts: #(Dict(String, Int), List(String))) -> Result(Hand, #(Dict(String, Int), List(String))) {
  case card_counts.0 |> dict.values |> list.contains(4) {
    True -> Ok(Four(card_counts.1))
    False -> Error(card_counts)
  }
}

fn full(card_counts: #(Dict(String, Int), List(String))) -> Result(Hand, #(Dict(String, Int), List(String))) {
  let is_full = card_counts.0
  |> dict.values
  |> fn(values) {list.contains(values, 3) && list.contains(values, 2)}
  case is_full {
    True -> Ok(Full(card_counts.1))
    False -> Error(card_counts)
  }
}

fn three(card_counts: #(Dict(String, Int), List(String))) -> Result(Hand, #(Dict(String, Int), List(String))) {
  case card_counts.0 |> dict.values |> list.contains(3) {
    True -> Ok(Three(card_counts.1))
    False -> Error(card_counts)
  }
}

fn two_pair(card_counts: #(Dict(String, Int), List(String))) -> Result(Hand, #(Dict(String, Int), List(String))) {
  card_counts.0
  |> dict.values
  |> list.filter(fn(count) { count == 2 })
  |> list.length
  |> fn(length){
    case length == 2 {
      True -> Ok(TwoPair(card_counts.1))
      False -> Error(card_counts)
    }
  }
}

fn one_pair(card_counts: #(Dict(String, Int), List(String))) -> Result(Hand, #(Dict(String, Int), List(String))) {
  case card_counts.0 |> dict.values |> list.contains(2) {
    True -> Ok(OnePair(card_counts.1))
    False -> Error(card_counts)
  }
}

fn high(card_counts: #(Dict(String, Int), List(String))) -> Hand {
  High(card_counts.1)
}

fn upgrade_four(card_counts: #(Dict(String, Int), List(String))) -> Hand {
  case dict.has_key(card_counts.0, "J") {
    True -> Five(card_counts.1)
    False -> Four(card_counts.1)
  }
}

fn upgrade_full(card_counts: #(Dict(String, Int), List(String))) -> Hand {
    case dict.has_key(card_counts.0, "J") {
      True -> Five(card_counts.1)
      False -> Full(card_counts.1)
    }
}

fn upgrade_three(card_counts: #(Dict(String, Int), List(String))) -> Hand {
    case dict.has_key(card_counts.0, "J") {
      True -> Four(card_counts.1)
      False -> Three(card_counts.1)
    }
}

fn upgrade_two_pair(card_counts: #(Dict(String, Int), List(String))) -> Hand {
    case dict.get(card_counts.0, "J") {
      Ok(2) -> Four(card_counts.1)
      Ok(1) -> Full(card_counts.1)
      _ -> TwoPair(card_counts.1)
    }
}

fn upgrade_one_pair(card_counts: #(Dict(String, Int), List(String))) -> Hand {
    case dict.has_key(card_counts.0, "J") {
      True -> Three(card_counts.1)
      False -> OnePair(card_counts.1)
    }
}

fn upgrade_high(card_counts: #(Dict(String, Int), List(String))) -> Hand {
  case dict.has_key(card_counts.0, "J") {
    True -> OnePair(card_counts.1)
    False -> High(card_counts.1)
  }
}

fn parse_input(input: String,wild joker: Bool) -> List(#(Hand, Int)) {
  input
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert Ok(re) = regex.from_string("\\s+")

    let assert Ok(hand_and_bet) = re
    |> regex.split(line)
    |> list.combination_pairs
    |> list.first
    |> result.map(fn(hand_and_bet) {
      let #(hand, bet) = hand_and_bet
      let assert Ok(bet) = int.parse(bet)
      #(get_hand(string.to_graphemes(hand), joker), bet)
    })

    hand_and_bet
  })
}

pub fn pt_1(input: String) {
  input
  |> parse_input(wild: False)
  |> list.sort(fn(hb1,hb2){compare_hand(hb1.0, hb2.0, wild: False)})
  |> list.index_fold(0, fn(points, hb, i){ points + hb.1 * {i+1} })
}

pub fn pt_2(input: String) {
  input
  |> parse_input(wild: True)
  |> list.sort(fn(hb1,hb2){compare_hand(hb1.0, hb2.0, wild: True)})
  |> list.index_fold(0, fn(points, hb, i){ points + hb.1 * {i+1} })
}
