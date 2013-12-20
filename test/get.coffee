quest  = require "#{__dirname}/../index"
assert = require 'assert'
_      = require 'underscore'
async  = require 'async'

describe 'quest', ->
  safe_err = (err) ->
    err = new Error err if err? and err not instanceof Error
    err
  _.each ['http', 'https'], (protocol) ->
    describe protocol, ->
      it "detects no uri", (done) ->
        @timeout 20000
        quest {}, (err, resp, body) ->
          assert.equal err?.message, 'Options does not include uri'
          done()

      it "detects non-string uri", (done) ->
        @timeout 20000
        quest {uri: {}}, (err, resp, body) ->
          assert.equal err?.message, 'Uri {} is not a string'
          done()

      it 'detects request errors', (done) ->
        @timeout 20000
        uri = 'arhgglserhslfhs'
        options = uri: uri
        quest options, (err, resp, body) ->
          assert.equal err?.code, "ENOTFOUND"
          done()

      it 'supports no protocol', (done) ->
        @timeout 20000
        options =
          uri: "httpbin.org/get"
          json: true
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
          assert.equal body?.headers?.Host, 'httpbin.org'
          done safe_err err

      it 'supports any case protocol', (done) ->
        @timeout 20000
        options =
          uri: "HTTP://httpbin.org/get"
          json: true
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
          assert.equal body?.headers?.Host, 'httpbin.org'
          done safe_err err

      it 'supports simple gets', (done) ->
        @timeout 20000
        options =
          uri: "#{protocol}://httpbin.org/get"
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
          assert.equal JSON.parse(body)?.headers?.Host, 'httpbin.org'
          done safe_err err

      it "supports simple gets with a uri instead of an options object", (done) ->
        @timeout 20000
        uri = "#{protocol}://httpbin.org/get"
        quest uri, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
          assert.equal JSON.parse(body)?.headers?.Host, 'httpbin.org'
          done safe_err err

      it 'supports interpreting responses as json', (done) ->
        @timeout 20000
        options =
          uri: "#{protocol}://httpbin.org/get"
          json: true
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
          assert.equal body?.headers?.Host, 'httpbin.org'
          done safe_err err

      it 'has a default user-agent', (done) ->
        @timeout 20000
        default_user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_3) AppleWebKit/537.16 (KHTML, like Gecko) Chrome/24.0.1297.0 Safari/537.16'
        options =
          uri: "#{protocol}://httpbin.org/user-agent"
          json: true
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
          assert.equal body?['user-agent'], default_user_agent
          done safe_err err

      it 'allows you to modify the headers', (done) ->
        @timeout 20000
        other_user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.16 (KHTML, like Gecko) Chrome/24.0.1297.0 Safari/537.16'
        options =
          uri: "#{protocol}://httpbin.org/user-agent"
          json: true
          headers:
            'user-agent': other_user_agent
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
          assert.equal body?['user-agent'], other_user_agent
          done safe_err err

      it 'allows you to set a querystring parameter', (done) ->
        @timeout 20000
        options =
          uri: "#{protocol}://httpbin.org/response-headers"
          qs:
            my_param: 'trolling'
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
          assert.equal resp?.headers?.my_param, 'trolling', "Parameter should be trolling, is #{resp?.headers?.my_param}"
          done safe_err err

      it "doesn't follow redirects when disabled", (done) ->
        @timeout 20000
        options =
          uri: "#{protocol}://httpbin.org/redirect/3"
          followRedirects: false
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 302, "Status code should be 302, is #{resp?.statusCode}"
          assert.equal resp?.headers?.location, '/redirect/2'
          done safe_err err

      it 'follows redirects', (done) ->
        @timeout 20000
        options =
          uri: "#{protocol}://httpbin.org/redirect/3"
          json: true
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
          assert.equal body?.url, "http://httpbin.org/get"
          done safe_err err

      it "doesn't follow relative redirects when disabled", (done) ->
        @timeout 20000
        options =
          uri: "#{protocol}://httpbin.org/relative-redirect/3"
          followRedirects: false
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 302, "Status code should be 302, is #{resp?.statusCode}"
          assert.equal resp?.headers?.location, '/relative-redirect/2'
          done safe_err err

      it 'follows relative redirects', (done) ->
        @timeout 20000
        options =
          uri: "#{protocol}://httpbin.org/relative-redirect/3"
          json: true
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
          assert.equal body?.url, "http://httpbin.org/get"
          done safe_err err

      it 'has a maximum number of redirects', (done) ->
        @timeout 20000
        options =
          uri: "#{protocol}://httpbin.org/redirect/3"
          json: true
          maxRedirects: 2
        quest options, (err, resp, body) ->
          assert.equal err?.message, 'Exceeded max redirects'
          done()

      it 'supports custom cookie jars', (done) ->
        @timeout 20000
        j = quest.jar()
        cookie = quest.cookie 'my_param=trolling'
        j.add cookie
        options =
          uri: "#{protocol}://httpbin.org/cookies"
          jar: j
          json: true
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
          assert.equal _(body?.cookies)?.keys()?.length, 1
          assert.equal body?.cookies?.my_param, 'trolling'
          done safe_err err

      it 'stores cookies', (done) ->
        @timeout 20000
        j = quest.jar()
        uri = "#{protocol}://httpbin.org/cookies/set"
        async.waterfall [
          (cb_wf) ->
            options =
              uri: uri
              qs:
                my_param: 'trolling'
                my_param2: 'trolling2'
              jar: j
              json: true
            quest options, cb_wf
          (resp, body, cb_wf) ->
            assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
            cookies = j.get uri
            assert.equal cookies.length, 2
            my_param = 0
            my_param2 = 1
            if cookies[0]?.name is 'my_param2'
              my_param = 1
              my_param2 = 0
            assert.equal cookies[my_param]?.name, 'my_param'
            assert.equal cookies[my_param]?.value, 'trolling'
            assert.equal cookies[my_param2]?.name, 'my_param2'
            assert.equal cookies[my_param2]?.value, 'trolling2'

            options =
              uri: "#{protocol}://httpbin.org/cookies"
              jar: j
              json: true
            quest options, cb_wf
          (resp, body, cb_wf) ->
            assert.equal resp?.statusCode, 200, "Status code should be 200, is #{resp?.statusCode}"
            assert.equal _(body?.cookies)?.keys().length, 2
            assert.equal body?.cookies?.my_param, 'trolling'
            assert.equal body?.cookies?.my_param2, 'trolling2'
            cb_wf()
        ], (err) -> done safe_err err

      it 'supports timeouts', (done) ->
        @timeout 20000
        options =
          uri: "#{protocol}://httpbin.org:88/get"
          timeout: 10
        quest options, (err, resp, body) ->
          assert.equal err.code, "ETIMEDOUT"
          setTimeout done, 100

      it 'only calls the callback once on timeout redirects', (done) ->
        @timeout 20000
        cnt = 0
        options =
          uri: "#{protocol}://httpbin.org/redirect/1"
          timeout: 1500
        quest options, (err, resp, body) ->
          cnt += 1
          assert.equal cnt, 1
          assert.ifError err
          assert.equal resp.statusCode, 200
          setTimeout done, 3000

      it 'supports changing the port', (done) ->
        @timeout 20000
        options =
          uri: "#{protocol}://httpbin.org:81334/get"
          timeout: 10000
        quest options, (err, resp, body) ->
          assert err
          # Produces ECONNREFUSED locally but ETIMEDOUT on travis
          # assert.equal err?.code, "ECONNREFUSED"
          done()

      it 'supports overriding content-type with a json body', (done) ->
        @timeout 20000
        options =
          uri: "#{protocol}://httpbin.org/headers"
          timeout: 10000
          json: some_field: 'some_val'
          headers: 'content-type': null
        quest options, (err, resp, body) ->
          assert.equal body.headers['Content-Type'], 'null' # httpbin returns all headers as strings
          done err

      it 'supports sending basic auth in the url', (done) ->
        options =
          uri: "#{protocol}://username:password@httpbin.org/headers"
          json: true
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal body.headers.Authorization, 'Basic dXNlcm5hbWU6cGFzc3dvcmQ='
          done()

      it 'supports sending basic auth in the options', (done) ->
        options =
          uri: "#{protocol}://httpbin.org/headers"
          auth: 'username:password'
          json: true
        quest options, (err, resp, body) ->
          assert.ifError err
          assert.equal body.headers.Authorization, 'Basic dXNlcm5hbWU6cGFzc3dvcmQ='
          done()
