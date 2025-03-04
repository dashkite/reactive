import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import print from "@dashkite/amen-console"

import Channel from "../src/channel"
import Topic from "../src/topic"

do ->

  print await test "Reactive", [

    test "Channel", [

      test "basic scenario", ->

        channel = Channel.make()
        log = []

        closed = new Promise ( resolve ) ->
          for await value from channel
            log.push { value }
          resolve true

        channel.send "foo"
        channel.send "bar"
        channel.close()
        assert await closed
        assert.deepEqual log, [
          { value: "foo" }
          { value: "bar" }
        ]
    ]

    test "Topic", [

      
      test "basic scenario", ->

        topic = Topic.make()
        log = []

        subscriptions =
          a: topic.subscribe()
          b: topic.subscribe()

        closed =
          a: new Promise ( resolve ) ->
            for await value from subscriptions.a
              log.push a: value
            resolve true
          b: new Promise ( resolve ) ->
            for await value from subscriptions.b
              log.push b: value
            resolve true

        topic.publish "foo"
        topic.unsubscribe subscriptions.a
        topic.publish "bar"
        topic.unsubscribe subscriptions.b
        
        assert await closed.a
        assert await closed.b
        assert.deepEqual log, [
          { a: "foo" }
          { b: "foo" }
          { b: "bar" }
        ]

    ]

  ]

  process.exit if success then 0 else 1
