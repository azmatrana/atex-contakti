SharedViews.ReplyTemplates = function () {
  var self = this;
  this.templatesList = ko.observableArray([]);
  this.templatesFilter = ko.observable("");
  this.templatesFilterForAgent = ko.observable("");

  this.templateText = ko.observable('');
  this.ckEditor = null;


  this.filteredTemplatesList = ko.computed(function () {
    return self.templatesList().filter(function (obj) {
      return (obj.text.toLocaleLowerCase().includes(self.templatesFilter().toLocaleLowerCase()));
    }).sort(function (a, b) {
      if (a.text.toLocaleLowerCase() < b.text.toLocaleLowerCase()) {
        return -1;
      }
      if (a.text.toLocaleLowerCase() > b.text.toLocaleLowerCase()) {
        return 1;
      }
      return 0;
    });
  })

    this.filteredTemplatesListForAgent = ko.computed(function () {
    return self.templatesList().filter(function (obj) {
      return (obj.text.toLocaleLowerCase().includes(self.templatesFilterForAgent().toLocaleLowerCase()));
    }).sort(function (a, b) {
      if (a.text.toLocaleLowerCase() < b.text.toLocaleLowerCase()) {
        return -1;
      }
      if (a.text.toLocaleLowerCase() > b.text.toLocaleLowerCase()) {
        return 1;
      }
      return 0;
    });
  })

  this.fetchReplyTemplates = function () {
    $.ajax({
      url: '/template_replies',
      dataType: 'json',
      success: function (data) {
        self.templatesList.destroyAll()
        data.forEach(function (template) {
          self.templatesList.push(template);
        });
      }
    });
  }
  this.fetchReplyTemplates();

  this.createReplyTemplate = function () {
    const template_data = {
      template_text: self.templatesFilterForAgent().length > 0 ? self.templatesFilterForAgent() :  self.ckEditor.getData()
    };
    $.ajax({
      url: '/' + I18n.locale + '/template_replies',
      dataType: 'json',
      method: "post",
      data: template_data,
      success: function (response) {
        if (response.errors) {
          alert(response.errors)
        } else {
          self.templatesList.push(response.data);
          self.templatesFilter('');
          self.templatesFilterForAgent('');
          self.ckEditor.setData("");

        }
      }
    })

  }

  this.deleteTemplate = function (templateId) {
    changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete)
    if (changed == false) {
      return
    }
    $.ajax({
      url: '/' + I18n.locale + '/template_replies/' + templateId,
      type: 'DELETE',
      success: function (response) {
        if (response.errors) {
        } else {
          console.log(response);
        }
        self.fetchReplyTemplates()
      }
    });
  }
  this.saveTemplate = function (data) {
    let editor = CKEDITOR.instances[`chat_template_edit${data.id}`]
    data.text = editor.getData();
    $.ajax({
      url: '/' + I18n.locale + '/template_replies/' + data.id,
      dataType: 'json',
      method: 'PATCH',
      data: data,
      success: function (response) {
        if (response.errors) {
          alert(response.errors);
        } else {
          alert(response.success)
          self.fetchReplyTemplates();
          console.log(response.data);
        }
      }
    });
  }

  this.reinitializeCkEditors = function () {
    self.filteredTemplatesList().forEach((filter) => {
      var editor = CKEDITOR.instances[`chat_template_edit${filter.id}`];
      if (editor) {
        editor.destroy(true);
      }
      var element = document.getElementById(`chat_template_edit${filter.id}`);
      if (element) {
        let ckEditorElement = CKEDITOR.replace(`chat_template_edit${filter.id}`, {
          language: I18n.currentLocale(),
          removePlugins: 'elementspath',
          resize_enabled: false
        });
      }
    })
  }

  $(document).ready(function () {
    var element = document.getElementById('chat_template_text');
    if (element) {
      var ckEditorElement = CKEDITOR.replace('chat_template_text', {
        language: I18n.currentLocale(),
        removePlugins: 'elementspath',
        resize_enabled: false
      });

      self.ckEditor = ckEditorElement;
    }
  })


}
SharedViews.ReplyTemplates.prototype = SharedViews;
