#import "@preview/oxifmt:0.2.1": strfmt

/// A helper function to convert types into an angle.
/// #test(
/// `utils.to-angle(25deg) == 25deg`,
/// `utils.to-angle(2rad) == 2rad`,
/// `utils.to-angle(50%) == 180deg`,
/// `utils.to-angle(0) == 0deg`,
/// `utils.to-angle(360) == 0deg`,
/// `utils.to-angle(-90) == 270deg`,
/// )
/// -> angle
#let to-angle(
  /// The rotation of the hexagon. -> angle | ratio | int | float | decimal
  value,
) = {
  assert(
    type(value) in (angle, ratio, int, float, decimal),
    message: "The given value must be an angle, ratio, or number.",
  )

  let new-angle = if type(value) == angle {
    value
  } else if type(value) == ratio {
    value * 360deg
  } else if type(value) in (int, float, decimal) {
    1deg * value
  }

  while new-angle < 0deg {
    new-angle = new-angle + 360deg
  }

  while new-angle >= 360deg {
    new-angle = new-angle - 360deg
  }

  assert.eq(type(new-angle), angle, message: "The result was expected to be an angle. Got: " + repr(new-angle) + ".")

  new-angle
}

/// A filter function that returns the minimum value based on a given function.
/// #test(
/// `utils.min-by((("b", 2), ("a", 1), ("c", 3)), x => x.at(1)) == ("a", 1)`,
/// `utils.min-by((("b", 2), ("a", 1), ("c", 3)), x => -x.at(1)) == ("c", 3)`,
/// `utils.min-by((("b", -2), ("a", 1), ("c", 3)), x => x.at(1)) == ("b", -2)`,
/// )
/// -> any
#let min-by(
  /// The values to filter. -> array
  values,
  /// The function to filter by. -> function
  func,
  default: none,
) = {
  values.sorted(key: func).at(0, default: default)
}

/// A helper function to calculate the distance between two points.
/// -> int | float | decimal
#let dist(
  /// The first point. -> array
  pt1,
  /// The second point. -> array
  pt2,
  kind: "euclidean",
) = {
  let (x1, y1) = pt1
  let (x2, y2) = pt2

  assert(
    kind in ("euclidean", "manhattan"),
    message: strfmt("The distance kind must be either 'euclidean' or 'manhattan'. Got: {}.", kind),
  )

  if kind == "manhattan" {
    calc.abs(x2 - x1) + calc.abs(y2 - y1)
  } else {
    calc.sqrt(calc.pow(x2 - x1, 2) + calc.pow(y2 - y1, 2))
  }
}

/// A helper function to calculate the sum of vectors.
/// #test(
/// `utils.vec-sum((1, 2), (3, 4)) == (4, 6)`,
/// `utils.vec-sum((1, 2), (3, 4), (5, 6)) == (9, 12)`,
/// `utils.vec-sum((1, 2, 3), (4, 5, 6), (7, 8, 9)) == (12, 15, 18)`,
/// )
/// -> array
#let vec-sum(
  /// The vector to sum. -> array
  ..vecs,
) = {
  let deg = vecs.pos().first().len()
  assert(vecs.pos().all(vec => vec.len() == deg), message: "All vectors must have the same length.")

  let res = (0,) * deg
  for vec in vecs.pos() {
    res = res.zip(vec).map(array.sum)
  }

  res
}

/// A helper function to calculate the difference of vectors.
/// #test(
/// `utils.vec-diff((1, 2), (3, 4)) == (-2, -2)`,
/// `utils.vec-diff((1, 2), (3, 4), (5, 6)) == (-7, -8)`,
/// `utils.vec-diff((1, 2, 3), (4, 5, 6), (7, 8, 9)) == (-10, -11, -12)`,
/// )
/// -> array
#let vec-diff(
  /// The vector to subtract from. -> array
  vec1,
  /// The vector to subtract. -> array
  ..vecs,
) = {
  let deg = vecs.pos().first().len()
  assert(vecs.pos().all(vec => vec.len() == deg), message: "All vectors must have the same length.")

  let res = vec1
  for vec in vecs.pos() {
    res = res.zip(vec.map(x => x * -1)).map(array.sum)
  }

  res
}

/// A helper function to normalise a vector.
/// #test(
/// `utils.normalise((2, 2)) == (1 / calc.sqrt(2), 1 / calc.sqrt(2))`,
/// `utils.normalise((2, 2), to: 2) == (2 / calc.sqrt(2), 2 / calc.sqrt(2))`,
/// `utils.normalise((1, 2, 3)) == (1 / calc.sqrt(14), 2 / calc.sqrt(14), 3 / calc.sqrt(14))`,
/// )
/// -> array
#let normalise(
  /// The vector to normalise. -> array
  vec,
  /// The length of the vector. -> int | float | decimal
  to: 1,
) = {
  let len = calc.sqrt(vec.map(x => calc.pow(x, 2)).sum())
  vec.map(x => x / len * to)
}

/// A helper function to calculate the dot product of two vectors.
/// #test(
/// `utils.dot((1, 2), (3, 4)) == 11`,
/// `utils.dot((1, 2, 3), (4, 5, 6)) == 32`,
/// )
/// -> int | float | decimal
#let dot(
  /// The first vector. -> array
  vec1,
  /// The second vector. -> array
  vec2,
) = {
  vec1.zip(vec2).map(array.product).sum()
}
