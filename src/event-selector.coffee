import * as Fn from "@dashkite/joy/function"
import * as Parse from "@dashkite/parse"

ws = ( rule ) -> Parse.pipe [
  Parse.all [
    Parse.skip Parse.optional Parse.ws
    rule
  ]
  Parse.first
]

comma = ws Parse.text ","
period = Parse.skip Parse.text "."
asterisk = Parse.text "*"
lbracket = Parse.text "["
rbracket = Parse.text "]"
equals = Parse.text "="

symbol = ws Parse.re /^[a-zA-Z][\w\-]*/

quoted = Parse.pipe [
  Parse.re /^'[^']*'|"[^"]*"/
  Parse.map ( text ) -> text[1...-1]
]

name = Parse.pipe [
  symbol
  Parse.tag "name"
]

scope = Parse.pipe [
  symbol
  Parse.tag "scope"
]

property = Parse.pipe [
  symbol
  Parse.tag "property"
]

wildcard = ( tag ) ->
  Parse.pipe [
    asterisk
    Parse.tag tag
  ]

scopedName = Parse.pipe [
    Parse.all [
      scope
      period
      name
    ]
    Parse.merge
  ]

wildcardName = Parse.pipe [
  Parse.all [
    wildcard "scope"
    period
    name
  ]
  Parse.merge
]

scopeWildcard = Parse.pipe [
  Parse.all [
    scope
    period
    wildcard "name"
  ]
  Parse.merge
]

nameSelector = Parse.any [
  scopedName
  wildcardName
  scopeWildcard
  name
  wildcard "name"
]

propertyExpression = Parse.pipe [
  Parse.all [
    property
    Parse.optional Parse.all [
      Parse.skip equals
      quoted
    ]

  ]
  Parse.map ([{ property }, relation ]) ->
    if relation?
      { property, value: relation[0] }
    else
      { property }
]

propertySelector = Parse.between [ lbracket, rbracket ], propertyExpression

selector = Parse.pipe [
  Parse.all [
    nameSelector
    Parse.optional propertySelector
  ]
  Parse.merge
  Parse.map ({ rest..., name, scope }) ->
    name ?= "*"
    scope ?= "*"
    { rest..., name, scope }
]

$not = Parse.pipe [
  ws Parse.text "!"
  Parse.map -> negate: true
]

$or = Parse.pipe [
  ws Parse.text "|"
  Parse.map -> operator: "or"
]

$and = Parse.pipe [
  ws Parse.text "&"
  Parse.map -> operator: "and"
]

unaryOperator = $not

binaryOperator = Parse.pipe [
  ws Parse.any [
    $and
    $or
  ]
]

unaryExpression = Parse.pipe [
  Parse.all [
    Parse.optional unaryOperator
    selector
  ]
  Parse.merge
  Parse.map ({ rest..., negate }) ->
    negate ?= false
    { rest..., negate }
]

binaryExpression = Parse.pipe [
  Parse.all [
    unaryExpression
    binaryOperator
    unaryExpression
  ]
  Parse.map ([ first, { operator }, second ]) ->
    { operator, first, second }
]

expression = Parse.any [
  binaryExpression
  unaryExpression
]

parse = Fn.memoize Parse.parser Parse.list comma, expression

evaluate = ( tree ) ->
  if Array.isArray tree
    ( event ) ->
      tree.some ( expression ) ->
        (( evaluate expression ) event )
  else
    if tree.operator
      f = evaluate tree.first
      g = evaluate tree.second
      switch tree.operator
        when "or"
          ( event ) -> ( f event ) || ( g event )
        when "and"
          ( event ) -> ( f event ) && ( g event )
    else
      { scope, name, property, value, negate } = tree
      do ( scope, name, property, value, negate ) ->
        ( event ) ->
          result = (( scope == "*" ) || ( scope == event.scope )) &&
            (( name == "*") || ( name == event.name )) &&
            (( !property? ) || event[ property ]? ) &&
            (( !value? ) || ( event[ property ]?.toString() == value ))
          if negate then !result else result

match = Fn.curry ( pattern, event ) ->
  (( evaluate parse pattern ) event )

export default match
