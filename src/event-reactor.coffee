import match from "./event-selector"

iterable = ( value ) ->
  ( value?[Symbol.asyncIterator]? ) || 
    ( value?[Symbol.iterator]? )

class EventReactor

  @make: ( reactor ) ->
    Object.assign ( new @ ), { reactor, handlers: []}

  bind: ( @self ) -> @

  when: ( selector, handler ) ->
    @handlers.push { selector, handler }
    @

  forward: ( selector ) -> 
    @when selector, ( event ) -> yield event

  run: ( selectors = {}) ->
    selectors.resolve ?= "success"
    selectors.reject ?= "failure"
    for await event from @
      if ( match selectors.resolve, event )
        return event
      else if ( match selectors.reject, event )
        throw event.error ? 
          ( new Error "failure event #{ selectors.reject } matched" )
      else
        continue
    return  

  [ Symbol.asyncIterator ]: ->
    for await event from @reactor
      for { selector, handler } in @handlers when match selector, event
        result = handler.call @self, event
        yield from result if ( iterable result )        
    return

export default EventReactor
