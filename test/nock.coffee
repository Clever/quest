quest  = require "#{__dirname}/../index"
assert = require 'assert'
nock   = require 'nock'

describe 'nock', ->
  it 'works with nock', (done) ->
    nock('http://test.com').post('/path').reply(200)
    quest { uri: 'http://test.com/path', method: 'post' }, (err, resp, body) ->
      console.log arguments
      assert.ifError err, "did not expect error"
      assert resp, "did not get a response from nock'd request"
      assert body, "did not get a body from nock'd request"
      done()
