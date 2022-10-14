$ ->
  $('ul.locale-switcher li').on 'click', () ->
    locale = $(this).attr('value')
    return unless locale
    currentPath = window.location.pathname
    localeRegexp = new RegExp "^/(en|fi|sv)/?"
    return false if new RegExp("^\/#{locale}\/").test(currentPath)
    if localeRegexp.test(currentPath)
      window.location.pathname = currentPath.replace localeRegexp, "/#{locale}/"
    else
      return false if locale == 'en'
      window.location.pathname = "/#{locale}#{currentPath}"
    false

