#import "@preview/valkyrie:0.2.1" as z

#let coordinate-system = (
  axial: "axial",
  euclidean: "euclidean",
)

/// Transforms an axial coordinate to an euclidean coordinate.
/// #test(
/// `coordinates.to-euclidean(0, 0) == (0, 0)`,
/// `coordinates.to-euclidean(1, 0) == (1, 0)`,
/// `coordinates.to-euclidean(0, 1) == (-0.5, calc.sqrt(3) / 2)`,
/// ) -> tuple
#let to-euclidean(r, q) = {
  let x = r - q / 2
  let y = q * calc.sqrt(3) / 2
  (x, y)
}

#let to-axial(x, y) = {
  let r = x + y * calc.sqrt(3) / 3
  let q = 2 * calc.sqrt(3) * y / 3
  (r, q)
}

#let axial-coord-schema = z.dictionary(
  (
    r: z.number(),
    q: z.number(),
  ),
  pre-transform: (self, input) => if type(input) == array {
    z.coerce.dictionary(it => (r: it.at(0), q: it.at(1)))
  } else { input },
)

#let euclidean-coord-schema = z.dictionary(
  (
    x: z.number(),
    y: z.number(),
  ),
  pre-transform: (self, input) => if type(input) == array {
    z.coerce.dictionary(it => (x: it.at(0), y: it.at(1)))
  } else { input },
)

#let coordinate-system-schema = z.string(assertions: (z.assert.one-of(coordinate-system.values()),))

#let coordinate-schema = z.dictionary((
  euclidean: euclidean-coord-schema,
  axial: axial-coord-schema,
))

#let add-coord-funcs(coord) = {
  let add(pt) = {
    let p = z.parse(
      (
        euclidean: (
          x: coord.euclidean.x + pt.euclidean.x,
          y: coord.euclidean.y + pt.euclidean.y,
        ),
        axial: (
          r: coord.axial.r + pt.axial.r,
          q: coord.axial.q + pt.axial.q,
        ),
      ),
      coordinate-schema,
    )

    add-coord-funcs(p)
  }

  let sub(pt) = {
    let p = z.parse(
      (
        euclidean: (
          x: coord.euclidean.x - pt.euclidean.x,
          y: coord.euclidean.y - pt.euclidean.y,
        ),
        axial: (
          r: coord.axial.r - pt.axial.r,
          q: coord.axial.q - pt.axial.q,
        ),
      ),
      coordinate-schema,
    )

    add-coord-funcs(p)
  }

  let scale(k) = {
    let p = z.parse(
      (
        euclidean: (
          x: coord.euclidean.x * k,
          y: coord.euclidean.y * k,
        ),
        axial: (
          r: coord.axial.r * k,
          q: coord.axial.q * k,
        ),
      ),
      coordinate-schema,
    )

    add-coord-funcs(p)
  }

  let mul-add(k, pt) = {
    let p = (scale(k).add)(pt)
    add-coord-funcs(p)
  }

  let xy() = (coord.euclidean.x, coord.euclidean.y)
  let rq() = (coord.axial.r, coord.axial.q)

  coord.insert("add", add)
  coord.insert("sub", sub)
  coord.insert("scale", scale)
  coord.insert("mul-add", mul-add)
  coord.insert("xy", xy)
  coord.insert("rq", rq)
  coord
}

#let coord(pt, system: "axial") = {
  pt = z.parse(pt, z.array(z.number(), assertions: (z.assert.length.equals(2),)))

  let system = z.parse(system, coordinate-system-schema)

  let euclidean = if system == coordinate-system.euclidean {
    pt
  } else {
    to-euclidean(..pt)
  }

  let axial = if system == coordinate-system.axial {
    pt
  } else {
    to-axial(..pt)
  }


  let euclidean = z.parse((x: euclidean.at(0), y: euclidean.at(1)), euclidean-coord-schema)
  let axial = z.parse((r: axial.at(0), q: axial.at(1)), axial-coord-schema)

  let coordinate = z.parse((euclidean: euclidean, axial: axial), coordinate-schema)

  add-coord-funcs(coordinate)
}

#let rel-coord(pt, dir, system: coordinate-system.axial) = {
  let system = z.parse(system, coordinate-system-schema)
  assert(
    type(dir) == dictionary and "rel" in dir,
    message: "The direction must be a relative coordinate.",
  )

  let rel = coord(dir.rel, system: system)

  let coordinate = (pt.coord.add)(rel)

  add-coord-funcs(coordinate)
}
