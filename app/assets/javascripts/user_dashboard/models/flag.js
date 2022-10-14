function Flag(name, parent) {
    var self = this;

    this.name = name;
    this.parent = parent;

    this.labelClass = ko.observable('label-info');

    if(self.name === 'urgent') {
      self.parent.isUrgent(true);
      self.labelClass('label-danger');
    } else {
      self.parent.isUrgent(false);
      self.labelClass('label-info');
    }

    this.destroy = function() {
      delete_data = self.ajax_data('delete');
      $.ajax({
        url: '/api/v1/tags',
        dataType: 'json',
        method: 'delete',
        data: self.ajax_data('delete'),
        success: function(data) {
          self.update_parent_flags(data);
          self._destroyed = true;
          return true;
        }
      });
      if(self.name == 'urgent') {
        self.parent.isUrgent(false);
      }
    }

    this.save = function() {
      $.ajax({
        url: '/api/v1/tags',
        dataType: 'json',
        method: 'post',
        data: self.ajax_data('post'),
        success: function(data) {
          self.update_parent_flags(data);
          return true;
        }
      });
    }
  
    this.ajax_data = function(method, name) {
      data_hash = {}
      data_hash['scope'] = 'flags';
      data_hash[self.parent_id_field()] = self.parent_id();
      data_hash[method === "post" ? "add" : "remove"] = self.name;
      return data_hash;
    }

    this.update_parent_flags = function(data) {
      var flags = [];
      _.forEach(data.tags, function(tag) {
        flags.push(new Flag(tag, self.parent));
      });
      self.parent.flags(flags);
    }

    this.parent_id_field = function() {
      return self.parent_type() + "_id";
    }

    this.parent_id = function() {
      return self.parent.data.id;
    }

    this.parent_class = function() {
      return self.parent.constructor.name;
    }

    this.parent_type = function() {
      if(self.parent_class() === "Task") {
        return 'task'
      } else if(self.parent_class() === "User") {
        return 'user'
      }
    }

    this.toJSON = function() {
      var cpy = ko.toJS(self);
      delete cpy.parent;
      return cpy;
    }
}
