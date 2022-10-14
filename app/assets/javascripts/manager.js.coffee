$ ->
  $(document).on 'keydown', '#search-input-box', (e) ->
    charCode = e.keyCode || e.which
    if charCode == 13
      e.preventDefault()
      e.stopPropagation()
      $('#search-form-container form').submit()

  $(document).on 'keyup', '#search-input-box', $.debounce 200, ->
    $('#search-form-container form').submit()
