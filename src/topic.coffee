import Channel from "./channel"

class Topic

  @make: ->
    Object.assign ( new @ ),
      subscribers: []
      
  publish: ( message ) ->
    # we prune here just in case
    # but it's best to call unsubscribe
    @prune()
    for subscriber in @subscribers
      subscriber.send message
    return @
  
  subscribe: ->
    channel = Channel.make()
    @subscribers.push channel
    channel

  unsubscribe: ( channel ) ->
    channel.close()
    @prune()
    
  prune: ->
    @subscribers =
      channel for channel in @subscribers when !( channel.closed )

export default Topic