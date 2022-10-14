$ ->
  myCustomConfirmBox = (message, callback) ->
    bootbox.confirm message, (confirmed) ->
      callback() if confirmed
      return
    return

  $.rails.allowAction = (element) ->
    message = element.data("confirm")
    answer = false
    callback = undefined
    return true  unless message
    if $.rails.fire(element, "confirm")
      myCustomConfirmBox message, ->
        callback = $.rails.fire(element, "confirm:complete", [answer])
        if callback
          oldAllowAction = $.rails.allowAction
          $.rails.allowAction = ->
            true
          element.trigger "click"
          $.rails.allowAction = oldAllowAction
        return
    false
  return
