import * as Fn from "@dashkite/joy/function"

match = Fn.curry ( pattern, event ) ->
  pattern
    .split /,\s*/
    .some ( pattern ) ->
      [ scope, name ] = pattern.trim().split "."
      # if there's no . we just match on the name
      # ex: 'foo' is the same as '*.foo'
      if !name?
        name = scope
        scope = "*"
      if ( m = name.match /^([^\[]+)\[([^\]]+)\]$/)
        [ , name, property ] = m
      else
        property = "*"
      (( scope == "*" ) || ( scope == event.scope )) &&
        (( name == "*") || ( name == event.name )) &&
        (( property == "*" ) || event[ property ]? )

export default match