#import "@preview/tidy:0.4.0"
#import "/src/utils.typ"
#import "src/objects/coordinates.typ"

#let doc(path, name, scope) = {
  let docs = read(path)
  let module = tidy.parse-module(
    docs,
    name: name,
    scope: scope,
  )

  tidy.show-module(module)
}

#doc("/src/utils.typ", "utils", (utils: utils))
#doc("/src/objects/coordinates.typ", "coordinates", (utils: utils, coordinates: coordinates))

