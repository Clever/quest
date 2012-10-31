qs    = require 'qs'
http  = require 'http'
https = require 'https'
_     = require 'underscore'
url   = require 'url'

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

normalize_uri = (options) ->
  uri_pattern = /^https?:\/\//
  options.uri = "http://#{options.uri}" if not uri_pattern.test options.uri

handle_options = (options) -> _(_(handle).values()).map (handler) -> handler options

module.exports = (options, cb) ->
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
    resp.setEncoding 'utf-8'
    resp.on 'data', (body) ->
      body = JSON.parse body if options.json
      cb null, resp, body
  req.on 'error', (err) -> cb err

  req.write options.body if options.body?
  req.end()