define([
  "jquery",
  "knockout",
  "i18next",
  "api"
], function ($,
             ko,
             i18n,
             api) {

  function GenericTag(name, parent) {
    this.name = name;
    this.parent = parent;
  }

  GenericTag.prototype.destroy = function() {
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

  // GenericTag.prototype.save = function() {
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

  GenericTag.prototype.ajax_data = function(method, name) {
    data_hash = {};
    data_hash['scope'] = 'generic_tags';
    data_hash[this.parent_id_field()] = this.parent_id();
    data_hash[method === "post" ? "add" : "remove"] = this.name;
    return data_hash;
  };

  GenericTag.prototype.update_parent_generic_tags = function(data) {
    var tags = [];
    var self = this;
    ko.utils.arrayForEach(data.tags, function(tag) {
      tags.push(new GenericTag(tag, self.parent));
    });
    this.parent.generic_tags(tags);
    self.parent.tagsAsString(self.parent._getTagsAsString());
    $('input#tags').tokenfield('setTokens', self.parent.tagsAsString());

  };

  GenericTag.prototype.parent_id_field = function() {
    return this.parent_type() + "_id";
  };

  GenericTag.prototype.parent_id = function() {
    return this.parent.id;
  };

  GenericTag.prototype.parent_class = function() {
    return this.parent.constructor.name;
  };

  GenericTag.prototype.parent_type = function() {
    if(this.parent_class() === "Task") {
      return 'task'
    } else if(this.parent_class() === "User") {
      return 'user'
    }
  };

  GenericTag.prototype.toJSON = function() {
    var cpy = ko.toJS(this);
    delete cpy.parent;
    return cpy;
  };


  return GenericTag;
});
