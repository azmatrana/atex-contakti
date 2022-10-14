modulejs.define('flotchartConfigurations', ['flotchartUtility', 'flotchartLimiter', 'flotchartOptions'], function (u, l, o) {
  var utility = u;
  var limiter = l;
  var options = o;

  //Holds options and initFunctions. All init functions must be one argument functions that take the ExtremiaFlotchart instance as argument
  var configurations = {
    'summaryReportHorizontal': {
      options: options['stackedChartTwoOptions'],
      initFunctions: [
        //Set styles
        utility.applyStyle,
        //Enables maximize button
        function (that) {
          limiter.enableMaximizeButton(that.$container.attr('id'), that.rawTicks, that.$container.data('maximized'));
        },
        //Limit the shown data
        function (that) {
          that.options.yaxis.ticks = limiter.limitTicks(that.rawTicks, that.options.yaxis.max);
        },
        //Limit the shown data
        function (that) {
          that.data = that.rawData;
          //that.data = limiter.limitData(that.rawData, 4);

          var sumVal = 0;
          for (var i in that.data) {

            if (that.data[i].data.length > 0) {

              for (var a in that.data[i].data) {
                if (that.data[i].data[a].length > 0) {
                  sumVal += that.data[i].data[a][0];
                }
              }
            }
          }

          // console.log(maxVal);
          //console.log(that.data);

          if (sumVal < 5) {
            that.options.xaxis.tickSize = 1;
          }
          else if (sumVal < 50) {
            that.options.xaxis.tickSize = 10;
          }
          else if (sumVal < 100) {
            that.options.xaxis.tickSize = 20;
          }
          else if (sumVal < 500) {
            that.options.xaxis.tickSize = 50;
          }
          else {
            that.options.xaxis.tickSize = 100;
          }
        }
      ]
    },

    'summaryReportPie': {
      options: options['pieChartOptions'],
      initFunctions: [
        //Set styles
        utility.applyStyle,
        //Parse data
        function (that) {
          if (that.rawData && !that.rawData.by_channel) return;
          var oldData = that.rawData;
          that.data = [
            {
              label: I18n.t('users.agents.media_channel_types.email'),
              data: (oldData.by_channel.email_channel.total) / oldData.total * 100.0,
              color: '#8bccf0'
            },
            {
              label: I18n.t('users.agents.media_channel_types.web_form'),
              data: (oldData.by_channel.web_form_channel.total) / oldData.total * 100.0,
              color: '#C1A0DA'
            },
            {
              label: I18n.t('users.agents.media_channel_types.call'),
              data: (oldData.by_channel.call_channel.total) / oldData.total * 100.0,
              color: '#ffa6b8'
            },
            {
              label: I18n.t('users.agents.media_channel_types.chat'),
              data: (oldData.by_channel.chat_channel.total) / oldData.total * 100.0,
              color: '#71CC98'
            },
            {
              label: I18n.t('users.agents.media_channel_types.internal'),
              data: (oldData.by_channel.internal_channel.total) / oldData.total * 100.0,
              color: '#ffb30d'
            },
            {
              label: I18n.t('reports.summary_report.calls'),
              data: (oldData.by_channel.agent_calls.total) / oldData.total * 100.0,
              color: '#bcf0bc'
            }
          ]
        },
        //Parse data
        function (that) {
          if (that.rawData && !that.rawData.by_alert_type) return;
          var oldData = that.rawData;
          that.data = [
            {
              label: I18n.t('reports.summary_report.sla_red'),
              data: (oldData.by_alert_type.total_count_tasks_with_red_alert) / oldData.total * 100.0,
              color: '#c60016'
            },
            {
              label: I18n.t('reports.summary_report.sla_yellow'),
              data: (oldData.by_alert_type.total_count_tasks_with_yellow_alert) / oldData.total * 100.0,
              color: '#fbd039'
            },
            {
              label: I18n.t('reports.summary_report.sla_no_alert'),
              data: (oldData.by_alert_type.total_count_tasks_with_no_alert) / oldData.total * 100.0,
              color: '#8dc63f'
            }
          ]
        }
      ]
    },

    'comparisonReportChart': {
      options: options['stackedChartOptions'],
      initFunctions: [
        utility.applyStyle,
        //Set ticks
        function (that) {
          that.options.xaxis = {
            ticks: that.rawTicks
          }
        },
        function (that) {
          that.popoverIcon = "glyphicon glyphicon-user";
        }
      ]
    },

    'comparisonReportPausesChart': {
      options: options['stackedChartOptions'],
      initFunctions: [
        utility.applyStyle,
        function (that) {
          that.options.xaxis = {
            ticks: that.rawTicks
          }
        },
        function (that) {
          that.options.yaxis = $.extend(that.options.yaxis, {
            tickFormatter: function (val, axis) {
              return val.toFixed(4).toString().replace(/\.?0+$/, '') + "%"
            }
          })
        },
        function (that) {
          that.popoverIcon = "glyphicon glyphicon-user";
        }
      ]
    },

    'comparisonReportSolutionsPercentageChart': {
      options: options['stackedChartOptions'],
      initFunctions: [
        utility.applyStyle,
        function (that) {
          that.options.xaxis = {
            ticks: that.rawTicks
          }
        },
        function (that) {
          that.options.yaxis = $.extend(that.options.yaxis, {
            tickFormatter: function (val, axis) {
              return val + "%";
            }
          });
        },
        function (that) {
          that.popoverIcon = "glyphicon glyphicon-user";
        }
      ]
    },

    'summaryReportLines': {
      options: options['linesChartWithFilterOptions'],
      initFunctions: [
        function (that) {
          that.options.yaxis.tickSize = Math.round(
            utility.getMaxValue(
              [
                that.rawData.email_channel, that.rawData.web_form_channel, that.rawData.call_channel
              ]
            ) / 4
          )
        },
        function (that) {
          that.data = [
            {
              label: I18n.t('reports.summary_report.email'),
              data: that.rawData.email_channel,
              idx: 'email_channel'
            },
            {
              label: I18n.t('reports.summary_report.web_form'),
              data: that.rawData.web_form_channel,
              idx: 'web_form_channel'
            },
            {
              label: I18n.t('reports.summary_report.call'),
              data: that.rawData.call_channel,
              idx: 'call_channel'
            },
            {
              label: I18n.t('reports.summary_report.internal'),
              data: that.rawData.internal_channel,
              idx: 'internal_channel'
            },
            {
              label: I18n.t('reports.summary_report.chat'),
              data: that.rawData.chat_channel,
              idx: 'chat_channel'
            },
            {
              label: I18n.t('reports.summary_report.calls'),
              data: that.rawData.agent_calls,
              idx: 'agent_calls'
            },

          ]
        }
      ]
    }
  };

  function getConfiguration(key) {
    if (validConfigurationKeys().indexOf(key) > -1) {
      return configurations[key]
    } else {
      throw key + " is not a valid configuration key. Available keys are: " + validConfigurationKeys().toString();
    }
  }

  function validConfigurationKeys() {
    return Object.keys(configurations);
  }

  return {
    getConfiguration: getConfiguration
  }
});
