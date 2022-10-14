$ ->
  showAlertMessage = (messageBox, success, message) ->
    messageBox.find('span.message-text').html(message)
    messageBox.removeClass('alert-danger alert-success')
    messageBox.addClass(if success then 'alert-success' else 'alert-danger')
    messageBox.removeClass 'hide'
    messageBox.css 'display', 'block'

  $('input#service_channel_name').focus()

  $(document).on 'click', '.switch-send-autoreply', ->
    $('#autoreply_text').toggleClass 'hide'

  $(document).on 'click', 'table.service-channel', ->
    window.location = "/#{I18n.locale}/service_channels/#{$(this).data('id')}"
    false

  $('.save-settings-btn').on 'click', ->
    $('#service_channel_form').submit()

  $(document).on 'click', '.clear-form-btn', (e)->
    form = $(e.currentTarget).parents('div.modal-content').find('div.tab-pane.active')
    form = $(e.currentTarget).closest('form, .form') if form.length == 0
    form.find('input').not('[type=hidden]').val('')

  $('.test-settings.imap').on 'click', ->
    imap_form = $(this).closest('form, .form')
    button = $(this)
    alertMessage = imap_form.find('div.alert')
    button.attr('disabled', true)
    $.ajax
      method: 'post',
      url: '/service_channels/test_imap_settings',
      timeout: 30 * 1000 # 30 seconds
      data: {
        server_name: imap_form.find('.server-name').val(),
        port: imap_form.find('.port').val(),
        use_ssl: if (imap_form.find('.use-ssl').parent().find('i').hasClass('checked')) then 1 else 0,
        user_name: imap_form.find('.user-name').val(),
        password: imap_form.find('.password').val()
      }
      success: (response) ->
        showAlertMessage(alertMessage, response.ok, response.message)
        button.removeAttr('disabled')
      error: (response, status) ->
        if status == 'timeout'
          showAlertMessage(alertMessage, false, 'Connection timeout. Possibly due to the wrong port') # TODO: localization
        button.removeAttr('disabled')
    false

  $('.test-settings.smtp').on 'click', ->
    smtp_form = $(this).closest('form, .form')
    button = $(this)
    alertMessage = smtp_form.find('div.alert')
    button.attr('disabled', true)
    $.ajax
      method: 'post',
      url: '/service_channels/test_smtp_settings'
      data: {
        server_name: smtp_form.find('.server-name').val(),
        port: smtp_form.find('.port').val(),
        use_ssl: if (smtp_form.find('.use-ssl').parent().find('i').hasClass('checked')) then 1 else 0,
        user_name: smtp_form.find('.user-name').val(),
        password: smtp_form.find('.password').val()
      }
      success: (response) ->
        showAlertMessage(alertMessage, response.ok, response.message)
        button.removeAttr('disabled')
    false

  $('#add_service_channel_btn').on 'click', ->
    window.location = "/#{I18n.locale}/service_channels"

  $('#sms_multi_sending_submit_button').on 'click', ->
    $form = $('#sms_multi_sending_form')
    formData = new FormData($form[0])
    $.ajax
      method: 'post',
      url: '/sms'
      data: formData
      contentType: false
      cache: false
      processData: false
      success: (response) ->
        $('#attach_csv').val('')
        alert('ok')
        $('#sms_templates_editor').modal 'hide'
      error: (response) ->
        error = $.parseJSON(response.responseText).errors
        userDashboardService.showStatusMessageInModal error, true
      complete: (response) ->


  $('#sms_individual_sending_submit_button').on 'click', ->
    $form = $('#sms_individual_sending_form')
    formData = new FormData($form[0])
    $.ajax
      method: 'post',
      url: '/sms_individual'
      data: formData
      contentType: false
      cache: false
      processData: false
      success: (response) ->
        alert('ok')
        $('#sms_templates_editor').modal 'hide'
      error: (response) ->
        error = $.parseJSON(response.responseText).errors
        userDashboardService.showStatusMessageInModal error, true
      complete: (response) ->

  $('#sms_templates_editor').on 'hide.bs.modal', ->
    $('#attach_csv').val('')


  $(window).load ->
    $('.single_sms_channel').on 'change', ->
      if $(this).find('option:selected').val() == null or $(this).find('option:selected').val() == 'undefined' or $(this).find('option:selected').val() == ''
        $('#sms_individual_sending_submit_button').attr 'disabled', true
      else
        $('#sms_individual_sending_submit_button').attr 'disabled', false
      return

    $('.group_sms_channel').on 'change', ->
      if $(this).find('option:selected').val() == null or $(this).find('option:selected').val() == 'undefined' or $(this).find('option:selected').val() == ''
        $('#sms_multi_sending_submit_button').attr 'disabled', true
      else
        $('#sms_multi_sending_submit_button').attr 'disabled', false
      return
    return
    
