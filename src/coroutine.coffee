class Coroutine

  @make: ( reactor ) ->
    Object.assign ( new @ ), { reactor, done: false }

  resume: ( value ) ->
    if !@done
      result = @reactor.next value
      if result.then?
        result.then ({ value, @done }) => value
      else
        { value, @done } = result
        value
    else
      throw new Error "attempt to resume
        coroutine after exiting"

export default Coroutine