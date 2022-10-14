window.applyDateRangePicker = ->
  customRanges = { }
  customRanges[I18n.t('daterangepicker.ranges.today')]                   = [moment().startOf('day'), moment().endOf('day')]
  customRanges[I18n.t('daterangepicker.ranges.yesterday')]               = [moment().startOf('day').subtract(1, 'days'), moment().endOf('day').subtract(1, 'days')]
  customRanges[I18n.t('daterangepicker.ranges.last_x_days', {days: 7})]  = [moment().startOf('day').subtract(6, 'days'), moment().endOf('day')]
  customRanges[I18n.t('daterangepicker.ranges.last_x_days', {days: 30})] = [moment().startOf('day').subtract(29, 'days'), moment().endOf('day')]
  customRanges[I18n.t('daterangepicker.ranges.this_month')]              = [moment().startOf('month'), moment().endOf('month')]
  customRanges[I18n.t('daterangepicker.ranges.last_month')]              = [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]

  $('input.date-range').daterangepicker(
    opens: 'left'
    format: 'DD/MM/YYYY'
    ranges: customRanges
    locale:
      cancelLabel:      I18n.t('daterangepicker.cancel')
      applyLabel:       I18n.t('daterangepicker.apply')
      fromLabel:        I18n.t('daterangepicker.from')
      toLabel:          I18n.t('daterangepicker.to')
      customRangeLabel: I18n.t('daterangepicker.custom_range')
      daysOfWeek:       I18n.t('daterangepicker.days_of_week')
      monthNames:       I18n.t('daterangepicker.month_names')
      firstDay:         if I18n.locale == 'en' then 7 else 1
  )

  $('#task-filter-date-range').daterangepicker(
    opens: 'right'
    sidebar: true
    format: 'DD/MM/YYYY'
    ranges: customRanges
    locale:
      cancelLabel:      I18n.t('daterangepicker.cancel')
      applyLabel:       I18n.t('daterangepicker.apply')
      fromLabel:        I18n.t('daterangepicker.from')
      toLabel:          I18n.t('daterangepicker.to')
      customRangeLabel: I18n.t('daterangepicker.custom_range')
      daysOfWeek:       I18n.t('daterangepicker.days_of_week')
      monthNames:       I18n.t('daterangepicker.month_names')
      firstDay:         if I18n.locale == 'en' then 7 else 1
  )

  $('input.date-range, #task-filter-date-range, #task-filter-date-range-container').on 'apply.daterangepicker', (ev, picker) ->
    startDate = picker.startDate.clone()
    if startDate.add('days', 1) > picker.endDate # moment add/substract operation changes the object
      $(this).val picker.startDate.format('DD/MM/YYYY')
    if window.refreshDashboard
      window.refreshDashboard()

  $('input.date-range, #task-filter-date-range, #task-filter-date-range-container').on 'cancel.daterangepicker', (ev, picker) ->
    picker.setStartDate(moment().startOf('day'))
    picker.setEndDate(moment().endOf('day'))
    startDate = picker.startDate.clone()
    if startDate.add('days', 1) > picker.endDate # moment add/substract operation changes the object
      $(this).val picker.startDate.format('DD/MM/YYYY')
    if window.refreshDashboard
      window.refreshDashboard()


$ ->
  window.applyDateRangePicker()
