

// This is not actually a view-model in knockout sense.
Views.DateRangePicker = function() {

    var self = this;

    this.startDate = null;
    this.endDate = null;

    this.callbacks = {
        filterChanged: []
    };

    this.filterChanged = function() {
        _.forEach(self.callbacks.filterChanged, function(func) {
            func(self);
        });
    };


    this.initialize = function() {

        $(document).on('apply.daterangepicker', 'input.date-range', function (ev, picker) {

            self.startDate = picker.startDate;
            self.endDate = picker.endDate;


            self.filterChanged();

            $('a.close-btn.clear-date').removeClass('hidden');
        });

        $('input.date-range').on('cancel.daterangepicker', function () {
            self.startDate = null;
            self.endDate = null;

            self.filterChanged();

            $(this).val('');
            $('a.close-btn.clear-date').addClass('hidden');
        });

        $('a.close-btn.clear-date').on('click', function () {
            $('button.cancelBtn').click();
        });
    };
};

Views.DateRangePicker.prototype = Views;
