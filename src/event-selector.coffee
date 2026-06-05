import { pipe, curry, memoize } from "@dashkite/joy/function"
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
bang = Parse.text "!"
lbracket = Parse.text "["
rbracket = Parse.text "]"
equals = Parse.text "="
bar = Parse.text "|"
ampersand = Parse.text "&"

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
    Parse.optional Parse.pipe [ bang, Parse.map -> negate: true ]
    name
    Parse.optional Parse.pipe [
      Parse.all [
        Parse.skip equals
        quoted
      ]
      Parse.map ([ value ]) -> { value }
    ]
  ]
  Parse.merge
  Parse.map ( specifier ) ->
    property: { negate: false, specifier... }
]

propertySelector = Parse.between [ lbracket, rbracket ], propertyExpression

selector = Parse.pipe [
  Parse.all [
    nameSelector
    Parse.optional propertySelector
  ]
  Parse.merge
  Parse.map ( specifier ) ->
    { name: "*", scope: "*", specifier... }
]

$not = Parse.pipe [
  ws bang
  Parse.map -> negate: true
]

$or = Parse.pipe [
  ws bar
  Parse.map -> operator: "or"
]

$and = Parse.pipe [
  ws ampersand
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
  Parse.map ( specifier ) ->
    { negate: false, specifier... }
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

parse = memoize Parse.parser Parse.list comma, expression

# Predicate Helpers
not_ = ( pred ) -> ( event ) -> ! pred event
and_ = ( f, g ) -> ( event ) -> ( f event ) && ( g event )
or_ = ( f, g ) -> ( event ) -> ( f event ) || ( g event )

isMatch = ( scope, name ) ->
  scope ?= "*"
  name ?= "*"
  ( event ) ->
    (( scope == "*" ) || ( scope == event?.scope )) &&
    (( name == "*") || ( name == event?.name ))

hasProperty = ( property, value ) ->
  ( event ) ->
    exists = event[property]?
    if value?
      exists && event[property]?.toString() == value
    else
      exists

Evaluators =

  property: ({ name, value, negate }) ->
    predicate = hasProperty name, value
    if negate then not_ predicate else predicate

  selector: ({ name, scope, property, negate }) ->
    predicate = isMatch scope, name
    if property?
      predicate = and_ predicate, Evaluators.property property
    if negate then not_ predicate else predicate

  expression: ( expression ) ->
    Evaluators.selector expression
  
  list: evaluate = ( selectors ) ->
    ( event ) ->
      selectors.some ( selector ) ->
        Evaluators.selector selector
          .call null, event

match = curry ( pattern, event ) ->
  (( evaluate parse pattern ) event )

export default match
