'use strict';
util           = require 'util'
url            = require 'url'
{EventEmitter} = require 'events'
request        = require 'request'
_              = require 'lodash'
debug          = require('debug')('meshblu-hue-button')

MESSAGE_SCHEMA =
  type: 'object'
  properties: {}

OPTIONS_SCHEMA =
  type: 'object'
  properties:
    ipAddress:
      type: 'string'
      required: true
    apiUsername:
      type: 'string'
      required: true
      default: 'newdeveloper'
    sensorName:
      type: 'string'
      required: true
      default: 'Hue Tap 1'
    sensorPollInterval:
      type: 'integer'
      required: true
      default: 1000

BUTTON_EVENTS =
  16: '2'
  17: '3'
  18: '4'
  34: '1'

class Plugin extends EventEmitter
  constructor: ->
    @options = {}
    @messageSchema = MESSAGE_SCHEMA
    @optionsSchema = OPTIONS_SCHEMA

  onMessage: (message) =>

  onConfig: (device) =>
    @setOptions device.options

  setOptions: (options={}) =>
    @options = _.defaults options, sensorPollInterval: 1000

    clearInterval @pollInterval
    @pollInterval = setInterval @checkSensors, @options.sensorPollInterval

  checkSensors: =>
    uri = url.format protocol: 'http', hostname: @options.ipAddress, pathname: "/api/#{@options.apiUsername}/sensors"

    request uri: uri, method: 'GET', json: true, (error, response, body) =>
      state = _.findWhere(_.values(body), name: @options.sensorName).state
      return if _.isEqual @lastState, state

      @lastState = state
      @emit 'message', devices: ['*'], topic: 'click', payload: {button: BUTTON_EVENTS[state.buttonevent]}

module.exports =
  messageSchema: MESSAGE_SCHEMA
  optionsSchema: OPTIONS_SCHEMA
  Plugin: Plugin
