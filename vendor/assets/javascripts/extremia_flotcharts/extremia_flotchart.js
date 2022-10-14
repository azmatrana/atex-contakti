(function($) {

    var ExtremiaFlotchart = function(element, configurationKey, args) {
        this.options = {};//Options for flotcharts
        this.configuration = null;
        this.args = args;
        this.rawData = [];//Data got when initializing
        this.data = [];
        this.rawTicks = [];
        this.ticks = [];//Chart ticks
        this.$container = $(element);
        this.$parentcontainer = $(element).parent().parent().parent();
       
     //   console.log("container:"+this.$supercontainer.height());
       
        
        this.maximized = this.$container.data('maximized');
        this.argsWhiteList = ['rawData','render','rawTicks'];
        this.argsToCall = [];
        this.popoverIcon = "";
        this.plot = null;//The plot object
        this.initialHeight = this.$container.height();
        this.initialContainerHeight = this.$parentcontainer.height();
        this.initialize(configurationKey);
    };

    ExtremiaFlotchart.prototype = {

        constructor: ExtremiaFlotchart,

        initialize: function(configurationKey) {
            if (!configurationKey) {
                throw "Must provide a valid configuration key";
            } else {
                this.extractArgs();
                this.loadConfiguration(configurationKey);
                //See extractArgs
                $.each(this.argsToCall,function(i,a) {
                    this.argsHandler(a);
                }.bind(this));
                this.argsToCall = [];
            }
        },

        toggle: function() {
            this.maximized = !this.maximized;
            if(this.maximized){
                this.options.yaxis.max = this.rawTicks.length;
            }else this.options.yaxis.max = 4;

            this.render();
        },

        setHeight: function() {
            if($(".gridster ul").data('gridster')){
                $(".gridster ul").data('gridster').resize_widget(this.$parentcontainer,null,this.maximized?2:1);
                this.$container.css('height',this.maximized ? dynamicDashboard.widgetHeight*2-100: this.initialHeight);
            }
            else{
                this.$container.css('height', this.initialHeight);
            }
            
        },

        loadConfiguration: function(key) {
            this.configuration = modulejs.require('flotchartConfigurations').getConfiguration(key);
            this.options = this.configuration['options'];
            $.each(this.configuration['initFunctions'], function(i,f) {
                f(this);
            }.bind(this));
        },

        render: function() {
            var self = this;
            $.each(this.configuration['initFunctions'], function(i,f) {
                f(self);
            });
            //If the init functions did not change the data, then use the data provided to constructor
            if (this.data.length == 0 && this.rawData.length > 0) {
                this.data = this.rawData;
            }

            this.setHeight();

            if (this.$container && this.options) {
                this.plot = $.plot(this.$container, this.data, this.options);
                if (this.popoverIcon != "") {
                    this.checkOverlappingLabels();
                }
            }
        },

        /*
         When viewing charts with long x-axis labels, the contents might overlap
         If this chart has a popoverIcon defined, the long labels are converted to that icon with the original data as a tooltip on hover
         */
        checkOverlappingLabels: function() {
            var xAxisLabels = $('div.flot-x-axis > div.flot-tick-label', this.$container);
            xAxisLabels.css('overflow','hidden');
            var overflowing = false;
            $.each(xAxisLabels, function(i,label) {
                if (label.offsetHeight < label.offsetHeight || label.offsetWidth < label.scrollWidth) {
                    overflowing = true;
                    return false;
                }
            });
            if (overflowing) {
                $.each(xAxisLabels, function(i, label) {
                    var $label = $(label),
                        oldVal = $label.text(),
                        oldWidth = $label.width();
                    $label.html(
                        $('<i></i>')
                            .addClass(this.popoverIcon)
                            .addClass("flotchart-label-tooltip")
                            .attr('title',oldVal)
                            .css('z-index',1)
                    );
                    $label.width(oldWidth);
                    $('i',$label).tooltip({
                        placement: 'bottom',
                        container: 'body',
                        trigger: 'hover'
                    });
                }.bind(this));
            }
        },

        /*
         Chart can be given arguments that the chart has as property, any additional arguments go to argsToCall.
         All non-property arguments in whitelist must have a related handler in argsHandler
         */
        extractArgs: function() {
            if (this.args) {
                $.each(this.args,function(a) {
                    if (this.argsWhiteList.indexOf(a) > -1) {
                        if (this.hasOwnProperty(a)) {
                            this[a] = this.args[a];
                        } else {
                            this.argsToCall.push(a);
                        }
                    }
                }.bind(this));
            }
        },

        //Must contain handler for all whitelisted arguments that are not properties of ExtremiaFlotchart
        argsHandler: function(argument) {
            switch (argument) {
                case 'render':
                    this.render();
            }
        }
    };

    $.fn.extremiaFlotchart = function(configurationKey, args) {
        return this.each(function() {
            var $this = $(this),
                data = $(this).data('extremiaFlotchart');
            if (!data || args['redraw']) {
                $this.data('extremiaFlotchart',(data = new ExtremiaFlotchart(this, configurationKey, args)));
            }
        })
    }

    $.fn.extremiaFlotchart.Constructor = ExtremiaFlotchart;

})(jQuery);
