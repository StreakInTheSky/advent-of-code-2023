import gleam/string
import gleam/list
import gleam/int
import gleam/dict
import gleam/option.{Some}

type Round {
  Round(red: Int, green: Int, blue: Int)
} 

type Game {
  Game(id: Int, rounds: List(Round))
}

fn parse_games(input: String) -> List(Game) {
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
      |> list.fold(Round(0,0,0), fn(round, group){
        let assert [count, color] = string.split(group, " ")
        let assert Ok(count) = int.parse(count)
        case color {
          "red" -> Round(..round, red: count)
          "green" -> Round(..round, green: count)
          "blue" -> Round(..round, blue: count)
        }
      })
    })
    Game(id, rounds)
  }) 
}

pub fn pt_1(input: String) {
  let games = parse_games(input)
  
  {
    use game <- list.filter(games)
    use round <- list.all(game.rounds)
    round.red <= 12 && round.green <= 13 && round.blue <= 14
  }
  |> list.fold(0, fn(acc, game) {acc + game.id})
}

pub fn pt_2(input: String) {
  let games = parse_games(input)
  
  {
    use game <- list.map(games)
    let Round(red, green, blue) = list.fold(game.rounds, Round(0,0,0), fn(mins, round) {
      Round(
        red: int.max(mins.red, round.red),
        green: int.max(mins.green, round.green),
        blue: int.max(mins.blue, round.blue)
      )
    })
    
    red * green * blue
  }
  |> int.sum
}
