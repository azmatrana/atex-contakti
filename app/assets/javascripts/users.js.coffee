$ ->
  $('#add_user_btn').on 'click', ->
    window.location = "/#{I18n.locale}/agents/new"
  $('button.reset-password-btn').on 'click', ->
    $.ajax
      url: '/password',
      method: 'post',
      data: {
        user: { email: $('#reset_password_form input').val() }
      },
      success: (jqXHR, status) ->
        # TODO: success message instead of page reload
        window.location.reload()

  $(document).on 'click', 'table.agent-item', ->
    window.location = "/#{I18n.locale}/agents/#{$(this).data('id')}"
    false

  $('#online_switch').on 'change', ->
    unless $(@).data('no-trigger')
      $.ajax
        url: '/users/change_online_status',
        method: 'put',
        data: { online: this.checked }

  $('#details_cancel_btn').on 'click', (e) ->
    window.location.href = $(e.currentTarget).data('url')

  $('a.user-activity').on 'click', ->
    $.get "/#{I18n.locale}/agents/#{$(this).data('id')}/render_activity_report", {}

  $('#user_activity_report input.date-range').on 'apply.daterangepicker', (ev, picker) ->
    $.get "/agents/#{$(this).data('id')}/render_activity_report", {
      starts_at: picker.startDate.format('LL'),
      ends_at: picker.endDate.format('LL')
    }
