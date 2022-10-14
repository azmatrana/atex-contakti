//= require_self
//= require_tree ./

var SharedViews = {
  registerCallback: function(scope, func) {
    this.callbacks[scope].push(func);
  }
};
