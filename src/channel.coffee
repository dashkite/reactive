import { Queue } from "@dashkite/joy/iterable"

class Channel

  @close: Symbol "close"

  @make: ->
    Object.assign ( new @ ),
      closed: false
      queue: Queue.make()

  source: ( channel ) ->
    ( @send message ) for await message from channel
      
  send: ( message ) ->
    if @closed
      throw new Error "send: channel closed"
    else
      @queue.enqueue message

  receive: -> 
    if @closed
      throw new Error "receive: channel closed"
    else
      @queue.dequeue()

  close: -> @send Channel.close
      
  listen: ->
    until @closed
      message = await @receive()
      if message == Channel.close
        @closed = true
      else
        yield message
    return # don't return comprehension
            
  [ Symbol.asyncIterator ]: -> @listen()


export default Channel