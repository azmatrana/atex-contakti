
function TaskDecorator(task_object) {
  var self = this;
  this.id = task_object.id;
  this.name = (function() {
    return "Task " + self.id;
  })();
  this.state = task_object.state
  this.date = moment(task_object.created_at).format("DD.MM.YYYY HH:mm");
  this.fullOriginalDate = task_object.created_at;
  this.agent = task_object.agent;
  this.agentFullName = (function() {
    if (!self.agent)
      return "";
    return self.agent.first_name + " " + self.agent.last_name;
  })();
  this.mediaChannel = task_object.media_channel;
  this.serviceChannel = task_object.service_channel;
  this.internalNotes = task_object.note_body;
  this.contentHidden = true;
  this.iconClass = (function() {
    switch (task_object.media_channel) {
      case 'call':
        return ' glyphicon-earphone';
      case 'web_form':
        return 'glyphicon-globe';
      case 'internal':
        return 'glyphicon-tag';
      case 'chat':
        return 'glyphicon-comment';
      default:
        return 'glyphicon-envelope';
    }
  })();
  this.cssOpenedTask = "task-background-color-opened";
  this.cssArrowDown = "fa-angle-double-down"; // When task not opened
  this.cssArrowUp = "fa-angle-double-up"; // When task is clicked and opened
  this.cssLeftBorder = (function() {
    switch(task_object.state) {
      case "new":
        return "new";
      case "open":
        return "open";
      case "waiting":
        return "waiting";
      case "ready":
        return "ready";
    }
  })();
  this.reminder = {text: ""};
}
