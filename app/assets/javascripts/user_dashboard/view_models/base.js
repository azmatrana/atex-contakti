//= require_self
//= require_tree ./

var Views = {
    registerCallback: function(scope, func) {
        this.callbacks[scope].push(func);
    }
};
