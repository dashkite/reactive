# Reference

## `Channel`

Channels act as isolated conduits for a single flow of asynchronous data. Built upon native JavaScript iterables, they rely on the event loop for bookkeeping.

### `make`
$make: () \rightarrow channel$

Instantiates a new, empty channel ready to send and receive messages.

### `merge`
$merge: (channels: array) \rightarrow channel$

Composes multiple channels into a single unified stream, allowing developers to create composite data flows.

### `source`
$source: (channel: channel)$

Pipes all incoming messages from the provided source channel directly into this channel.

### `send`
$send: (message: any)$

Pushes a message onto the channel's internal queue. Throws an error if the channel has been closed.

### `receive`
$receive: () \rightarrow any$

Retrieves the next message from the channel's queue. Throws an error if the channel has been closed.

### `close`
$close: ()$

Sends a specialized `close` symbol to the channel, shutting it down and notifying consumers to stop iterating.

### `listen`
$listen: () \rightarrow asyncgenerator$

Returns an asynchronous generator that continuously yields messages from the channel until it receives a close signal.

## `Coroutine`

Coroutines provide the underlying mechanics to build small, implicit state machines without manual state bookkeeping.

### `make`
$make: (reactor: any) \rightarrow coroutine$

Initializes a new coroutine mapped to a specific reactor, setting its initial completion state to false.

### `resume`
$resume: (value: any) \rightarrow any$

Resumes the coroutine with the provided value, driving the state machine forward by one step. Throws an error if the coroutine has already exited.

## `EventCoroutine`

An abstraction over coroutines that ties into the CSS-like event filtering syntax.

### `make`
$make: (reactor: function | object) \rightarrow eventcoroutine$

Instantiates a new event-driven coroutine with an underlying function or object reactor.

### `bind`
$bind: (self: object) \rightarrow eventcoroutine$

Binds the coroutine's internal context to a specific object.

### `when`
$when: (selector: string, handler: function) \rightarrow eventcoroutine$

Registers a CSS-like string selector and its corresponding handler. Supports multiplexing over a single event stream.

### `start`
$start: () \rightarrow any$

Begins executing the event coroutine, utilizing the JavaScript event loop to drive the sequence.

## `EventReactor`

Reactors represent the highest level of abstraction for composing channels and topics. They act as state machines routing events.

### `make`
$make: (reactor: any) \rightarrow eventreactor$

Constructs a new event reactor around an existing async iterable or generator.

### `run`
$run: (reactor: any) \rightarrow any$

Static convenience method to immediately instantiate and start a reactor.

### `bind`
$bind: (self: object) \rightarrow eventreactor$

Binds the reactor's context to the provided object.

### `when`
$when: (selector: string, handler: function) \rightarrow eventreactor$

Assigns a behavior to fire whenever an event matches the provided CSS-like selector.

### `catch`
$catch: (catchhandler: function) \rightarrow eventreactor$

Registers an error handler for the reactor to catch issues thrown during event processing.

### `forward`
$forward: (selector: string) \rightarrow eventreactor$

Registers a selector that automatically forwards matching events by yielding them directly.

### `start`
$start: () \rightarrow asyncgenerator$

Initiates the reactor loop, asynchronously awaiting events and delegating them to the appropriate handlers based on selector rules.

## `Topic`

Topics provide a multiplexing abstraction, adhering to the publish-subscribe pattern to broadcast single events across multiple channels.

### `make`
$make: () \rightarrow topic$

Creates a new topic capable of managing multiple subscriber channels.

### `publish`
$publish: (message: any) \rightarrow topic$

Broadcasts a message to all currently active subscriber channels. Channels that have closed are automatically pruned.

### `subscribe`
$subscribe: () \rightarrow channel$

Generates and returns a fresh, dedicated `Channel` for a new subscriber to receive broadcasted messages.

### `unsubscribe`
$unsubscribe: (channel: channel)$

Closes the specified subscriber's channel and removes it from the topic's distribution list.

### `close`
$close: ()$

Closes all subscriber channels and shuts down the topic permanently.

### `prune`
$prune: ()$

Iterates over all subscriptions and removes any channels that have been closed.

## `match`

$match: (pattern: string, event: object) \rightarrow boolean$

Parses a CSS-like string selector and evaluates it against an event object. This allows creators to explicitly express scope and construct specific names for event multiplexing.
