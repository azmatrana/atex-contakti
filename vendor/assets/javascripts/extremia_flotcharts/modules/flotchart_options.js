modulejs.define('flotchartOptions', function() {

    //See https://github.com/flot/flot/blob/master/API.md for options details
    var options = {
        'horizontalBarsOptions': {
            grid: {
                show: true,
                aboveData: false,
                color: "#3f3f3f",
                labelMargin: 5,
                axisMargin: 0,
                borderWidth: 0,
                borderColor: null,
                minBorderMargin: 5,
                clickable: true,
                hoverable: true,
                autoHighlight: false,
                mouseActiveRadius: 20,
                backgroundColor: {}
            },

            series: {
                grow: {
                    active: false
                },
                bars: {
                    show: true,
                    horizontal: true,
                    barWidth: 0.2,
                    fill: 1,
                    fillColor: "#0dc0c0"
                }
            },

            legend: {
                position: "ne",
                backgroundColor: null,
                backgroundOpacity: 0
            },

            yaxis: {
                ticks: [],
                show: true
            },

            colors: ["#0dc0c0"],

            tooltip: true,

            tooltipOpts: {
                content: "%x.0",
                shifts: {
                    x: -30,
                    y: -50
                },
                defaultTheme: false
            }
        },

        'stackedChartOptions': {
            grid: {
                show: true,
                aboveData: false,
                color: "#3f3f3f",
                labelMargin: 5,
                axisMargin: 0,
                borderWidth: 0,
                borderColor: null,
                minBorderMargin: 5,
                clickable: true,
                hoverable: true,
                autoHighlight: true,
                mouseActiveRadius: 20,
                backgroundColor: {}
            },

            series: {
                grow: {
                    active: false
                },
                stack: 0,
                lines: {
                    show: false,
                    fill: true,
                    steps: false
                },
                bars: {
                    show: true,
                    barWidth: 0.5,
                    fill: 1,
                    align: 'center'
                }
            },

            legend: {
                position: "ne",
                backgroundColor: null,
                backgroundOpacity: 0
            },

            colors: [],

            shadowSize: 1,

            tooltip: true,

            tooltipOpts: {
                content: "%s : %y.0",
                shifts: {
                    x: -30,
                    y: -50
                },
                defaultTheme: false
            },

            yaxis: {
                min: 0
            }
        },

        'stackedChartTwoOptions': {
            colors: ["#2980B9", "#F39C12", "#8dc63f"],
            grid: {
                show: true,
                aboveData: false,
                color: "#3f3f3f",
                labelMargin: 5,
                axisMargin: 0,
                borderWidth: 0,
                borderColor: null,
                minBorderMargin: 5,
                clickable: true,
                hoverable: true,
                autoHighlight: false,
                mouseActiveRadius: 20,
                backgroundColor: {}
            },

            series: {
                grow: {
                    active: false
                },
                stack: true,
                lines: {
                    show: false,
                    fill: true,
                    steps: false
                },
                bars: {
                    show: true,
                    barWidth: 0.3,
                    fill: 1,
                    align: 'center',
                    lineWidth: 1,
                    position: "ne",
                    noColumns: 1,
                    horizontal: true
                }
            },
            legend: {
                show: true,
                position: "nw",
                noColumns: 5,
                backgroundColor: null,
                backgroundOpacity: 0
            },

            colors: [],

            shadowSize: 1,

            tooltip: true,

            tooltipOpts: {
                content: "%s : %x.0",
                shifts: {
                    x: -30,
                    y: -50
                },
                defaultTheme: false
            },

            yaxis: {
                tickSize: 10,
                min: -1,
                max: 4
            },
            xaxis: {
                tickSize: 5
            }
        },

        'pieChartOptions': {
            series: {
                pie: {
                    show: true,
                    innerRadius: 0,
                    highlight: {
                        opacity: 0.1
                    },
                    radius: 1,
                    stroke: {
                        color: "#fff",
                        width: 1
                    },
                    startAngle: 2,
                    combine: {
                        color: "#EEE",
                        threshold: 0.00
                    },
                    label: {
                        show: true,
                        radius: 1,
                        formatter: function(label, series) {
                            return "<div class=\"label label-inverse\">" + label + "&nbsp;" + Math.round(series.percent) + "%</div>"
                        }
                    }
                },
                grow: {
                    active: false
                }
            },

            legend: {
                show: false
            },

            grid: {
                hoverable: true,
                clickable: true,
                backgroundColor: {}
            },

            tooltip: true,

            tooltipOpts: {
                content: "%s : %p.0%",
                shifts: {
                    x: -30,
                    y: -50
                },
                defaultTheme: false
            }
        },

        'linesChartOptions': {
        colors: ["#2980B9", "#F39C12", "#E74C3C"],

            grid: {
            color: "#0dc0c0",
                borderWidth: 1,
                borderColor: "transparent",
                clickable: true,
                hoverable: true
        },

        series: {
            grow: {
                active: false
            },
            lines: {
                show: true,
                    fill: false,
                    lineWidth: 5,
                    steps: false,
                    color: "#0dc0c0"
            },
            points: {
                show: false
            }
        },
        legend: {
            show: true,
            position: "nw",
            noColumns: 3,
            backgroundColor: null,
            backgroundOpacity: 0
        },

        yaxis: {
            ticks: 3,
                tickSize: 10,
                tickFormatter: function(val, axis) {
                return val + ""
            }
        },

        xaxis: {
            ticks: 24,
                tickDecimals: 0,
        },

        shadowSize: 0,

            tooltip: true,

            tooltipOpts: {
            content: "%s : %y.0",
                shifts: {
                x: -30,
                    y: -50
            },
            defaultTheme: false
        }
    },
        'linesChartWithFilterOptions': {
            colors: ["#8bccf0", "#C1A0DA", "#ffa6b8", "#ed8500", "#71CC98" ],

            grid: {
                color: "#0dc0c0",
                borderWidth: 1,
                borderColor: "transparent",
                clickable: true,
                hoverable: true
            },

            series: {
                grow: {
                    active: false
                },
                lines: {
                    show: true,
                    fill: false,
                    lineWidth: 5,
                    steps: false,
                    color: "#0dc0c0"
                },
                points: {
                    show: true
                }
            },

            legend: {
                show: true,
                labelFormatter: function (label, series) {

                    cb =  '<label class="legendCB"';
                    cb += 'for="legend_'+series.idx+'"  ';
                    cb += 'data-key="'+series.idx+'" >';
                    cb += '<input  type="checkbox" class="checkbox" ';
                    if (series.data.length > 0){
                        cb += 'checked="true" ';
                    }
                    cb += 'id="legend_'+series.idx+'"/>';
                    cb += '<span >'+label+'</span>';
                    cb +=  '</label>'
                    return cb;
                },
                noColumns: 6,
                position: "sw"
            },

            yaxis: {
                ticks: 3,
                tickSize: 10,
                tickFormatter: function(val, axis) {
                    return val + ""
                }
            },

            xaxis: {
                ticks: 24,
                tickDecimals: 0
            },

            shadowSize: 0,

            tooltip: true,

            tooltipOpts: {
                content: "%s : %y.0",
                shifts: {
                    x: -30,
                    y: -50
                },
                defaultTheme: false
            }
        }
    };

    return options;
});
