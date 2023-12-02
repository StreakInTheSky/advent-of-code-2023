import gleam/string
import gleam/list
import gleam/int
import gleam/dict
import gleam/option.{Some}

type Id = Int

type Group = #(String, Int)

type Round = List(Group)

type Game = #(Id, List(Round))

fn parse_game(input: String) -> List(Game) {
  input
  |> string.split("\n")
  |> list.map(fn(line){
    let assert [game_id, rounds] = string.split(line, ": ")
    let assert "Game " <> id = game_id
    let assert Ok(id) = int.parse(id) 

    let rounds = rounds
    |> string.split("; ")
    |> list.map(fn(round){
      round
      |> string.split(", ")
      |> list.map(fn(group){
        let assert [count, color] = string.split(group, " ")
        let assert Ok(count) = int.parse(count)
        #(color, count)
      })
    })
    #(id, rounds)
  }) 
}

pub fn pt_1(input: String) {
  let games = parse_game(input)
  
  games
  |> list.filter(fn(game){
    list.all(game.1, fn(round){
      list.all(round, fn(group){
        case group {
          #("red", count) if count <= 12 -> True
          #("green", count) if count <= 13 -> True
          #("blue", count) if count <= 14 -> True
          _ -> False
        }
      })
    })
  })
  |> list.fold(0, fn(acc, game) {acc + game.0})
}

pub fn pt_2(input: String) {
  let games = parse_game(input)
  
  games
  |> list.map(fn(game){
    let min_set = list.fold(game.1, dict.from_list([#("red", 0),#("green", 0),#("blue", 0)]), fn(mins, round) {
      list.fold(round, mins, fn(mins, group: Group){
          dict.update(mins, group.0, fn(value) {
            let assert Some(curr) = value
            int.max(curr, group.1)
          })
      })
    })
    
    let assert Ok(red) = dict.get(min_set, "red")
    let assert Ok(green) = dict.get(min_set, "green")
    let assert Ok(blue) = dict.get(min_set, "blue")

    red * green * blue
  })
  |> int.sum
}
