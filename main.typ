#import "@preview/cetz:0.3.1"
#import "@preview/suiji:0.3.0": gen-rng, choice
#import "lib.typ": *

#set page(width: auto, height: auto, fill: white)

#let rng = gen-rng(49)

#cetz.canvas({
  import cetz.draw as draw: *

  let last = none
  let row-first = none
  let cells = ()

  let n = 0
  for y in range(5) {
    let (rng_, color) = choice(rng, (red, blue))
    rng = rng_

    row-first = if row-first == none {
      new-cell((0, 0), content: [#n], color: color)
    } else {
      add-neighbour(
        row-first,
        cell-dir.Left,
        content: [#n],
        color: color,
      )
    }

    last = row-first
    cells.push(row-first)
    n += 1
    for x in range(5) {
      let digits = str(x + y).split().map(int)
      let size = if calc.rem(digits.sum(), 3) == 0 {
        cell-size.large
      } else {
        cell-size.regular
      }

      let (rng_, color) = choice(rng, (red, blue))
      rng = rng_

      let rel = rel-coord(last, cell-dir.UpRight)
      let cell = add-neighbour(
        last,
        (rel: (0, 1)),
        color: color,
        size: size,
        content: [#n],
      )
      n += 1
      last = cell


      if x in (2, 3, 1) and y in (2, 1, 3) {
        continue
      }

      cells.push(cell)
    }
  }

  cell-grid(cells, spaceing: 1.5, debug: false)
})

#cetz.canvas({
  import cetz.draw as draw: *

  let cells = ()

  let root = new-cell((0, 0), content: [5], color: red, size: cell-size.large)
  cells.push(root)

  let dirs = (
    (cell-dir.UpLeft, red, 1),
    (cell-dir.Right, blue, 4),
    (cell-dir.DownRight, red, 1),
    (cell-dir.DownLeft, blue, 2),
    (cell-dir.Left, blue, 3),
    (cell-dir.UpLeft, blue, 2),
    (cell-dir.UpLeft, auto, 1),
    (cell-dir.UpRight, auto, 1),
    (cell-dir.Right, auto, 1),
    (cell-dir.Right, auto, 1),
    (cell-dir.DownRight, auto, 1),
    (cell-dir.DownRight, auto, 1),
    (cell-dir.DownLeft, auto, 1),
    (cell-dir.DownLeft, auto, 1),
    (cell-dir.Left, auto, 1),
    (cell-dir.Left, auto, 1),
    (cell-dir.UpLeft, auto, 1),
    (cell-dir.UpLeft, auto, 1),
  )

  let last = root
  for (idx, (dir, color, power)) in dirs.enumerate() {
    let size = if color == auto and calc.rem(idx, 2) == 0 {
      cell-size.large
    } else {
      cell-size.regular
    }
    last = add-neighbour(last, dir, size: size, color: color, content: [#power])
    cells.push(last)
  }

  cell-grid(cells, spaceing: 1.5, debug: true)
})

This is a ```c "banana"``` for scale #emoji.banana
#place(dx: 120pt, dy: -340pt, text("Pain", size: 20pt))

// #cetz.canvas({
//   import cetz.draw as draw: *

//   let cell = new-cell((0, 0), content: [1], color: red, size: cell-size.large)

//   let next = new-cell((1, 2), content: [2], color: blue, size: cell-size.regular)

//   draw.line(
//     // Vertices are relative to the center of the cell
//     ..cell.vertices.map(v => vec-sum(v, (cell.coord.xy)())),
//     close: true,
//     stroke: black,
//     fill: white,
//     name: cell.name,
//   )

//   draw.line(
//     // Vertices are relative to the center of the cell
//     ..next.vertices.map(v => vec-sum(v, (next.coord.xy)())),
//     close: true,
//     stroke: black,
//     fill: white,
//     name: next.name,
//   )

//   draw.line(cell.name, next.name, stroke: black)
// })
