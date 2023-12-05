import gleam/iterator
import gleam/int
import gleam/string
import gleam/list
import gleam/result

type SourceMap {
  SourceMap(source_start: Int, destination_start: Int, range: Int)
}

type SeedMap {
  SeedMap(seeds: List(Int), maps: List(List(SourceMap)))
}

fn source_to_destination(source: Int, maps: List(SourceMap)) -> Int {
  list.find(maps, fn(map) {
    map.source_start <= source && map.source_start + map.range > source
  })
  |> result.map(fn(map){
    map.destination_start + { source - map.source_start }
  })
  |> result.unwrap(source)
}

fn parse_maps(map_str: String) -> List(SourceMap) {
  let assert Ok(map) = {
    use rest <- result.map(string.split(map_str, "\n") |> list.rest)
    use map_str <- list.map(rest)
    map_str
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.values
    |> fn(values){
      let [destination_start, source_start, range] = values
      SourceMap(source_start, destination_start, range)
    }
  }

  map
}

fn parse_seeds(seed_str: String) -> List(Int) {
  let assert "seeds: " <> seed_count_str = seed_str

  string.split(seed_count_str, " ")
  |> list.map(int.parse)
  |> result.values
}


fn parse_input(input: String) -> SeedMap {
  let groups = string.split(input, "\n\n")

  let assert Ok(seed_str) = list.first(groups)
  let seeds = parse_seeds(seed_str)
  
  let assert Ok(maps) = list.rest(groups)
  let maps = list.map(maps, fn(map){parse_maps(map)})

  SeedMap(seeds, maps)
}

fn seed_to_location(seed: Int, maps: List(List(SourceMap))) -> Int {
  list.fold(maps, seed, source_to_destination)
}

fn find_location(map: SeedMap) -> Result(Int, Nil) {
  map.seeds
  |> list.map(fn(seed){seed_to_location(seed, map.maps)})
  |> list.reduce(int.min)
}

fn find_location_range(map: SeedMap) -> Result(Int, Nil) {
  let seed_ranges = list.sized_chunk(map.seeds, 2)

  seed_ranges
  |> list.sort(fn(a,b){
    let assert [a, _] = a
    let assert [b, _] = b
    int.compare(a,b)
  })
  |> list.fold([], fn(modified, range){
    case modified {
      [] -> [range]
      [last, ..rest] -> {
        let [last_start, last_length] = last
        let [curr_start, curr_length] = range
        case last_start, last_start + last_length, curr_start, curr_start + curr_length {
          _,  le, _,  ce if ce < le -> [last, ..rest]
          ls, le, cs, _  if cs < le -> [[ls, cs], [cs+1, le-cs], ..rest]
          _,  _,  _,  _             -> [range, ..modified]
        }
      }
    }
  })
  |> list.map(fn(range){find_location_iterator(range, map.maps)})
  |> result.values
  |> list.reduce(int.min)
}

fn find_location_iterator(range: List(Int), maps: List(List(SourceMap))) {
  let assert [start, length] = range

  iterator.range(start, start+length-1)
  |> iterator.map(fn(seed){seed_to_location(seed, maps)})
  |> iterator.reduce(int.min)
}

pub fn pt_1(input: String) {
  let assert Ok(location) = parse_input(input)
  |> find_location
  
  location
}

pub fn pt_2(input: String) {
  let assert Ok(location) = parse_input(input)
  |> find_location_range

  location
}
