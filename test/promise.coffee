quest  = require "#{__dirname}/../index"
assert = require 'assert'
_      = require 'underscore'
async  = require 'async'

describe 'promise support', ->
  it 'returns a promise when no callback is given', (done) ->
    actual = quest "http://httpbin.org/get"
    assert.equal typeof(actual.then), 'function'
    done()

  it 'is thenable on success', (done) ->
    @timeout 20000
    options =
      uri: "http://httpbin.org/get"
    quest options
      .then (resp) ->
        assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
        assert.equal JSON.parse(resp.body)?.headers?.Host, 'httpbin.org'
        done()
      , (err) ->
        assert.ifError err
        done()
  
  it 'is catchable on error', (done) ->
    @timeout 20000
    options =
      uri: {}
    quest options
      .then (resp) ->
        assert.fail "success", "failure", "Request should not have succeeded"
        done()
      .catch (err) ->
        assert.equal err?.message, 'Uri {} is not a string'
        done()
