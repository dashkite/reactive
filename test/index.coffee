import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import print from "@dashkite/amen-console"

import Channel from "../src/channel"

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

  ]

  process.exit if success then 0 else 1
