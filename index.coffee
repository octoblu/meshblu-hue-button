'use strict';
util           = require 'util'
{EventEmitter} = require 'events'
_              = require 'lodash'
HueUtil        = require 'hue-util'
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
      default: 5000

class Plugin extends EventEmitter
  constructor: ->
    debug 'starting plugin'
    @options = {}
    @messageSchema = MESSAGE_SCHEMA
    @optionsSchema = OPTIONS_SCHEMA

  onMessage: (message) =>
    debug 'on message', message

  onConfig: (device={}) =>
    debug 'on config', apikey: device.apikey
    @apikey = device.apikey || {}
    @setOptions device.options

  setOptions: (options={}) =>
    debug 'setOptions', options
    defaults = apiUsername: 'octoblu', sensorPollInterval: 5000
    @options = _.extend defaults, options

    if @options.apiUsername != @apikey?.devicetype
      @apikey =
        devicetype: @options.apiUsername
        username: null

    @hue = new HueUtil @options.apiUsername, @options.ipAddress, @apikey?.username, @onUsernameChange

    clearInterval @pollInterval
    @pollInterval = setInterval @checkSensors, @options.sensorPollInterval

  onUsernameChange: (username) =>
    debug 'onUsernameChange', username
    @apikey.username = username
    @emit 'update', apikey: @apikey

  checkSensors: =>
    debug 'checking sensors'
    @hue.checkButtons @options.sensorName, (error, response) =>
      return console.error error if error?
      return if _.isEqual @lastState, response.state
      @lastState = response.state
      @emit 'message', devices: ['*'], topic: 'click', payload: button: response.button

module.exports =
  messageSchema: MESSAGE_SCHEMA
  optionsSchema: OPTIONS_SCHEMA
  Plugin: Plugin
