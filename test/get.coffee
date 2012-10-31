quest  = require "#{__dirname}/../index"
assert = require 'assert'

describe 'quest', ->
  safe_err = (err) ->
    err = new Error err if err? and err not instanceof Error
    err
  it 'supports simple gets', (done) ->
    options =
      uri: 'http://httpbin.org/get'
    quest options, (err, resp, body) ->
      assert.equal resp.statusCode, 200
      assert.equal JSON.parse(body).headers.Host, 'httpbin.org'
      done safe_err err

  it 'supports simple gets with json responses', (done) ->
    options =
      uri: 'http://httpbin.org/get'
      json: true
    quest options, (err, resp, body) ->
      assert.equal resp.statusCode, 200
      assert.equal body.headers.Host, 'httpbin.org'
      done safe_err err