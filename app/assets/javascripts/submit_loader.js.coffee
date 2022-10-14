
$ ->
  $("form .submit-loader").closest("form").submit (e) ->
    form = $(this)
    return false if form.data("submitted")

    btns = form.find("button.submit-loader")

    # Disable the button(s)
    btns.prop("disabled", true)

    # Add spinner
    spinner = $("<i></i>").addClass("fa fa-spinner fa-spin")
    btns.prepend(spinner)

    # Mark as submitted
    form.data("submitted", true)
    true
