import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import print from "@dashkite/amen-console"

import Coroutine from "../src/coroutine"
import Channel from "../src/channel"
import Topic from "../src/topic"
import match from "../src/event-selector"
import EventReactor from "../src/event-reactor"
import EventCoroutine from "../src/event-coroutine"

do ->

  print await test "Reactive", [

    test "Coroutine", [

      test "iterator", ->

        multiplier = ( m ) ->
          x = 1
          loop
            m = yield x *= m
            break if m == 0
          return x

        co = Coroutine.make multiplier 2
        assert.equal 2, co.resume()
        assert.equal 6, co.resume 3
        assert.equal 24, co.resume 4
        assert.equal 24, co.resume 0
        assert.throws -> co.resume()

      test "reactor", ->

        multiplier = ( m ) ->
          x = 1
          loop
            m = ( yield await ( x *= m ))
            break if m == 0
          return x

        co = Coroutine.make multiplier 2
        assert.equal 2, await co.resume()
        assert.equal 6, await co.resume 3
        assert.equal 24, await co.resume 4
        assert.equal 24, await co.resume 0
        assert.rejects -> co.resume()

    ]

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

        test "match", do ->

          event =
            name: "value"
            scope: "component"
            url: "https://dashkite.com"
            value: 42

          [
            test "wildcard scope", ->
              assert match "*.value", event
            test "scope and name", ->
              assert match "component.value", event
              assert ! match "controller.value", event
            test "name only", ->
              assert match "value", event
            test "name and property existence", ->
              assert match "value[url]", event
              assert ! match "value[foo]", event
            test "name and property non-existence", ->
              assert match "value[!foo]", event
              assert ! match "value[!url]", event
            test "wildcard scope, name, property existence", ->
              assert match "*.value[url]", event
            test "wildcard scope, name, property value", ->
              assert match "*.value[url='https://dashkite.com']", event
              assert ! match "*.value[url='https://acme.org']", event
              # double-quoted
              assert match '*.value[url="https://dashkite.com"]', event
            test "scope, name, property existence", ->
              assert match "component.value[url]", event
              assert ! match "controller.value[url]", event
            test "name, property value", ->
              assert match "value[value='42']", event
            test "wildcard (scope and name)", ->
              assert match "*", event     
            test "selector list", ->
              assert match "value, foo", event        
              assert match "foo, value", event        
              assert ! match "foo, bar", event    
            test "negated name", ->
              assert match "!foo", event
              assert ! match "!value", event
              assert ! match "foo, !value", event
            test "hyphenated names", ->
              do ({ event } = {}) ->
                event = 
                  name: "add-post" 
                  "the-answer": 42
                assert match "add-post", event
                assert match "add-post[the-answer='42']", event

          ]
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

      test "error handling", ->

        reactor = EventReactor.make do ->
          yield name: "A"
          throw new Error "oops"

        log = []
        caught = false
        
        # Test chaining and catching
        reactor
          .when "A", ( event ) -> log.push event.name
          .catch ( error ) -> 
            log.push error.message
            caught = true

        for await event from reactor
          # iterate to trigger execution
          continue

        assert.deepEqual [ "A", "oops" ], log
        assert caught

    ]

    test "Event Coroutine", [

      test "one ping only", [

        test "synchronous", ->

          source = ->
            yield name: "A", value: 1
            yield name: "B", value: 2
            yield name: "C", value: 3

          results = []
          ( co = EventCoroutine.make source )
            .when "A", ({ value }) -> results.push value
            .when "B", ({ value }) -> results.push value
            .when "C", ({ value }) -> results.push value
            .start()

          assert.deepEqual [ 1, 2, 3 ], results

        test "asynchronous", ->

          source = ->
            yield await name: "A", value: 1
            yield await name: "B", value: 2
            yield await name: "C", value: 3

          results = []
          await do ->
            ( co = EventCoroutine.make source )
              .when "A", ({ value }) -> results.push value
              .when "B", ({ value }) -> results.push value
              .when "C", ({ value }) -> results.push value
              .start()

          assert.deepEqual [ 1, 2, 3 ], results

      ]

      test "ping-pong", [

        test "synchronous", ->

          reactor = ->
            value = yield name: "A", value: 1
            value = yield { name: "B", value }
            yield { name: "C", value }

          result = do ->
            ( co = EventCoroutine.make reactor )
              .when "A", ({ value }) -> ++value
              .when "B", ({ value }) -> ++value
              .when "C", ({ value }) -> ++value
              .start()

          assert.equal 4, result

        test "asynchronous", ->

          reactor = ->
            value = yield await name: "A", value: 1
            value = yield await { name: "B", value }
            yield await { name: "C", value }

          result = await do ->
            ( co = EventCoroutine.make reactor )
              .when "A", ({ value }) -> ++value
              .when "B", ({ value }) -> ++value
              .when "C", ({ value }) -> ++value
              .start()

          assert.equal 4, result

        test "iterator", ->

          reactor = ->
            value = yield name: "A", value: 1
            value = yield { name: "B", value }
            yield { name: "C", value }

          result = do ->
            ( co = EventCoroutine.make reactor )
              .when "A", ({ value }) -> yield return ++value
              .when "B", ({ value }) -> yield return ++value
              .when "C", ({ value }) -> yield return ++value
              .start()

          assert.equal 4, result

        test "reactor", ->

          reactor = ->
            value = yield name: "A", value: 1
            value = yield { name: "B", value }
            yield { name: "C", value }

          result = await do ->
            ( co = EventCoroutine.make reactor )
              .when "A", ({ value }) -> yield return await ++value
              .when "B", ({ value }) -> yield return await ++value
              .when "C", ({ value }) -> yield return await ++value
              .start()

          assert.equal 4, result

      ]

    ]

  ]

  process.exit if success then 0 else 1
