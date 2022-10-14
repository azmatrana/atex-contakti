define([
  "jquery",
  "knockout",
  "i18next",
  "api"
], function ($,
             ko,
             i18n,
             api) {

  function Skill(name, parent) {
    this.name = name;
    this.parent = parent;
    this.priorityClass = 'priority-no';

    if(this.parent) {
      this.priority_tag = ko.utils.arrayFirst(this.parent._originalData.skills_priority, function(s) {
        if(s.name == name) {
          return s;
        };
      })


      if(this.priority_tag) {
        switch (this.priority_tag.priority) {
          case 0:
            this.priorityClass = ' priority-0';
            break;
          case 1:
            this.priorityClass = ' priority-1';
            break;
          case 2:
            this.priorityClass = ' priority-2';
            break;
          case 3:
            this.priorityClass = ' priority-3';
            break;
          default:
            this.priorityClass = 'priority-no';
        };
      }
    };

  }

  Skill.prototype.destroy = function() {
    var self = this;
    $.ajax({
      url: '/api/v1/tags',
      dataType: 'json',
      method: 'delete',
      data: this.ajax_data('delete'),
      success: function(data) {
        self.update_parent_generic_tags(data);
        self._destroyed = true;
        return true;
      }
    });
  };

  // Skill.prototype.save = function() {
  //   $.ajax({
  //     url: '/api/v1/tags',
  //     dataType: 'json',
  //     method: 'post',
  //     data: this.ajax_data('post'),
  //     success: function(data) {
  //       this.update_parent_generic_tags(data);
  //       return true;
  //     }
  //   });
  // };

  Skill.prototype.ajax_data = function(method, name) {
    data_hash = {};
    data_hash['scope'] = 'skills';
    data_hash[this.parent_id_field()] = this.parent_id();
    data_hash[method === "post" ? "add" : "remove"] = this.name;
    return data_hash;
  };

  Skill.prototype.update_parent_generic_tags = function(data) {
    var tags = [];
    var self = this;
    ko.utils.arrayForEach(data.tags, function(tag) {
      tags.push(new Skill(tag, self.parent));
    });
    this.parent.generic_tags(tags);
    self.parent.tagsAsString(self.parent._getTagsAsString());
    $('input#tags').tokenfield('setTokens', self.parent.tagsAsString());

  };

  Skill.prototype.parent_id_field = function() {
    return this.parent_type() + "_id";
  };

  Skill.prototype.parent_id = function() {
    return this.parent.id;
  };

  Skill.prototype.parent_class = function() {
    return this.parent.constructor.name;
  };

  Skill.prototype.parent_type = function() {
    if(this.parent_class() === "Task") {
      return 'task'
    } else if(this.parent_class() === "User") {
      return 'user'
    }
  };

  Skill.prototype.toJSON = function() {
    var cpy = ko.toJS(this);
    delete cpy.parent;
    return cpy;
  };


  return Skill;
});
