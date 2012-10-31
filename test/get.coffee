quest  = require "#{__dirname}/../index"
assert = require 'assert'
_ = require 'underscore'

describe 'quest', ->
  safe_err = (err) ->
    err = new Error err if err? and err not instanceof Error
    err
  _.each ['https', 'http'], (protocol) ->
    describe protocol, ->
      it "detects no uri", (done) ->
        quest {}, (err, resp, body) ->
          assert.equal err, 'Options does not include uri'
          done()

      it 'detects request errors', (done) ->
        uri = 'arhgglserhslfhs'
        options = uri: uri
        quest options, (err, resp, body) ->
          assert.equal err.code, "ENOTFOUND"
          done()

      it 'supports no protocol', (done) ->
        options =
          uri: "httpbin.org/get"
          json: true
        quest options, (err, resp, body) ->
          assert not err, "Has error #{err}"
          assert.equal resp.statusCode, 200, "Status code should be 200, is #{resp.statusCode}"
          assert.equal body.headers.Host, 'httpbin.org'
          done safe_err err

      it 'supports simple gets', (done) ->
        options =
          uri: "#{protocol}://httpbin.org/get"
        quest options, (err, resp, body) ->
          assert not err, "Has error #{err}"
          assert.equal resp.statusCode, 200, "Status code should be 200, is #{resp.statusCode}"
          assert.equal JSON.parse(body).headers.Host, 'httpbin.org'
          done safe_err err

      it 'supports interpreting responses as json', (done) ->
        options =
          uri: "#{protocol}://httpbin.org/get"
          json: true
        quest options, (err, resp, body) ->
          assert not err, "Has error #{err}"
          assert.equal resp.statusCode, 200, "Status code should be 200, is #{resp.statusCode}"
          assert.equal body.headers.Host, 'httpbin.org'
          done safe_err err

      it 'has a default user-agent', (done) ->
        default_user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_3) AppleWebKit/537.16 (KHTML, like Gecko) Chrome/24.0.1297.0 Safari/537.16'
        options =
          uri: "#{protocol}://httpbin.org/user-agent"
          json: true
        quest options, (err, resp, body) ->
          assert not err, "Has error #{err}"
          assert.equal resp.statusCode, 200, "Status code should be 200, is #{resp.statusCode}"
          assert.equal body['user-agent'], default_user_agent
          done safe_err err

      it 'allows you to modify the headers', (done) ->
        other_user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.16 (KHTML, like Gecko) Chrome/24.0.1297.0 Safari/537.16'
        options =
          uri: "#{protocol}://httpbin.org/user-agent"
          json: true
          headers:
            'user-agent': other_user_agent
        quest options, (err, resp, body) ->
          assert not err, "Has error #{err}"
          assert.equal resp.statusCode, 200, "Status code should be 200, is #{resp.statusCode}"
          assert.equal body['user-agent'], other_user_agent
          done safe_err err

      it 'allows you to set a querystring parameter', (done) ->
        options =
          uri: "#{protocol}://httpbin.org/response-headers"
          qs:
            my_param: 'trolling'
        quest options, (err, resp, body) ->
          assert not err, "Has error #{err}"
          assert.equal resp.statusCode, 200, "Status code should be 200, is #{resp.statusCode}"
          assert.equal resp.headers.my_param, 'trolling', "Parameter should be trolling, is #{resp.headers.my_param}"
          done safe_err err