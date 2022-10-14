$ ->
  window.InitEasyPieCharts = ->
    if $(".easy-pie").length and $.fn.easyPieChart
      $.each $(".easy-pie"), (k, v) ->
        color = primaryColor
        color = infoColor  if $(this).is(".info")
        color = dangerColor  if $(this).is(".danger")
        color = successColor  if $(this).is(".success")
        color = warningColor  if $(this).is(".warning")
        color = inverseColor  if $(this).is(".inverse")
        $(v).easyPieChart
          barColor: color
          animate: ((if $("html").is(".ie") then false else 3000))
          lineWidth: 4
          size: 50

  window.InitEasyPieCharts()
