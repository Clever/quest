quest  = require "#{__dirname}/../index"
assert = require 'assert'
nock   = require 'nock'

describe 'nock', ->
  it 'works with nock', (done) ->
    nock('http://test.com').post('/path').reply(200, {success: 1})
    quest { uri: 'http://test.com/path', method: 'post', json: true }, (err, resp, body) ->
      assert.ifError err, "did not expect error"
      assert resp?, "did not get a response from nock'd request"
      assert body?, "did not get a body from nock'd request"
      assert.equal body.success, 1
      done()
