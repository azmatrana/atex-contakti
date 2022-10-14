$ ->
  deleteTemplate = (form_prefix) ->
    templateId = $("##{form_prefix}_id").val()
    templateKind = $("##{form_prefix}_kind").val()
    if form_prefix == 'chat_autoreply_text #manager_template'
      prefix = 'chat_media_channel'
    else
      prefix = 'call_media_channel'
    $.ajax
      url: "/#{I18n.locale}/sms_templates"
      method: 'delete'
      data:
        id: templateId
        service_channel_id: $("##{form_prefix}_service_channel_id").val()
        prefix: prefix
        kind: templateKind
      success: ->
        removeTemplateFromList templateId, if templateKind == 'agent' then gon.smsTemplates else gon.managerTemplates
    false

  removeTemplateFromList = (templateId, templatesList) ->
    for value, index in templatesList
      if value.id.toString() == templateId
        templatesList.splice(index, 1)
        break

  updateManagerTemplate = (templateTitle, saveAsNew) ->
    $.post "/#{I18n.locale}/sms_templates", {
      sms_template:
        kind: 'manager'
        save_as_new: saveAsNew
        prefix: 'call_media_channel'
        text: $('#autoreply_text textarea.sms-message-input').val()
        title: templateTitle
        service_channel_id: $('#manager_template_service_channel_id').val()
        id: $('#autoreply_text #manager_template_id').val()
      }

  updateSmsManagerTemplate = (templateTitle, saveAsNew) ->
    $.post "/#{I18n.locale}/sms_templates", {
      sms_template:
        kind: 'manager'
        save_as_new: saveAsNew
        prefix: 'chat_media_channel'
        text: $('#chat_autoreply_text textarea.sms-message-input').val()
        title: templateTitle
        service_channel_id: $('#manager_template_service_channel_id').val()
        id: $('#chat_autoreply_text #manager_template_id').val()
      }

  $('#disabled_sms_template_link').tooltip { title: I18n.t('service_channels.please_save_first') }

  $(document).on 'keyup', '#autoreply_text .sms-message-input, #sms_template_form .sms-message-input, #sms_multi_sending_form .sms-message-input, #sms_individual_sending_form .sms-message-input', ->
    window.SMSHelper.countRemainingChars $(this)

  $(document).on 'keyup', '#chat_autoreply_text .sms-message-input', ->
    window.SMSHelper.countRemainingChars $(this)

  $(document).on 'click', '#sms_template_form a.save-as-new-template', ->
    templateTitle = $('#sms_template_title').val()
    existingTemplate = gon.smsTemplates.filter((x) -> x.title == templateTitle)[0]
    if existingTemplate
      bootbox.confirm I18n.t('service_channels.proceed_overwriting_template', name: templateTitle), (result) ->
        if result
          $('#sms_template_form').submit()
          existingTemplate.title = templateTitle
          existingTemplate.text = $('#sms_template_text').val()
    else
      $('#sms_template_save_as_new').val(true)
      $('#sms_template_form').submit()

  $(document).on 'change', '.sms_template_id', ->
    selectedId = $(this).val()
    template = gon.smsTemplates.filter((t) -> t.id.toString() == selectedId)[0]
    if template
      $('.sms-message-input:visible').val template.text
      $('#sms_template_title').val template.title
      $('#sms_template_visibility').val template.visibility
      $('#sms_template_visibility').trigger 'change'
      $('#sms_template_location_id').val template.location_id
      $(this).closest('form').find('a.save-as-new-template').attr 'disabled', true
    window.SMSHelper.countRemainingChars $('.sms-message-input:visible')

  $(document).on 'click', '.sms-tab', ->
    $('.sms-message-counter').addClass 'hide'
    messageInput = $($(this).attr("href")).find('.sms-message-input')
    window.SMSHelper.countRemainingChars messageInput

  $(document).on 'change', '#sms_template_visibility', ->
    selectedVisibility = $(this).val()
    locationDiv = $('#sms_template_location_id').parent('div')
    if selectedVisibility == 'location'
      locationDiv.removeClass 'hide'
    else
      locationDiv.addClass 'hide'

  $(document).on 'click', '#sms_template_form .delete-template', ->
    deleteTemplate 'sms_template'

  $(document).on 'keyup', '#sms_template_text, #sms_template_title', ->
    $(this).closest('form').find('a.save-as-new-template').attr 'disabled', false

  $(document).on 'keyup', '#autoreply_text textarea.sms-message-input, #autoreply_text #manager_template_title', ->
    $('#autoreply_text a.save-as-new-template').attr 'disabled', false

  $(document).on 'keyup', '#chat_autoreply_text textarea.sms-message-input, #chat_autoreply_text #manager_template_title', ->
    $('#chat_autoreply_text a.save-as-new-template').attr 'disabled', false

  # manager SMS template form events
  $(document).on 'click', '#autoreply_text a.save-as-new-template', ->
    templateTitle = $('#autoreply_text #manager_template_title').val()
    existingTemplate = gon.managerTemplates.filter((x) -> x.title == templateTitle)[0]
    saveAsNew = true
    sendRequest = true
    if existingTemplate
      bootbox.confirm I18n.t('service_channels.proceed_overwriting_template', name: templateTitle), (result) ->
        updateManagerTemplate(templateTitle, false) if result
    else
      updateManagerTemplate(templateTitle, true)

  $(document).on 'click', '#chat_autoreply_text a.save-as-new-template', ->
    templateTitle = $('#chat_autoreply_text #manager_template_title').val()
    existingTemplate = gon.managerTemplates.filter((x) -> x.title == templateTitle)[0]
    saveAsNew = true
    sendRequest = true
    if existingTemplate
      bootbox.confirm I18n.t('service_channels.proceed_overwriting_template', name: templateTitle), (result) ->
        updateSmsManagerTemplate(templateTitle, false) if result
    else
      updateSmsManagerTemplate(templateTitle, true)

  $(document).on 'change', '#autoreply_text #manager_template_id', ->
    selectedId = $(this).val()
    template = gon.managerTemplates.filter((t) -> t.id.toString() == selectedId)[0]
    if template
      $('#autoreply_text .sms-message-input').val template.text
      $('#autoreply_text manager_template_title').val template.title
      $('#autoreply_text a.save-as-new-template').attr 'disabled', true

  $(document).on 'change', '#chat_autoreply_text #manager_template_id', ->
    selectedId = $(this).val()
    template = gon.managerTemplates.filter((t) -> t.id.toString() == selectedId)[0]
    if template
      $('#chat_autoreply_text .sms-message-input').val template.text
      $('#chat_autoreply_text #manager_template_title').val template.title
      $('#chat_autoreply_text a.save-as-new-template').attr 'disabled', true

  $(document).on 'click', '#autoreply_text .delete-template', ->
    deleteTemplate 'manager_template'

  $(document).on 'click', '#chat_autoreply_text .delete-template', ->
    deleteTemplate 'chat_autoreply_text #manager_template'
