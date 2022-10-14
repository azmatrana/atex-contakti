$ ->
  $('#add_location_btn').on 'click', ->
    window.location = "/#{I18n.locale}/locations/new"
  $(document).on 'click', 'table.location-item', ->
    window.location = "/#{I18n.locale}/locations/#{$(this).data('id')}"

  $('[data-all-checkboxes]').on 'click', (e) ->
    selector = $(e.currentTarget).data('all-checkboxes')
    enabled = $(e.currentTarget).is(':checked')
    $("##{selector} :checkbox").each (index, item) ->
      $item = $(item)
      $item.click() unless $item.is(':checked') == enabled
