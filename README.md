# Reactive

*Reactive programming support for JavaScript*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

Reactive provides the foundational primitives for building reactive systems using async generators and event streams.

## Features

- Channels for async iteration
- Topics for publish-subscribe messaging
- Event Coroutines for responsive task flow
- Event Reactors for routing and responding to event streams
- Powerful string-based event selector syntax

## Installation

Use your favorite package manager:

```bash
pnpm install @dashkite/reactive
```

## Usage

Create a channel and send messages to it, iterating asynchronously:

```javascript
import { Channel } from "@dashkite/reactive"

const channel = Channel.make()

// Send a message
channel.send("Hello, Reactive!")

// Receive asynchronously
for await (const message of channel) {
  console.log(message)
}
```

## Other Resources

- [Usage Guides](docs/recipes.md)
- [Reference Documentation](docs/reference.md)
- [Technical Notes](docs/technical-notes.md)
- [Testing Guide](docs/testing.md)

## Status

Not suitable for production use. Please report any issues on the [GitHub repository](https://github.com/dashkite/reactive).
