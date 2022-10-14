
QueryThrottler = (function($) {
    function QueryThrottler(options) {
        this.options = $.extend({
            timeout: 250,
            query: null,
            done: null
        }, options);

        this.queryPromise = null;
        this.timer = null;
        this.enabled = false;
    }

    QueryThrottler.prototype.abort = function() {
        this.enabled = false;

        if (this.queryPromise) {
            this.queryPromise.abort();
        }
        if (this.timer) {
            clearTimeout(this.timer);
        }

        this.queryPromise = null;
        this.timer = null;
    };

    QueryThrottler.prototype.query = function() {
        this.enabled = true;

        this.params = Array.prototype.slice.call(arguments);

        if (this.timer) {
            clearTimeout(this.timer);
        }
        this.timer = setTimeout(this.execute.bind(this), this.options.timeout);
    };

    QueryThrottler.prototype.execute = function() {
        this.timer = null;

        if (this.queryPromise) {
            this.queryPromise.abort();
        }

        if (!this.enabled) return;

        this.queryPromise = this.options.query.apply(this, this.params);
        this.queryPromise.done(this.onQueryDone.bind(this));
    };

    QueryThrottler.prototype.onQueryDone = function() {
        if (!this.enabled) return;

        var args = Array.prototype.slice.call(arguments);

        if (typeof this.options.done === "function") {
            this.options.done.apply(this, args);
        }
    };

    return QueryThrottler;
})(jQuery);