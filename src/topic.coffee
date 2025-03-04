import Channel from "./channel"

class Topic

  @make: ->
    Object.assign ( new @ ),
      subscribers: []
      closed: false
      
  publish: ( message ) ->
    if @closed
      throw new Error "publish: topic closed"
    else
      # we prune here just in case
      # but it's best to call unsubscribe
      @prune()
      for subscriber in @subscribers
        subscriber.send message
      return @
  
  subscribe: ->
    if @closed
      throw new Error "subscribe: topic closed"
    else
      channel = Channel.make()
      @subscribers.push channel
      channel

  unsubscribe: ( channel ) ->
    if @closed
      throw new Error "unsubscribe: topic closed"
    else if channel in @subscribers
      channel.close()
      @prune()
    else
      throw new Error "unsubscribe: not a subscription channel"
  
  close: ->
    if !@closed
      @prune()
      channel.close() for channel in @subscribers
      subscribers = []
      @closed = true

  prune: ->
    @subscribers =
      channel for channel in @subscribers when !( channel.closed )

export default Topic