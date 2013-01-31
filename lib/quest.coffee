qs        = require 'qs'
http      = require 'http'
https     = require 'https'
_         = require 'underscore'
url       = require 'url'
cookiejar = require 'cookiejar'

handle =
  form: (options) ->
    return if not options.form?
    options.headers['content-type'] = 'application/x-www-form-urlencoded; charset=utf-8'
    options.body = qs.stringify(options.form).toString 'utf8'
  qs: (options) ->
    return if not options.qs?
    options.path = "#{options.path}?#{qs.stringify options.qs}"
  json: (options) ->
    return if not options.json?
    options.headers.accept = 'application/json'
    # Don't set the body if options.json is true: that just means that there will be a json response
    return if options.json is true
    options.headers['content-type'] = 'application/json'
    options.body = JSON.stringify options.json
  jar: (options) ->
    cookie_string = _(options.jar.getCookies options).map((c) -> c.toValueString()).join '; '
    options.headers.cookie = if not options.headers.cookie? then '' else "#{options.headers.cookie}; "
    options.headers.cookie = "#{options.headers.cookie}#{cookie_string}"
handle_options = (options) -> _(handle).chain().values().map (handler) -> handler options

is_uri = (uri) -> /^https?:\/\//.test uri
normalize_uri = (options) -> options.uri = "http://#{options.uri}" if not is_uri options.uri

should_redirect = (options, resp) ->
  299 < resp.statusCode < 400 and (options.followAllRedirects or (options.followRedirects and
  options.method not in ['PUT', 'POST', 'DELETE']))

quest = (options, cb) ->
  options = if typeof options is "string" then uri: options else options

  options.uri = options.url if options.url? and not options.uri?
  return cb 'Options does not include uri' if not options?.uri?
  return cb "Uri #{JSON.stringify options.uri} is not a string" if not _(options.uri).isString()
  options = _.clone options

  normalize_uri options
  https_pattern = /^https:/
  request_module = if https_pattern.test options.uri then https else http

  _(options).defaults
    port: if request_module is http then 80 else 443
    headers: {}
    method: 'get'
    followRedirects: true
    followAllRedirects: false
    maxRedirects: 10
    jar: new cookiejar.CookieJar
    ended: state: false

  parsed_uri = null
  try parsed_uri = url.parse options.uri # Suppress exceptions from url.parse
  return cb "Failed to parse uri #{options.uri}" if not parsed_uri? # This should never occur
  _(options).extend parsed_uri
  _(options.headers).defaults
    'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_3) AppleWebKit/537.16 (KHTML, like Gecko) Chrome/24.0.1297.0 Safari/537.16'
  handle_options options
  if options.body?
    options.body = new Buffer options.body
    options.headers['content-length'] = options.body.length
  options.method = options.method.toUpperCase()

  req = request_module.request options, (resp) ->
    resp.request = _({}).chain().extend(req).extend(options).value()

    cookies = resp?.headers?['set-cookie']
    if options.jar isnt false and cookies?
      options.jar.setCookies if _(cookies).isArray() then cookies else [cookies]
    if should_redirect options, resp
      return req.emit 'error', 'Exceeded max redirects' if options.maxRedirects is 0
      redirect_options =
        json: if options.json? then true # Don't send json bodies, but do parse json
        method: if options.followAllRedirects then 'GET' else options.method
        uri: resp.headers.location
        maxRedirects: options.maxRedirects-1
        jar: options.jar
        ended: options.ended
      redirect_options.uri = url.resolve options.href, redirect_options.uri if not is_uri redirect_options.uri
      return quest redirect_options, cb

    body = ''
    resp.setEncoding 'utf-8'
    resp.on 'data', (part) -> body += part if part?
    resp.on 'end', (part) ->
      body += part if part?
      try body = JSON.parse body if options.json
      req.emit 'end', null, resp, body
    req.on 'end', (err, resp, body) ->
      if not options.ended.state
        options.ended.state = true
        return cb err, resp, body
  setTimeout (() ->
    req.abort()
    e = new Error "ETIMEDOUT"
    e.code = "ETIMEDOUT"
    req.emit "error", e
  ), options.timeout if options.timeout
  req.on 'error', (err) ->
    if not options.ended.state
      options.ended.state = true
      return cb err
  req.write options.body if options.body?
  req.end()

# Make our jar support the same interface as request's
quest.jar = () ->
  jar = cookiejar.CookieJar()
  jar.add = jar.setCookie
  jar.get = (uri) -> jar.getCookies url.parse uri
  jar
quest.cookie = cookiejar.Cookie
module.exports = quest