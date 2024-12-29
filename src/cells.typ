#import "@preview/cetz:0.3.1" as cetz: draw
#import "@preview/oxifmt:0.2.1": strfmt
#import "@preview/valkyrie:0.2.1" as z
#import "/src/objects/coordinates.typ": *
#import "/src/utils.typ": to-angle, min-by, dist, vec-sum, vec-diff, normalise, dot

#let cell-size = (
  regular: 0.5,
  large: 0.65,
)

#let cell-colors = (
  "red": red,
  "blue": blue,
  "green": green,
  "yellow": yellow,
  "purple": purple,
  "none": gray.rgb(),
)

//     (0, 1)   (1, 1)
//   (-1, 0)       (1, 0)
//     (-1,-1)   (0,-1)
#let cell-dir = (
  UpLeft: (rel: (0, 1)),
  UpRight: (rel: (1, 1)),
  Left: (rel: (-1, 0)),
  Right: (rel: (1, 0)),
  DownLeft: (rel: (-1, -1)),
  DownRight: (rel: (0, -1)),
)

#let cell-schema = z.dictionary((
  coord: coordinate-schema,
  size: z.number(),
  rotation: z.either(z.number(), z.angle()),
  vertices: z.array(z.array(z.number(), assertions: (z.assert.length.equals(2),))),
  content: z.any(),
  color: z.color(),
  name: z.string(),
))

#let gen-cell-name(pt, size, rotation) = {
  let rot = to-angle(rotation)

  let suffix = array(cbor.encode((pt, size, rot)))
    .chunks(8)
    .map(chunk => str(int.from-bytes(bytes(chunk)), base: 36))
    .rev()
    .join()

  strfmt("cell-{}", suffix)
}

#let parse-size(size) = {
  if size == auto {
    cell-size.regular
  } else if type(size) == str {
    assert(size in cell-size.keys(), message: "The size of the cell must be a valid cell size.")
    cell-size.at(size)
  } else {
    assert(type(size) in (int, float, decimal), message: "The size of the cell must be a number.")
    size
  }
}

#let new-cell(
  pt,
  coord-system: coordinate-system.axial,
  color: auto,
  content: none,
  size: auto,
  rotation: 0deg,
) = {
  assert.eq(type(pt), array, message: "The center of the cell must be an array.")
  assert(pt.len() == 2, message: "The point must have two elements.")

  let pt = coord(pt, system: coord-system)

  let size = parse-size(size)
  let rot = to-angle(rotation)

  let verts = ()
  let angle = 360deg / 6 + to-angle(rotation)

  let (x, y) = (pt.xy)()
  while angle < 360deg + to-angle(rotation) {
    let vert = (size * calc.cos(angle), size * calc.sin(angle))
    verts.push(vert)

    angle = angle + 180deg / 3
  }

  let color = if color == auto {
    cell-colors.none
  } else if color == none {
    white.rgb()
  } else {
    color
  }

  z.parse(
    (
      coord: pt,
      size: size,
      rotation: rot,
      vertices: verts,
      content: content,
      color: color,
      name: gen-cell-name(pt, size, rotation),
    ),
    cell-schema,
  )
}

#let add-neighbour(
  cell,
  dir,
  dir-coord-system: "axial",
  color: auto,
  content: none,
  size: auto,
  spacing: 1,
  rotation: 0deg,
  debug: false,
) = {
  let scaled = (rel: dir.rel.map(it => it * spacing))
  let rel = rel-coord(cell, scaled, system: dir-coord-system)

  new-cell(
    (rel.rq)(),
    coord-system: coordinate-system.axial,
    color: color,
    content: content,
    size: size,
    rotation: rotation,
  )
}

#let parse-cell-color(color) = {
  let fill = if color == none {
    white.rgb()
  } else {
    color.rgb()
  }

  let stroke = color.rgb().darken(40%).desaturate(40%)

  let cell-fill = fill
  let cell-stroke = stroke

  if color == auto {
    fill = gray.rgb()
    stroke = black.rgb()
  } else if color == none {
    fill = white.rgb()
    stroke = black.rgb()
  }

  if fill != white {
    cell-fill = gradient.radial(
      fill,
      stroke,
      radius: 70%,
      focal-radius: 30%,
    )
  }

  if stroke != black {
    cell-stroke = gradient.radial(
      stroke,
      fill,
      radius: 55%,
      focal-radius: 15%,
    )
  }

  (cell-fill, cell-stroke)
}

#let draw-cell(
  /// The cell data. -> dictionary
  cell-obj,
  /// Whether to show vertex indices. -> bool
  debug: false,
) = {
  draw.group(
    name: "group-" + cell-obj.name,
    {
      let (cell-fill, cell-stroke) = parse-cell-color(cell-obj.color)

      draw.line(
        // Vertices are relative to the center of the cell
        ..cell-obj.vertices.map(v => vec-sum(v, (cell-obj.coord.xy)())),
        fill: cell-fill,
        stroke: cell-stroke,
        close: true,
        name: cell-obj.name,
      )

      draw.content((cell-obj.coord.xy)(), cell-obj.content)

      if debug {
        let midpoint = cell-obj
          .vertices
          .map(v => vec-sum(v, (cell-obj.coord.xy)()))
          .sorted(key: ((x, y)) => y)
          .slice(0, 2)
          .fold((0, 0), (acc, pt) => vec-sum(acc, pt))
          .map(it => it / 2)

        draw.content(
          midpoint,
          pad(top: 0.5mm, text(repr((cell-obj.coord.rq)()), size: 0.4em, fill: red)),
          anchor: "north",
        )
      }
    },
  )
}

#let get-nearest-neighbours(cell, other-cells) = {
  let (x, y) = (cell.coord.xy)()
  let selectors = (
    pt => pt != cell and pt.coord.euclidean.x < x and pt.coord.euclidean.y == y,
    pt => pt != cell and pt.coord.euclidean.x > x and pt.coord.euclidean.y == y,
    pt => pt != cell and pt.coord.euclidean.x < x and pt.coord.euclidean.y > y,
    pt => pt != cell and pt.coord.euclidean.x < x and pt.coord.euclidean.y < y,
    pt => pt != cell and pt.coord.euclidean.x > x and pt.coord.euclidean.y > y,
    pt => pt != cell and pt.coord.euclidean.x > x and pt.coord.euclidean.y < y,
  )

  let search-branches = selectors.map(selector => other-cells.filter(selector))

  search-branches
    .map(branch => min-by(
      branch,
      pt => dist((cell.coord.xy)(), (pt.coord.xy)()),
    ))
    .filter(pt => pt != none)
}

#let check-unique-coords(cells) = {
  let coords = cells.map(cell => (cell.coord.rq)())
  let deduped = coords.dedup()
  let has-dups = coords.len() != deduped.len()

  if has-dups {
    // let dup-idx = coords
    //   .enumerate()
    //   .zip(deduped)
    //   .map((((idx, coord), deduped)) => (idx, coord, deduped))
    //   .filter(((idx, coord, deduped)) => coord != deduped)
    //   .at(0, default: coords.len() - 1)

    let idx = 0
    while true {
      let popped = coords.remove(0)

      if popped in coords {
        break
      }

      idx += 1
    }

    assert.ne(idx, none, message: "Duplicate coordinates found. But idx is none.")
    panic(strfmt("Duplicate coordinates found at index {}.", idx))
  }
}
#let cell-grid(cell-objs, spaceing: 1, debug: false) = {
  check-unique-coords(cell-objs)

  let connections = ()
  let visited = ()

  // Scale by spacing
  let cell-objs = cell-objs.map(cell => {
    cell.insert("coord", (cell.coord.scale)(spaceing))
    cell
  })

  for (idx, current-cell) in cell-objs.enumerate() {
    // let neighbours = get-nearest-neighbours(current-cell, cell-objs)

    let neighbours = cell-objs.filter(pt => (
      pt != current-cell
        and dist(
          (current-cell.coord.xy)(),
          (pt.coord.xy)(),
        )
          <= calc.sqrt(2) * spaceing
    ))

    for neighbour in neighbours {
      if (neighbour, current-cell) in visited {
        continue
      }

      let connection = (
        from: current-cell,
        to: neighbour,
      )

      // Only need to add (current-cell, neighbour) since the current
      // loop is the ONLY way to get (neighbour, current-cell) in the
      // visited list.
      visited.push((current-cell, neighbour))

      connections.push(connection)
    }
  }

  draw.on-layer(
    -1,
    {
      let line-num = 1
      for connection in connections {
        let (cell-from, cell-to) = (connection.from, connection.to)

        // if (
        //   cell-from.coord.axial.r > cell-to.coord.axial.r or cell-from.coord.axial.q < cell-to.coord.axial.q
        // ) {
        //   (cell-from, cell-to) = (cell-to, cell-from)
        // }

        let color-from = if cell-from.color == auto {
          black
        } else {
          cell-from.color
        }

        let color-to = if cell-to.color == auto {
          black
        } else {
          cell-to.color
        }

        // Gradient may appear backwards if the line is drawn at an angle that
        // effectively reverses the line direction. Intuitively, the gradient
        // can be considered as "applied" before drawing the line from A to B.
        // Thus, if we drawn from B to A, the gradient will appear as if
        // the line was spun around.
        let dir = if cell-from.coord.euclidean.y == cell-to.coord.euclidean.y {
          if cell-from.coord.euclidean.x < cell-to.coord.euclidean.x {
            ltr
          } else {
            rtl
          }
        } else {
          if cell-from.coord.euclidean.y < cell-to.coord.euclidean.y {
            btt
          } else {
            ttb
          }
        }

        let line-stroke = gradient.linear(
          color-from,
          color-to,
          dir: dir,
        )

        // Draw the line between the two cells starting from the edge of the cell
        // and ending at the edge of the other cell. This ensures that the gradient
        // is applied correctly, since otherwise the midpoint of the line may not
        // be directly between the two cell edges.
        let from = (cell-from.coord.xy)()
        let to = (cell-to.coord.xy)()
        draw.line(
          vec-sum(from, normalise(vec-diff(to, from), to: cell-from.size)),
          vec-sum(to, normalise(vec-diff(from, to), to: cell-to.size)),
          stroke: line-stroke,
        )

        if debug {
          draw.on-layer(
            1,
            {
              draw.content(
                (cell-from.coord.xy)(),
                pad(
                  top: 2mm,
                  block(
                    text(
                      str(cell-from.color.to-hex()),
                      size: 0.4em,
                      fill: cell-from.color,
                    ),
                    fill: black,
                    inset: 0.3mm,
                    radius: 0.4mm,
                  ),
                ),
                anchor: "north",
              )

              // t = (d - r - R) / 2
              // where:
              // d = distance between the centers of the two cells
              // r = radius of the first cell
              // R = radius of the second cell
              // t = true middle on the line BETWEEN the two cells,
              //    not the middle of the line connecting the two cells
              //    from their centers
              let v = vec-sum(
                (cell-to.coord.xy)(),
                (cell-from.coord.xy)().map(it => -it),
              )

              let d = calc.sqrt(v.map(x => calc.pow(x, 2)).sum())
              let t = (d - cell-from.size - cell-to.size) / 2

              let vec = normalise(v, to: cell-from.size + t)

              let (vx, vy) = vec
              let vec_perp = normalise((-vy, vx), to: 0.08)

              draw.content(
                vec-sum((cell-from.coord.xy)(), vec, vec_perp),
                block(
                  text(str(line-num), size: 0.3em, fill: white),
                  fill: black,
                  inset: 0.3mm,
                  radius: 0.4mm,
                ),
              )

              line-num += 1
            },
          )
        }
      }
    },
  )

  draw.on-layer(
    0,
    {
      for (idx, cell) in cell-objs.enumerate() {
        draw-cell(cell, debug: debug)

        if debug {
          let corners = cell
            .vertices
            .map(v => vec-sum(v, (cell.coord.xy)()))
            .sorted(key: ((x, y)) => x)
            .sorted(key: ((x, y)) => -y)

          let m = vec-sum(corners.at(0), corners.at(2)).map(it => it / 2)

          draw.content(
            m,
            block(
              text(str(idx), size: 0.5em, fill: white),
              fill: black,
              inset: 0.3mm,
              radius: 0.4mm,
            ),
          )
        }
      }
    },
  )
}

#let draw-rel-cells(root, dirs, color, init-power) = {
  assert(init-power - dirs.len() >= 0, message: "The initial power must be greater than the number of directions.")
  let cells = (new-cell(root, color: blue, content: [#{ init-power - dirs.len() }]),)

  while dirs.len() > 0 {
    let dir = dirs.pop()
    cells.push(add-neighbour(cells.last(), dir, color: color, content: [1]))
  }

  cell-grid(cells)
}
