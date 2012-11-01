# Quest - massively simplified, super lightweight HTTP request method

## Install

<pre>
  npm install quest
</pre>

## Super simple to use

Quest is designed to be the simplest way possible to make http calls. It supports HTTPS and follows redirects by default.

```coffeescript
quest = require 'quest'
quest 'www.google.com', (err, response, body) ->
  console.log body if not err? and response.statusCode is 200
```

## Supported options
* `uri` - fully qualified uri (e.g. http://google.com). If protocol is left off, assumes http://
* `qs` - object containing querystring values to be appended to the uri
* `method` - http method, defaults to GET
* `headers` - http headers, defaults to {}
* `body` - entity body for POST and PUT requests. must be string
* `form` - object containing form values to send in the body. also adds `content-type: application/x-www-form-urlencoded; charset=utf-8` to the header
* `json` - if true, parses response as JSON. if object, additionally sends JSON representation of the object and adds `content-type: application/json` to the header
* `followRedirect` - follow HTTP 3xx responses as redirects. defaults to true
* `followAllRedirects` - follow non-GET HTTP 3xx responses as redirects. defaults to false
* `maxRedirects` - the maximum number of redirects to follow. defaults to 10
* `jar` - set to `false` if you don't want cookies to be remembered for future use. optionally pass in your own custom cookie jar (see Cookies below)

## Cookies
Cookies are enabled by default (so they can be used in subsequent requests). To disable cookies set jar to false.

If you want to use a custom cookie jar (instead of letting quest use its own default cookie jar) you do so by specifying a jar as an option:

``coffeescript
j = quest.jar()
quest {uri: 'www.google.com', jar: j}, () ->
 quest {uri: 'images.google.com', jar: j}, () ->
   # The request to Google images was sent with any cookies that the original request to Google set
```

You can also set your own cookies when you specify a jar:

```coffeescript
j = quest.jar()
cookie = request.cookie 'your_cookie_here'
j.add cookie
quest {uri: 'www.google.com', jar: j}, (err, resp, body) ->
  # The request to Google was sent with the cookie that you specified
```