function Skill(name, parent) {
 
    var self = this;

    this.name = name;
    this.parent = parent;
    if(this.parent){
      this.priority_tag = _.find(parent.data.skills_priority, function(s){ return s.name == self.name}) || {}
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

    this.destroy = function() {
      delete_data = self.ajax_data('delete');
      $.ajax({
        url: '/api/v1/tags',
        dataType: 'json',
        method: 'delete',
        data: self.ajax_data('delete'),
        success: function(data) {
          self.update_parent_skills(data);
          self._destroyed = true;
          return true;
        }
      });
    }

    this.save = function() {
      $.ajax({
        url: '/api/v1/tags',
        dataType: 'json',
        method: 'post',
        data: self.ajax_data('post'),
        success: function(data) {
          self.update_parent_skills(data);
          return true;
        }
      });
    }
  
    this.ajax_data = function(method, name) {
      data_hash = {}
      data_hash['scope'] = 'skills';
      data_hash[self.parent_id_field()] = self.parent_id();
      data_hash[method === "post" ? "add" : "remove"] = self.name;
      return data_hash;
    }

    this.update_parent_skills = function(data) {
      var skills = [];
      _.forEach(data.tags, function(tag) {
        skills.push(new Skill(tag, self.parent));
      });
      self.parent.skills(skills);
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

