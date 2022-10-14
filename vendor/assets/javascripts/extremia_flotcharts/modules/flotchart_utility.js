modulejs.define('flotchartUtility', function() {

    var utility =  {
        chartColors: [ themerPrimaryColor, "#444", "#777", "#999", "#DDD", "#EEE" ],
        //chartBackgroundColors: ["transparent", "transparent"],
        chartBackgroundColors: ["rgba(255,255,255,0)", "rgba(255,255,255,0)"],

        applyStyle: function(that)
        {
            that.options.colors = utility.chartColors;
            that.options.grid.backgroundColor = { colors: utility.chartBackgroundColors };
            that.options.grid.borderColor = utility.chartColors[0];
            that.options.grid.color = utility.chartColors[0];
        },

        // generate random number for charts
        randNum: function()
        {
            return (Math.floor( Math.random()* (1+40-20) ) ) + 20;
        },
        //Get maximum value out of set of data arrays for graphs
        getMaxValue: function(dataSet) {
            var values = [];
            $.each(dataSet, function(index, items) {
                values.push(Math.max.apply(null, $.map(items, function(item) { return item[1]; })));
            });
            return Math.max.apply(null, values);
        }
    }

    return utility;

});