# TODO possibly allow from to take a list of valid states
#      so that we can flag handlers for invalid states
#      success/failure could be a given?

# TODO make run a generic so that it can take a gen fn

class EventReactor
  
  @from: ( reactor ) -> 
    Object.assign ( new @ ),
      { reactor, handlers: {} }
  
  when: ( name, handler ) -> 
    @handlers[ name ] = handler
    @
    
  run: ->
    for await event from @reactor
      @handlers[ event.name ]?.apply null, [ event ]
    undefined
  
  resolve: ( name ) ->
    @run()      
    new Promise ( resolve, reject ) ->
      self.handlers[ name ] = resolve
      self.handlers.failure ?= reject
    
  [ Symbol.asyncIterator ]: -> @reactor

export default EventReactor