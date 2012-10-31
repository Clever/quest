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

  it 'supports interpreting responses as json', (done) ->
    options =
      uri: 'http://httpbin.org/get'
      json: true
    quest options, (err, resp, body) ->
      assert.equal resp.statusCode, 200
      assert.equal body.headers.Host, 'httpbin.org'
      done safe_err err

  it 'has a default user-agent', (done) ->
    default_user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_3) AppleWebKit/537.16 (KHTML, like Gecko) Chrome/24.0.1297.0 Safari/537.16'
    options =
      uri: 'http://httpbin.org/user-agent'
      json: true
    quest options, (err, resp, body) ->
      assert.equal resp.statusCode, 200
      assert.equal body['user-agent'], default_user_agent
      done safe_err err

  it 'allows you to modify the headers', (done) ->
    other_user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.16 (KHTML, like Gecko) Chrome/24.0.1297.0 Safari/537.16'
    options =
      uri: 'http://httpbin.org/user-agent'
      json: true
      headers:
        'user-agent': other_user_agent
    quest options, (err, resp, body) ->
      assert.equal resp.statusCode, 200
      assert.equal body['user-agent'], other_user_agent
      done safe_err err