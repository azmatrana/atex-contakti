Views.Order = function() {
    var self = this;
    this.order = ko.observable(null);
    this.loading = ko.observable(true);

    this.fetchOrder = function(_task){
        let order_id = _task.order_id()
        this.order(null);
        self.loading(true);
        $.ajax({
            url: `/api/v1/orders/${order_id}`,
            dataType: 'json',
            success: function (data) {
                self.order(data);
                self.loading(false);
            }
        });
    }
};

Views.Order.prototype = Views;
