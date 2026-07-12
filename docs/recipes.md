# Usage Guides

## Creating and using a channel

Channels allow developers to manage a single flow of information. Rooted in the [channel programming pattern](https://en.wikipedia.org/wiki/Channel_(programming)), they provide an isolated conduit for messages.

To use a channel, call the `make` factory method. You can then `send` messages to the channel and use an asynchronous `for await` loop to receive them.

```coffeescript
import { Channel } from "@dashkite/reactive"

channel = Channel.make()
channel.send "data"

for await message from channel
  # Process the message here
```

## Multiplexing with topics

When developers need to distribute a single message to multiple subscribers—the [publish-subscribe pattern](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern)—they use topics. Topics allow multiplexing by granting each subscriber their own dedicated channel.

First, create a topic using `Topic.make()`. Then, invoke `subscribe` to obtain a channel for receiving messages. Use `publish` on the topic to broadcast a message to all active subscribers.

```coffeescript
import { Topic } from "@dashkite/reactive"

topic = Topic.make()

# Create multiple independent subscriber channels
primarySubscriber = topic.subscribe()
loggingSubscriber = topic.subscribe()

# A single published message is distributed to all active channels
topic.publish type: "notification", body: "Update available"

# Each subscriber receives the broadcast on their own channel
processPrimary = ->
  for await message from primarySubscriber
    # Process the primary business logic
    console.log message

processLogging = ->
  for await message from loggingSubscriber
    # Process the logging logic
    console.log "Log: #{ message.type }"

processPrimary()
processLogging()
```

## Declarative event handling with EventReactor

Event Reactors provide a higher-level abstraction for handling event streams compared to simple `for await...from` loops. They enable declarative event handling and are isomorphic to state machines. A reactor's `.when` blocks define the transitions of a state machine. Use this to maintain clear state-based logic within components.

### State Machine Isomorphism and Context Binding

When handling events that interact with component state, always use `.bind @` to ensure handlers can call methods on the component instance (like `@render` or `@dispatch`).

```coffeescript
import { EventReactor } from "@dashkite/reactive"

listen: ->
  yield from EventReactor
    .make @model.listen()
    .bind @
    .when "connect", -> 
      # Transition to 'connected' state
      @render html state: "loading"
    .when "value", ( event ) ->
      # Transition to 'data' state
      @render html data: event.value
```

### Merging, Forwarding, and Flow Control

Use `yield from` within a handler to merge another event stream into the current reactor's logic. Use `.forward` to pass specific events through to the reactor's output stream unhandled. For specific flow control, use `yield` inside handlers to propagate custom events to the component's output channel.

```coffeescript
listen: ->
  yield from EventReactor
    .make @source.listen()
    .bind @
    .forward "notification"
    .when "connect", ->
      # Pull events from another controller into this reactor
      yield from @controller.listen()
    .when "ping", ->
      # Propagate an event to the output channel
      yield type: "pong"
```

### Nesting Reactors

For large state machines, divide them into smaller reactors and use them within `.when` blocks to handle sub-states organically.

```coffeescript
listen: ->
  yield from EventReactor
    .make @source.listen()
    .bind @
    .when "authenticated", ( event ) ->
      # Delegate to a nested reactor for authenticated behaviors
      yield from @handleAuthenticatedSession event
```

## Forcing asynchronous behavior

Because CoffeeScript determines whether a function is a synchronous or asynchronous generator based on the presence of the `await` keyword, developers must be explicit when a generator contains no internal `await` statements but needs to remain compatible with `for await...from` loops.

To guarantee that the function resolves to an async iterator, place `await return` at the end of the generator. This forces the CoffeeScript compiler to wrap the function correctly.

```coffeescript
import { EventReactor } from "@dashkite/reactive"

class AuthController
  
  listen: ->
    # Delegating iteration using yield from
    yield from EventReactor
      .make @source.listen()
      .bind @
      .when "login", ( event ) ->
        yield type: "authenticated", user: event.user
    
    # Force CoffeeScript to compile this as an async generator
    await return
```
