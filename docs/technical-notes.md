# Technical Notes

### JavaScript Iterators and the Event Loop
The foundation of the Reactive package rests on JavaScript iterators (both synchronous and asynchronous). Native iterators provide stability because the JavaScript event loop manages all the bookkeeping. This foundational layer allows creators to construct higher-level primitives without reinventing core mechanisms or battling asynchronous race conditions. All methods intended to be used as event streams (like `listen`) should uniformly return async iterators.

### Async Generator Semantics
Reactive programming in Dashkite revolves around using async iterators (reactors) to model application logic as a sequence of events. 

- **Delegation with `yield from`:** Use `yield from` to delegate iteration to another async iterable (such as an `EventReactor` or another reactor's `listen()` method). This maps directly to JavaScript's [`yield*` operator](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/yield*). This allows events from the source to flow directly through your function. Favor `yield from` and `EventReactor` over manual `for await` loops whenever possible.

### Forcing Async Semantics (`await return`)
Because CoffeeScript uses the content of the function to determine asynchronicity, we cannot declare it explicitly. This is a notorious pitfall, particularly for LLMs generating code, so we stress getting it correct on the first try. If a generator function body does not contain any other `await` statements, the CoffeeScript compiler will default to a synchronous generator. To ensure it returns an **async iterator** (compatible with `for await...from`), append `await return` to the end of the function.

```coffeescript
listen: ->
  yield from someAsyncIterable
  await return
```

### Avoiding Redundant Closures
Do not wrap reactor definitions in IIFEs (e.g., `do =>`) unless you specifically require a localized state closure. `yield from` works directly on the result of a reactor chain or async iterable.

### Exception Handling
Errors in reactors follow standard async generator semantics and propagate up the chain when using `yield from`.
- **Standard `try/catch`:** Standard `try/catch` blocks can be used around `yield from` or within reactor logic to handle exceptions locally.
- **Event Reactor `.catch`:** The `EventReactor` class provides a `.catch(handler)` method for declarative error handling. It supports chaining and handles errors originating from both the source reactor and individual `.when` handlers.

### Implicit State Machines and Event Selectors
Because our interfaces compose iterables, we enable straightforward state management over the event loop. Event Reactors behave as small, implicit state machines that manage these transitions.
To support multiplexing over single event streams, the `match` function parses string-based event selectors into evaluator predicates. This syntax enables creators to express scope within events, construct specific names, and apply boolean operators (`&`, `|`, `!`). When matching patterns within an `EventReactor`, the most specific match always wins. This logic avoids regular expressions by utilizing the `@dashkite/parse` library.

### Coroutine and Reactor Termination
A reactor typically runs until its source channel is closed. It is vital to ensure that any resources or intervals started within a reactor are properly cleaned up when the reactor terminates. Similarly, coroutines track their internal `done` state to prevent resumption after exiting. A thrown error prevents executing any further operations on a closed coroutine, improving stability in event-driven flows.
