Views.FlagItem = function(flag) {
  var self = this;
  this.flag = flag;

  this.deleteClicked = function() {
    self.flag().destroy();
    return true;
  };

};

Views.FlagItem.prototype = Views;


