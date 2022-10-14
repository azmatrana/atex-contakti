$ ->
  timeout = null

  hideSidebar = ->
    $('.reports-index-container #search-form-container').css('width', '0px')
    $('.reports-index-container #search-form-container').css('padding', '0')
    $('.reports-index-container #search-form-container').css('overflow', 'hidden')
    $('.reports-index-container .agent-admin.preview-content').removeClass('col-md-9')
    $('.reports-index-container .agent-admin.preview-content').addClass('col-md-12')
    $('#dashboard-gridster').resize();

  showSidebar = ->
    $('.reports-index-container #search-form-container').css('width', '25%')
    $('.reports-index-container #search-form-container').css('padding', '0 12px')
    $('.reports-index-container .agent-admin.preview-content').removeClass('col-md-12')
    $('.reports-index-container .agent-admin.preview-content').addClass('col-md-9')
    $('#dashboard-gridster').resize();

  urlPrefix = "/#{I18n.locale}/reports/"

  $('input[name="report[date_range]"]').on 'apply.daterangepicker', (ev, picker) ->
    container = $(this).closest('div')
    container.find('input[name="report[starts_at]"]').val picker.startDate
    container.find('input[name="report[ends_at]"]').val picker.endDate

  $('input[name="report[start_sending_at_time_picker]"]').on 'apply.daterangepicker', (ev, picker) ->
    container = $(this).closest('div')
    container.find('input[name="report[start_sending_at]"]').val picker.startDate

  $(document).on 'click', '.view-report', ->
    window.location = "#{urlPrefix}#{$(this).data('id')}/show"

  $(document).on 'click', 'button.new-report', () ->
    $('.hideable').hide()
    self = $(this)
    if self.hasClass('selected')
      self.removeClass('selected')
      $(self.data('noselection-element')).show()
    else
      $('.selected').removeClass('selected')
      self.addClass('selected')
      $($(this).data('show-element')).show()

  $(document).on 'click', 'button.cancel', ()->
    $('.hideable').hide()
    $('button.new-report').removeClass('selected')

  $(document).on 'click', 'table.report-item',  ->
    $('.hideable').hide()
    self = $(this)
    noselectionElement = $(self.data('noselection-element'))
    loaderElement = $(self.data('loader-element'))
    container = $(self.data('show-element'))

    if self.hasClass('selected')
      self.removeClass('selected')
      noselectionElement.show()
    else
      $('.selected').removeClass('selected')
      self.addClass('selected')
      loaderElement.show()
      $.get "#{urlPrefix}#{$(this).data('id')}/preview", (data) =>
        loaderElement.hide()
        container.show()
        container.html(data)
        $('body').removeClass('menu-left-visible').addClass('menu-hidden')


  # FIXME
  $(document).on 'click', 'button.edit-btn',  ->
    window.location = "#{urlPrefix}#{$(this).data('id')}/edit"

  $(document).on 'click', 'button.print-btn', ->
    messageUrl = "#{urlPrefix}#{$(this).data('id')}/print"
    printTab = window.open(messageUrl, '_blank')
    printTab.focus()

  $(document).on 'click', 'button.send-report-btn', ->
    $(this).prop 'disabled', true
    $.ajax
      url: "#{urlPrefix}/#{$(this).data('id')}/send"
      method: 'post'
      data:
        send_to_emails: $('#report_send_to_emails').val()
      complete: =>
        setTimeout (() => $(this).prop 'disabled', false), 2000


  $(document).on 'click', 'button.report-form.comparison', ->
    $('#comparison_report_form').submit()

  $(document).on 'click', 'button.report-form.summary', ->
    $('#summary_report_form').submit()

  $('span.tooltip-wrapper').tooltip {
    title: I18n.t('reports.generic.please_save_first')
  }

  # show pre-selected checkboxes
  $('.select-service-channel, .select-media-channel, .select-agent').find('input:checked').each ->
    $(this).closest('div.checkbox').removeClass 'hide'

  showCheckbox = (el, wrapper) ->
    wrapper.removeClass 'hide'
    el.checkbox('check')
    el.trigger('change')

  hideCheckbox = (el, wrapper) ->
    wrapper.addClass 'hide'
    el.checkbox('uncheck')
    el.trigger('change')

  # TODO: heavily optimize later, this approach is very inefficient
  reprocessCheckboxes = (checkbox) ->
    checkbox.closest('div.widget-body').find('input:checked').each -> $(this).trigger 'change'

  showSelectAll = (containerClass) ->
    container = $(".#{containerClass}")
    checkedElementsCount = container.find('input:checked').length
    allCheckboxesCount = container.find('input:checkbox').filter(':visible').length
    selectAll = container.closest('div.checkbox-set').find('input[data-all-checkboxes]')
    if allCheckboxesCount > 0
      selectAll.next('i').removeClass 'hide'
      isChecked = selectAll.is(':checked')
      if isChecked and checkedElementsCount < allCheckboxesCount
        selectAll.checkbox('uncheck')
      if !isChecked and checkedElementsCount == allCheckboxesCount
        selectAll.checkbox('check')
    else
      selectAll.next('i').addClass 'hide'

  $('.select-location input:checkbox').on 'change', ->
    checkbox = $(this)
    $('.select-service-channel input:checkbox').each ->
      el = $(this)
      locations = el.data('locations').toString().split(',')
      if locations.indexOf(checkbox.val()) isnt -1
        wrapper = el.closest('div.checkbox')
        if checkbox.is(':checked')
          showCheckbox el, wrapper
        else
          hideCheckbox el, wrapper
    reprocessCheckboxes(checkbox) unless checkbox.is(':checked')

  $('.select-service-channel input:checkbox').on 'change', ->
    checkbox = $(this)
    mediaChannels = checkbox.data('media-channels').split(',')
    $('.select-media-channel input:checkbox').each ->
      el = $(this)
      if mediaChannels.indexOf(el.val()) isnt -1
        wrapper = el.closest('div.checkbox')
        if checkbox.is(':checked')
          showCheckbox el, wrapper
        else
          hideCheckbox el, wrapper
    showSelectAll 'select-service-channel'
    reprocessCheckboxes(checkbox) unless checkbox.is(':checked')

  $('.select-media-channel input:checkbox').on 'change', ->
    checkbox = $(this)
    $('.select-agent input:checkbox').each ->
      el = $(this)
      mediaChannels = el.data('media-channels').toString().split(',')
      if mediaChannels.indexOf(checkbox.val()) isnt -1
        el.prop 'checked', checkbox.is(':checked')
        wrapper = el.closest('div.checkbox')
        if checkbox.is(':checked')
          showCheckbox el, wrapper
        else
          hideCheckbox el, wrapper
    showSelectAll 'select-media-channel'
    reprocessCheckboxes(checkbox) unless checkbox.is(':checked')

  $('.select-agent input:checkbox').on 'change', ->
    showSelectAll 'select-agent'

  tt = $('.scheduler-start-date-picker .time-picker')
  new Pikaday({
    field: tt[0],
    trigger: tt[0],
    position: 'bottom left',
    reposition: true,
    use24hour: true,
    minDate: new Date(),
    showButtonPanel: true,
    autoClose: false,
    format: 'DD/MM/YYYY HH:mm',
    i18n: PIKADAY_LOCALES[I18n.locale]
  });
