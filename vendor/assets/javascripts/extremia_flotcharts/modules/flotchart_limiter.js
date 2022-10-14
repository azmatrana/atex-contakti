modulejs.define('flotchartLimiter', function() {

    return {
        defaultLimit: 5,

        limitData: function(data, limit) {
            limit = limit || this.defaultLimit;
            return this.ensureItems(this.limitItems(data, limit), limit, 1);
        },

        limitTicks: function(ticks, limit) {
            limit = limit || this.defaultLimit;
            return this.ensureItems(this.limitItems(ticks, limit), limit, 0);
        },

        ensureData: function(data, limit) {
            return this.ensureItems(data, limit, 1);
        },

        ensureTicks: function(data, limit) {
            return this.ensureItems(data, limit, 0);
        },

        ensureItems: function(items, limit, positionIndex) {
            var itemsLength = items.length;
            if(itemsLength + 1 < limit) {
                for(var i = itemsLength; i < limit; i++) {
                    var newItem;
                    positionIndex == 0 ? newItem = [null, ''] : newItem = ['', null];
                    items.unshift(newItem);
                }
            }
            return items;
        },
        limitItems: function(items, limit) {
            limit = limit || this.defaultLimit;
            var itemsLength = items.length;
            if(itemsLength > limit) {
                items = items.slice(0, limit);
            }
            return items;
        },

        enableMaximizeButton: function(id, data, maximized) {
            var toggler = $('a[data-chart-id="' + id +'"]'),
                icon;
            if(data.length <= this.defaultLimit) {
                toggler.hide();
            }
            else {
                icon = toggler.find('.glyphicon');
                //If the chart is initialized in maximized state, make sure the toggle button is in correct state
                if(maximized) {
                    icon.removeClass('glyphicon-plus').addClass('glyphicon-minus');
                    $('#'+id).data('maximized',  true);
                } else {
                    $('#'+id).data('maximized',  false);
                }
                toggler
                    .off('click')
                    .on('click', function () {
                        $('#'+id).data('extremiaFlotchart').toggle();
                        icon.hasClass('glyphicon-plus') ? $('#' + id).data('maximized', true) : $('#' + id).data('maximized', false);
                        icon.hasClass('glyphicon-plus') ? icon.removeClass('glyphicon-plus').addClass('glyphicon-minus') :
                            icon.removeClass('glyphicon-minus').addClass('glyphicon-plus');
                        return false;
                    })
            }
        }

    }

});
