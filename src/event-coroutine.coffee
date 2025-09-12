import Generic from "@dashkite/generic"
import { Queue, reduce } from "@dashkite/joy/iterable"
import Coroutine from "./coroutine"
import match from "./event-selector"

class EventCoroutine

  @make: do ->

    ( Generic.make "EventCoroutine.make" )
    
      .define [ Object ], ( reactor ) ->
        Object.assign ( new @ ), {
          co: ( Coroutine.make reactor )
          handlers: []
        }

      .define [ Function ], ( f ) ->
        @make f()

  bind: ( @self ) -> @

  when: ( selector, handler ) ->
    @handlers.push { selector, handler }
    @

  start: -> run @

last = reduce (( ax, x ) -> x), undefined

isEvent = ( value ) -> value?.name?

run = ( self, value ) ->
  if self.co.done == true
    value
  else
    event = self.co.resume value
    if ( result = handle self, event )?.then?
      result.then ( value ) -> run self, value
    else if result?[ Symbol.iterator ]?
      last do -> 
        yield run self, yield from result
    else if result?[ Symbol.asyncIterator ]?
      last do ->
        yield run self, yield from result
        await return
    else run self, result

handle = do ->

  ( Generic.make "handle" )

    .define [ EventCoroutine, ( -> true )], ( self, value ) -> value

    .define [ EventCoroutine, isEvent ], ( self, event ) ->
      result = self
        .handlers
        .find ({ selector }) -> 
          match selector, event
      if result?
        result.handler.call self.self, event
    
    .define [ EventCoroutine, Promise ], ( self, promised ) ->
      event = await promised
      handle self, event

export default EventCoroutine