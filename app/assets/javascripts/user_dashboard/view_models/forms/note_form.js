
Views.NoteForm = function(params) {

  var self = this;

  this.task = params.task;
  this.showFormObservable = params.showForm;
  this.editMode = ko.observable(false);
  this.readOnlyMode = ko.pureComputed(function() { return !self.editMode(); });

  this.showFormObservable.subscribe(function() {
    self.editMode(self.task().noteBody() ? false : true);
  });

  this.toggleEdit = function() {
    self.editMode(!self.editMode());
  };

  this.enableEdit = function() {
    self.editMode(true);
  };

  this.toggleEdit = function() {
    self.editMode(false);
  };
  task_id = self.task().id
  $.ajax({
    'url': '/attachments/'+task_id,
    'type': 'get',
    'data': 'json',
    success: function(resp){
      $("#attachments").html(resp);
    },
    error: function(error){
      console.log(error);
    }
  })

  this.saveNote = function(data, event) {
    form_data = data;
    var form = $(event.target).closest('form');
    formm = form;
    var saveButton = $("#reply_button", form);

    form.bind("ajax:beforeSend", function() {
      saveButton.button("loading");
    });
    form.bind("ajax:success", function(respData, respStatus, respXhr) {
      self.task().noteBody(respStatus.body);
    });
    form.bind("ajax:complete", function(respData, respStatus, respXhr) {
      task_id = self.task().id
      $.ajax({
        'url': '/attachments/'+task_id,
        'type': 'get',
        'data': 'json',
        success: function(resp){
          console.log("*********************");
          console.log(resp);
          console.log("*********************");
          $("#attachments").html(resp);
        },
        error: function(error){
          console.log(error);
        }
      })
      saveButton.button("reset");
    });

    form.trigger('submit.rails');
  };

  this.clearNote = function(data, event) {
    var form = $(event.target).closest('form');

    var textArea = form.find('textarea');
    $('#task-note-boxy-container')[0].value = '';

    form.trigger('submit.rails');
    self.showFormObservable(false);
  };


  Views.BaseForm.call(this);
};

_.extend(Views.NoteForm.prototype, new Views.BaseForm());
Views.NoteForm.prototype.constructor = Views.NoteForm;

