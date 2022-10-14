SharedViews.BasicTemplates = function () {
  var self = this;
  this.basicTemplatesList = ko.observableArray([]);
  this.templateTitle = ko.observable('');
  this.templateText = ko.observable('');
  this.basicTemplatesFilter = ko.observable('');
  this.ckEditor = null;


  this.filteredBasicTemplates = ko.computed(function () {
    let filteredTemplates = self.basicTemplatesList().filter(function (obj) {
      return (obj.title.toLocaleLowerCase().includes(self.basicTemplatesFilter().toLocaleLowerCase()) ||
        obj.text.toLocaleLowerCase().includes(self.basicTemplatesFilter().toLocaleLowerCase()));
    });
    return filteredTemplates;
  })

  this.createBasicTemplate = function(){
    const data = {
      title: self.templateTitle(),
      text: self.ckEditor.getData()
    }
    $.ajax({
      url: '/' + I18n.locale + '/basic_templates',
      dataType: 'json',
      method: "post",
      data: data,
      success: function (response) {
        if (response.errors) {
          alert(response.errors)
        }
        else{
          self.basicTemplatesList.push(response.data);
          self.templateText('');
          self.ckEditor.setData("");
          self.templateTitle('');
        }
      }
    })
  }

  this.fetchBasicTemplates = function(){
    $.ajax({
      url: '/basic_templates',
      dataType: 'json',
      success: function (data) {
        self.basicTemplatesList.destroyAll()
        self.basicTemplatesList(data);
      }
    });
  }

  this.fetchBasicTemplates();

  this.saveBasicTemplate = function(data){
    let editor = CKEDITOR.instances[`basic_template_edit${data.id}`]
    data.text = editor.getData();
    $.ajax({
      url: '/' + I18n.locale + '/basic_templates/' + data.id,
      dataType: 'json',
      method: 'PATCH',
      data: data,
      success: function (response) {
        if (response.errors) {
          alert(response.errors);
        } else {
          alert(response.success)
          self.fetchBasicTemplates();
          console.log(response.data);
        }
      }
    });
  }

  this.deleteBasicTemplate =function(templateId){
    let changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete)
    if (changed == false)
    {
      return
    }
    $.ajax({
      url: '/' + I18n.locale + '/basic_templates/'+ templateId,
      type: 'DELETE',
      success: function (response) {
        if (response.errors) {
        } else {
          console.log(response);
        }
        self.fetchBasicTemplates()
      }
    });
  }

  this.reinitializeCkEditors = function () {
    self.filteredBasicTemplates().forEach((filter) => {
      var editor = CKEDITOR.instances[`basic_template_edit${filter.id}`];
      if (editor) {
        editor.destroy(true);
      }
      var element = document.getElementById(`basic_template_edit${filter.id}`);
      if (element) {
        let ckEditorElement = CKEDITOR.replace(`basic_template_edit${filter.id}`, {
          language: I18n.currentLocale(),
          removePlugins: 'elementspath',
          resize_enabled: false
        });
      }
    })
  }
  $(document).ready(function () {
    var element = document.getElementById('basic_template_text');
    if (element) {
      var ckEditorElement = CKEDITOR.replace('basic_template_text', {
        language: I18n.currentLocale(),
        removePlugins: 'elementspath',
        resize_enabled: false
      });

      self.ckEditor = ckEditorElement;
    }
  })
}


SharedViews.BasicTemplates.prototype = SharedViews;
