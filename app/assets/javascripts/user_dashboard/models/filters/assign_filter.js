Filters.AssignFilter = function() {
    var self = this;
    this.filter = ko.observable('assigned_to_me');
    this.selected = ko.observable(
        function(task) {
            switch (self.filter()) {
                case 'open_to_all':
                    return ( task.data.assigned_to_user_id === null || task.data.state === 'ready') && UserDashboard.current_user_service_channels.find(x => x.id === task.data.service_channel_id) != undefined;
                case 'assigned_to_me':
                    return (task.data.assigned_to_user_id == UserDashboard.currentUserId || task.data.assigned_to_user_id == null || task.data.skills.length > 0 || task.data.created_by_user_id == UserDashboard.currentUserId || (UserDashboard.current_user_service_channels.find(x => x.id === task.data.service_channel_id) != undefined));
                case 'created_by_me':
                    return task.data.created_by_user_id == UserDashboard.currentUserId;
                default:
                    return false;
            }
        }
    );

    this.set = function(filter) {
        self.filter(filter);
    };
};

Filters.MultiAssignFilterOptions = ['open_to_all', 'assigned_to_me', 'created_by_me'];
Filters.MultiAssignFilter = function() {
    var self = this;
    this.filters = ko.observableArray(Filters.MultiAssignFilterOptions);
    this.selected = ko.observable(
        function(task) {
            if(self.filters().length == 0) { return true; }
            if((task.data.assigned_to_user_id === null || task.data.state === 'ready') && UserDashboard.current_user_service_channels.find(x => x.id === task.data.service_channel_id) != undefined && self.filters().indexOf('open_to_all') > -1) { return true; }
            if(((task.assigned_to_user_id() ==  UserDashboard.currentUserId && task.data.created_by_user_id !=  UserDashboard.currentUserId) || task.data.skills.length > 0) && self.filters().indexOf('assigned_to_me') > -1) { return true; }
            if(task.data.created_by_user_id  ==  UserDashboard.currentUserId && self.filters().indexOf('created_by_me') > -1)  { return true; }
            if(task.assigned_to_user_id() != UserDashboard.currentUserId && self.filters().indexOf('assigned_to_other') > -1)  { return true; }
            if(task.follow_user_ids().includes(UserDashboard.currentUserId) && self.filters().indexOf('i_am_following') > -1)  { return true; }

            return false;
        }
    );

    this.set = function(filter) {
        if(!filter || filter.length == 0) {
          self.filters(Filters.MultiAssignFilterOptions);
        } else {
          self.filters(filter);
        }
    };
};
