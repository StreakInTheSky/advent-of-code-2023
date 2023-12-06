import gleam/string
import gleam/regex
import gleam/int
import gleam/result
import gleam/list
import gleam/order

fn parse_race_data(input: String) -> List(#(Int, Int)) {
  input
  |> string.split("\n")
  |> list.map(fn(line){
    let assert Ok(re) = regex.from_string("[0-9]+")
      
    re
    |> regex.scan(line)
    |> list.map(fn(match){match.content})
    |> list.map(int.parse)
    |> result.values
  })
  |> fn(race_lists) {
    let assert [times, records] = race_lists
    list.zip(times, records)
  }
}

fn get_winning_times_and_distances(race_datum: #(Int, Int)) {
  let #(total_time, record) = race_datum
  list.range(1, total_time-1)
  |> list.map(fn(press_time){
    let travel_time = total_time - press_time
    let travel_distance = press_time * travel_time
    #(press_time, travel_distance)
  })
  |> list.filter(fn(race_result){
    race_result.1 > record
  })
}

pub fn pt_1(input: String) {
  input
  |> parse_race_data
  |> list.map(get_winning_times_and_distances)
  |> list.map(list.length)
  |> int.product
}


// Part 2
fn parse_single_race_data(input: String) -> #(Int, Int) {
  let assert [time, record] = input
  |> string.split("\n")
  |> list.map(fn(line){
    let assert Ok(re) = regex.from_string("[0-9]+")
      
    re
    |> regex.scan(line)
    |> list.map(fn(match){match.content})
    |> string.join("")
    |> int.parse
  })
  |> result.values

  #(time, record)
}

fn get_distance(race_time, press_time) {
  let travel_time = race_time - press_time
  press_time * travel_time
}

fn is_win(distance1, distance2) {
  case int.compare(distance1, distance2) {
    order.Lt -> True
    _  -> False
  }
}

fn find_win_start(start, end, race_data) -> Int {
  let #(total_time, record) = race_data

  let mid = {end+start}/2
  let mid_dist = get_distance(total_time, mid)

  let mid_win = is_win(record, mid_dist)

  case mid_win, mid - start {
    True, delta if delta == 1 -> mid
    True, delta if delta > 1 -> find_win_start(start, mid, race_data)
    False, _ -> find_win_start(mid, end, race_data)
  }
}

fn find_win_end(start, end, race_data) -> Int {
  let #(total_time, record) = race_data

  let mid = {end+start}/2
  let mid_dist = get_distance(total_time, mid)

  let mid_win = is_win(record, mid_dist)

  case mid_win, end - mid {
    True, delta if delta == 1 -> mid
    True, delta if delta > 1 -> find_win_end(mid, end, race_data)
    False, _ -> find_win_end(start, mid, race_data)
  }
}

fn get_length_of_wins(race_data: #(Int, Int)) -> Int {
  let start_bound = find_win_start(0, race_data.0, race_data)
  let end_bound = find_win_end(0, race_data.0, race_data)

  end_bound - start_bound + 1
}

pub fn pt_2(input: String) {
  input
  |> parse_single_race_data
  |> get_length_of_wins
}
