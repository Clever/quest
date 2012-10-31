quest  = require "#{__dirname}/../index"
assert = require 'assert'
_ = require 'underscore'

describe 'quest', ->
  safe_err = (err) ->
    err = new Error err if err? and err not instanceof Error
    err
  _.each ['https', 'http'], (protocol) ->
    describe protocol, ->
      it 'posts some json data', (done) ->
        @timeout 20000
        json = my_param: 'trolling'
        options =
          uri: "#{protocol}://httpbin.org/post"
          json: json
          method: 'post'
        quest options, (err, resp, body) ->
          assert not err, "Has error #{err}"
          assert.equal resp.statusCode, 200, "Status code should be 200, is #{resp.statusCode}"
          assert.equal JSON.stringify(body.json), JSON.stringify json
          done safe_err err

      it 'posts some form data', (done) ->
        @timeout 20000
        form = my_param: 'trolling'
        options =
          uri: "#{protocol}://httpbin.org/post"
          form: form
          method: 'post'
          json: true
        quest options, (err, resp, body) ->
          assert not err, "Has error #{err}"
          assert.equal resp.statusCode, 200, "Status code should be 200, is #{resp.statusCode}"
          assert.equal JSON.stringify(body.form), JSON.stringify form
          done safe_err err