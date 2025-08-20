import * as Type from "@dashkite/joy/type"
import match from "./event-selector"

isGeneratorFunction = ( f ) ->
  ( Type.isGeneratorFunction f ) ||
    ( Type.isReactorFunction f )

class EventReactor

  @make: ( reactor ) ->
    Object.assign ( new @ ), { reactor, handlers: []}

  @run: ( reactor ) -> ( @make reactor ).run()

  bind: ( @self ) -> @

  when: ( selector, handler ) ->
    @handlers.push { selector, handler }
    @

  catch: ( @_catch ) ->

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

  start: ->
    for await event from @reactor
      for { selector, handler } in @handlers when match selector, event
        try
          if isGeneratorFunction handler
            result = handler.call @self, event
            await yield from result
          else
            await handler.call @self, event
        catch error 
          if @_catch?
            @_catch error
          else
            throw error
    return

  [ Symbol.asyncIterator ]: -> @start()


export default EventReactor
