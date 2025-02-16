# TODO possibly allow from to take a list of valid states
#      so that we can flag handlers for invalid states
#      success/failure could be a given?

# TODO make run a generic so that it can take a gen fn

run = ( handlers, event ) ->
  if handlers?
    for handler in handlers
      handler.apply null, [ event ]

class EventReactor
  
  @from: ( reactor ) -> 
    Object.assign ( new @ ),
      { reactor, handlers: {} }
  
  when: ( name, handler ) -> 
    ( @handlers[ name ] ?= []).push handler
    @

  each: ( handler ) ->
    ( @handlers._ ?= [] ).push handler
    @
    
  run: ->
    for await event from @reactor
      run @handlers[ event.name ], event
      run @handlers._, event
    undefined
  
  resolve: ( name ) ->
    @run()      
    self = @
    new Promise ( resolve, reject ) ->
      self.when name, resolve
      self.when "failure", ({ error }) -> reject error
    
  [ Symbol.asyncIterator ]: -> @reactor

export default EventReactor
