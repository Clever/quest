# Quest - massively simplified, super lightweight HTTP requests

[![Build Status](https://travis-ci.org/Clever/quest.png)](https://travis-ci.org/Clever/quest)

## Install

<pre>
  npm install quest
</pre>

## Super simple to use

Quest is designed to be the simplest way possible to make http calls, as well as being a drop-in replacement for the popular `request` library. It supports HTTPS and follows redirects by default.

```coffeescript
quest = require 'quest'
quest 'www.google.com', (err, response, body) ->
  console.log body if not err? and response.statusCode is 200
```

## Supported options
* `uri` - fully qualified uri (e.g. http://google.com). if protocol is left off, assumes http://. may include basic auth
* `auth` - a string of the form `username:password` to be used for http basic auth
* `qs` - object containing querystring values to be appended to the uri
* `method` - http method, defaults to GET
* `headers` - http headers, defaults to {}
* `body` - entity body for POST and PUT requests. must be string
* `form` - object containing form values to send in the body. also adds `content-type: application/x-www-form-urlencoded; charset=utf-8` to the header
* `json` - if true, parses response as JSON. if object, additionally sends JSON representation of the object in tne body and adds `content-type: application/json` to the header
* `followRedirects` - follow HTTP 3xx responses as redirects. defaults to true
* `followAllRedirects` - follow non-GET HTTP 3xx responses as redirects. defaults to false
* `maxRedirects` - the maximum number of redirects to follow. defaults to 10
* `jar` - cookies are enabled by default. set to `false` to disable. optionally pass in your own custom cookie jar (see Cookies below)
* `timeout` - integer containing the number of milliseconds to wait for a request to respond before aborting the request

The options object is passed in instead of a url string.
```coffeescript
quest = require 'quest'

options =
  uri: 'www.google.com'
  method: "POST"

quest options, (err, response, body) ->
  console.log body if not err? and response.statusCode is 200
```

## Cookies
Cookies are enabled by default. This means that if your requests involved redirection, any redirects will contain cookies set prior. To disable cookies, set jar to false.

If you want to use a custom cookie jar (instead of letting quest use its own default cookie jar) you do so by specifying a jar as an option:

```coffeescript
j = quest.jar()
quest {uri: 'www.google.com', jar: j}, () ->
 quest {uri: 'images.google.com', jar: j}, () ->
   # The request to Google images was sent with any cookies that were set by the original request to Google
```

Note that any cookies that earlier requests set are set in your custom jar, so you can use them for later requests. You can also set your own cookies when you specify a jar:

```coffeescript
j = quest.jar()
cookie = quest.cookie 'your_cookie_here'
j.add cookie
quest {uri: 'www.google.com', jar: j}, (err, resp, body) ->
  # The request to Google was sent with the cookie that you specified
```

## Vs. request
Clever wrote quest after we had decided we'd spent too long diagnosing bugs in the third-party `request` module for node. It should be a drop-in replacement. What are the advantages of quest?

1. No global state

2. Cleaner codebase: 1/10th as many lines of code

3. Fewer bugs
