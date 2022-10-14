#
# SmsTools from https://github.com/mitio/smstools
# Copyright (c) 2014 Dimitar Dimitrov
#
window.SmsTools = {}

class SmsTools.Message
  maxLengthForEncoding:
    gsm:
      normal: 160
      concatenated: 153
    unicode:
      normal: 70
      concatenated: 67

  doubleByteCharsInGsmEncoding:
    '^':  true
    '{':  true
    '}':  true
    '[':  true
    '~':  true
    ']':  true
    '|':  true
    '€':  true
    '\\': true

  gsmEncodingPattern: /^[0-9a-zA-Z@Δ¡¿£_!Φ"¥Γ#èΛ¤éΩ%ùΠ&ìΨòΣçΘΞ:Ø;ÄäøÆ,<Ööæ=ÑñÅß>ÜüåÉ§à€~ \$\.\-\+\(\)\*\\\/\?\|\^\}\{\[\]\'\r\n]*$/

  constructor: (@text) ->
    @text                   = @text.replace /\r\n?/g, "\n"
    @encoding               = @_encoding()
    @length                 = @_length()
    @concatenatedPartsCount = @_concatenatedPartsCount()

  maxLengthFor: (concatenatedPartsCount) ->
    messageType = if concatenatedPartsCount > 1 then 'concatenated' else 'normal'

    concatenatedPartsCount * @maxLengthForEncoding[@encoding][messageType]

  _encoding: ->
    if @gsmEncodingPattern.test(@text) then 'gsm' else 'unicode'

  _concatenatedPartsCount: ->
    encoding = @encoding
    length   = @length

    if length <= @maxLengthForEncoding[encoding].normal
      1
    else
      parseInt Math.ceil(length / @maxLengthForEncoding[encoding].concatenated), 10

  # Returns the number of symbols which the given text will eat up in an SMS
  # message, taking into account any double-space symbols in the GSM 03.38
  # encoding.
  _length: ->
    length = @text.length

    if @encoding == 'gsm'
      for char_entry in @text
        length += 1 if @doubleByteCharsInGsmEncoding[char_entry]

    length

#
# SMSHelper
#
window.SMSHelper =
  countRemainingChars: (obj) ->
    smsMessage = new SmsTools.Message(obj.val())
    num = smsMessage.concatenatedPartsCount
    message_length = smsMessage.length
    max = smsMessage.maxLengthFor(num)
    message = "#{message_length}/#{max}, #{num} "
    key = if Math.ceil(num) > 1 then 'messages' else 'message'
    message += I18n.t("user_dashboard.sms_#{key}")
    obj.parents('div').find('.sms-message-counter').html(message).removeClass 'hide'

