qs        = require 'qs'
http      = require 'http'
https     = require 'https'
_         = require 'underscore'
url       = require 'url'
cookiejar = require 'cookiejar'

handle =
  form: (options) ->
    return unless options.form?
    if 'content-type' not of options.headers
      options.headers['content-type'] = 'application/x-www-form-urlencoded; charset=utf-8'
    options.body = qs.stringify(options.form).toString 'utf8'
  qs: (options) ->
    return unless options.qs?
    options.path = "#{options.path}?#{qs.stringify options.qs}"
  json: (options) ->
    return unless options.json?
    options.headers.accept = 'application/json' if 'accept' not of options.headers
    # Don't set the body if options.json is true: that just means that there will be a json response
    return if options.json is true
    options.headers['content-type'] = 'application/json' if 'content-type' not of options.headers
    options.body = JSON.stringify options.json
  jar: (options) ->
    cookie_string = _(options.jar.getCookies options).invoke('toValueString').join '; '
    options.headers.cookie = if not options.headers.cookie? then '' else "#{options.headers.cookie}; "
    options.headers.cookie = "#{options.headers.cookie}#{cookie_string}"
handle_options = (options) -> _(handle).chain().values().each (handler) -> handler options

is_uri = (uri) -> /^https?:\/\//i.test uri
normalize_uri = (options) -> options.uri = "http://#{options.uri}" unless is_uri options.uri

should_redirect = (options, resp) ->
  299 < resp.statusCode < 400 and (options.followAllRedirects or (options.followRedirects and
  options.method not in ['PUT', 'POST', 'DELETE']))

quest = (options, cb) ->
  options = uri: options if _(options).isString()
  options.uri ?= options.url

  return cb new Error 'Options does not include uri' unless options?.uri?
  return cb new Error "Uri #{JSON.stringify options.uri} is not a string" unless _(options.uri).isString()
  options = _.clone options

  normalize_uri options
  https_pattern = /^https:/i
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

  # Normalize headers
  for key, val of options.headers when key isnt key.toLowerCase()
    options.headers[key.toLowerCase()] = val
    delete options.headers[key]

  parsed_uri = null
  try parsed_uri = url.parse options.uri # Suppress exceptions from url.parse
  return cb new Error "Failed to parse uri #{options.uri}" unless parsed_uri? # This should never occur
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
      return req.emit 'error', new Error 'Exceeded max redirects' if options.maxRedirects is 0
      redirect_options =
        json: if options.json? then true # Don't send json bodies, but do parse json
        method: if options.followAllRedirects then 'GET' else options.method
        uri: resp.headers.location
        maxRedirects: options.maxRedirects-1
        jar: options.jar
        ended: options.ended
      redirect_options.uri = url.resolve options.href, redirect_options.uri unless is_uri redirect_options.uri
      resp.resume()
      return quest redirect_options, cb

    body = undefined
    resp.setEncoding 'utf-8'
    add_data = (part) ->
      return unless part?
      body ?= ''
      body += part
    resp.on 'data', add_data
    resp.on 'end', (part) ->
      add_data part
      try body = JSON.parse body if options.json
      return if options.ended.state
      options.ended.state = true
      return cb null, resp, body
  if options.timeout
    setTimeout (() ->
      req.abort()
      e = new Error "ETIMEDOUT"
      e.code = "ETIMEDOUT"
      req.emit "error", e
    ), options.timeout
  req.on 'error', (err) ->
    return if options.ended.state
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
