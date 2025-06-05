import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import print from "@dashkite/amen-console"

import Channel from "../src/channel"
import Topic from "../src/topic"
import match from "../src/event-selector"
import EventReactor from "../src/event-reactor"

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

        topic.close()
        
        assert await closed.a
        assert await closed.b
        assert.deepEqual log, [
          { a: "foo" }
          { b: "foo" }
          { b: "bar" }
        ]

    ]

    test "Event Reactor", [

      test "selector", [

        test "match", ->

          event =
            name: "value"
            scope: "component"
            url: "https://dashkite.com"
            value: 42

          assert match "*.value", event
          assert match "component.value", event
          assert ! match "controller.value", event
          assert match "value", event
          assert match "value[url]", event
          assert ! match "value[foo]", event
          assert match "*.value[url]", event
          assert match "*.value[url='https://dashkite.com']", event
          assert ! match "*.value[url='https://acme.org']", event
          assert match '*.value[url="https://dashkite.com"]', event
          assert match "component.value[url]", event
          assert ! match "controller.value[url]", event
          assert match "value[value='42']", event
          assert match "*", event        
          assert match "value, foo", event        
          assert match "foo, value", event        
          assert ! match "foo, bar", event    
          assert ! match "!value", event
          assert match "!foo", event
          assert ! match "foo, !value", event    

      ]

      test "basic reactor", [

        test "sync", ->

          reactor = EventReactor.make do ->
              for x in [ 1..5 ]
                yield name: "number", value: x
            
            .when "number", ( event ) ->
              yield event.value

          result = ( x for await x from reactor )
          assert.deepEqual [ 1..5 ], result

        test "async", ->
          reactor = EventReactor.make do ->
              for x in [ 1..5 ]
                yield name: "number", value: await x
            
            .when "number", ( event ) ->
              yield event.value

          result = ( x for await x from reactor )
          assert.deepEqual [ 1..5 ], result
      ]

    ]

  ]

  process.exit if success then 0 else 1
