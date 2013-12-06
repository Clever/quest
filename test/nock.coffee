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

  it 'supports cookies with a domain', (done) ->
    scope = nock('http://example.com')
      .matchHeader('cookie', 'cookie=test')
      .get('/test')
      .reply(200, '')
    j = quest.jar()
    j.add quest.cookie 'cookie=test; domain=example.com'
    quest { uri: 'http://example.com/test', jar: j }, (err, resp, body) ->
      assert.ifError err, "did not expect error"
      scope.done()
      done()

  it 'supports cookies with a wildcard domain', (done) ->
    scope = nock('http://test.example.com')
      .matchHeader('cookie', 'cookie=test')
      .get('/test')
      .reply(200, '')
    j = quest.jar()
    j.add quest.cookie 'cookie=test; domain=.example.com'
    quest { uri: 'http://test.example.com/test', jar: j }, (err, resp, body) ->
      assert.ifError err, "did not expect error"
      scope.done()
      done()

  it 'does not send cookies to the wrong domain', (done) ->
    scope = nock('http://test.example.com')
      .matchHeader('cookie', 'cookie=test')
      .get('/test')
      .reply(200, '')
    j = quest.jar()
    j.add quest.cookie 'cookie=test; domain=.example.com'
    j.add quest.cookie 'badcookie=bad; domain=example.com'
    j.add quest.cookie 'badcookie2=bad; domain=nottest.example.com'
    quest { uri: 'http://test.example.com/test', jar: j }, (err, resp, body) ->
      assert.ifError err, "did not expect error"
      scope.done()
      done()
