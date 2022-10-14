Views.SkillItem = function(skill) {
  var self = this;
  this.skill = skill;

  this.deleteClicked = function() {
    self.skill().destroy();
    return true;
  };

};

Views.SkillItem.prototype = Views;

