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
    cookies = options.jar.getCookies options
    cookie_string = _(cookies).map (c) -> c.toValueString()
    cookie_string = cookie_string.join '; '
    options.headers.cookie = if not options.headers.cookie? then '' else "#{options.headeers.cookie}; "
    options.headers.cookie = "#{options.headers.cookie}#{cookie_string}"

is_uri = (uri) -> /^https?:\/\//.test uri
normalize_uri = (options) -> options.uri = "http://#{options.uri}" if not is_uri options.uri

handle_options = (options) -> _(_(handle).values()).map (handler) -> handler options

should_redirect = (options, resp) ->
  299 < resp.statusCode < 400 and (options.followAllRedirects or (options.followRedirects and
  options.method isnt 'PUT' and options.method isnt 'POST' and options.method isnt 'DELETE'))

quest = (options, cb) ->
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

  parsed_uri = null
  try parsed_uri = url.parse options.uri # Suppress exceptions from url.parse
  return cb "Failed to parse uri #{options.uri}" if not parsed_uri? # This should never occur
  _(options).defaults parsed_uri
  _(options.headers).defaults
    'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_3) AppleWebKit/537.16 (KHTML, like Gecko) Chrome/24.0.1297.0 Safari/537.16'

  handle_options options

  if options.body?
    options.body = new Buffer options.body
    options.headers['content-length'] = options.body.length

  options.method = options.method.toUpperCase()
  req = request_module.request options, (resp) ->
    the_request_info = {}
    _(the_request_info).extend req
    _(the_request_info).extend options
    resp.request = the_request_info

    cookies = resp?.headers?['set-cookie']
    if options.jar isnt false and cookies?
      options.jar.setCookies if _(cookies).isArray() then cookies else [cookies]

    if should_redirect options, resp
      return req.emit 'error', 'Exceeded max redirects' if options.maxRedirects is 0
      redirect_options = {}
      _(redirect_options).defaults
        json: options.json? and options.json # Don't send json bodies, but do parse json
        method = if options.followAllRedirects then 'GET' else options.method
        uri: resp.headers.location
        maxRedirects: options.maxRedirects-1
        jar: options.jar
      redirect_options.uri = url.resolve options.href, redirect_options.uri if not is_uri redirect_options.uri
      return quest redirect_options, cb

    resp.setEncoding 'utf-8'
    body = ''

    resp.on 'data', (part) -> body += part if part?
    resp.on 'end', (part) ->
      body += part if part?
      try
        body = JSON.parse body if options.json
      catch err
        return req.emit 'error', "Error parsing body as json: #{body}"
      req.emit 'end', null, resp, body
  req.on 'error', cb
  req.on 'end', cb
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