type Coordinate = {
  x: number;
  y: number;
}

function Coordinate(row: number, col: number) {
  this.row = row;
  this.col = col;
}

function parseMatrix(file: String) : string[][] {
  return file.split("\n")
    .map((line)=>line.split(""));
}


function getSymbolCoordinates(re: RegExp) : (matrix: string[][]) => Coordinate[] {
  return (matrix) => {
    const coordinates = [];
    for (let i = 0; i < matrix.length; i++) { 
      for (let j = 0; j < matrix[i].length; j++) {
        if (matrix[i][j] != "." && re.test(matrix[i][j])) {
          coordinates.push(new Coordinate(i,j));
        }
      }
    }
    
    return coordinates;
  }
}

function findAdjacentNumbers(matrix: string[][]) : (a: Coordinate[]) => number[] {
  const directions = [[1,0],[0,1],[-1,0],[0,-1],[1,1],[-1,-1],[1,-1],[-1,1]];
  return (coordinates)=>{
    return coordinates.map(({row, col})=>{
      const numbers = [];
      directions.forEach(([h,v])=>findNumber(numbers, matrix, new Coordinate(row+h, col+v)));
      return numbers;
    })
    .filter((numbers)=>numbers.length);
  }
}

function findNumber(numbers: number[], matrix: string[][], coord: Coordinate) : void {
  let col = coord.col;
  const colCount = matrix[0].length;
  const checkValidCol = (col) => col < colCount && col > -1;
  
  const row = coord.row;
  const rowCount = matrix.length;
  const validRow = row < rowCount && row > -1;
  
  const re = /\d/
  let numArr = [];
  
  while (validRow && checkValidCol(col) && re.test(matrix[row][col])) {
    numArr.push(matrix[row][col]);
    matrix[row][col] = ".";
    col--;
  }
  
  if (!numArr.length) return;
  
  numArr = numArr.reverse();
  col = coord.col + 1;
  while (validRow && checkValidCol(col) && re.test(matrix[row][col])) {
    numArr.push(matrix[row][col]);
    matrix[row][col] = ".";
    col++;
  }

  if (numArr.length) {
    numbers.push(Number(numArr.join("")));
  }
}

function findPartsNumbers(matrix: string[][]) : number[] {
  return Promise.resolve(matrix)
  .then(getSymbolCoordinates(/[\W\D]/))
  .then(findAdjacentNumbers(matrix))
  .then((adjacentNumbers)=>adjacentNumbers.flat());
}

function getGears(numberLists: number[][]) {
  return numberLists
    .filter((numList)=>numList.length === 2)
    .map(([a,b])=>a*b)
}

function findGearRatios(matrix: string[][]): number[] {
  return Promise.resolve(matrix)
    .then(getSymbolCoordinates(/\*/))
    .then(findAdjacentNumbers(matrix))
    .then(getGears)
}


const file = Deno.readTextFile("../../input/2023/3.txt");

// Part 1
file
.then(parseMatrix)
.then(findPartsNumbers)
.then(nums=>nums.reduce((acc,n)=>acc+n))
.then(console.log);

// Part 2
file
.then(parseMatrix)
.then(findGearRatios)
.then(nums=>nums.reduce((acc,n)=>acc+n))
.then(console.log);
