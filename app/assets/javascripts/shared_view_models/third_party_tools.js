SharedViews.ThirdPartyTools = function () {
  let self = this;
  this.disable_controlls = ko.observable(false);
  this.toolsList = ko.observableArray([]);
  this.setTimeOut = {};
  this.toolTitle = ko.observable("")
  this.selectedTool = ko.observable(null);
  this.toolsFilter = ko.observable("")
  this.ckEditor = null;

    this.filteredTools = ko.computed(function () {
    let filteredList = self.toolsList().filter(function (obj) {
      return (obj.title.toLocaleLowerCase().includes(self.toolsFilter().toLocaleLowerCase()) ||
        obj.content.toLocaleLowerCase().includes(self.toolsFilter().toLocaleLowerCase()));
    });
    return filteredList;
  })


  this.showStatus = function (msg, selector) {
    $(selector).addClass("hide")
    clearTimeout(self.setTimeOut[selector]);
    if (msg) {
      $(selector).removeClass("hide");
      $(selector).text(msg);
      self.setTimeOut[selector] = setTimeout(function () {
        $(selector).addClass("hide")
      }, 5000);
    }
  };

  this.fetchAllTools = function () {
    this.disable_controlls(true);
    $.ajax({
      url: "/" + I18n.locale + "/third_party_tools",
      dataType: "json",
      success: function (response) {
        self.disable_controlls(false);
        self.toolsList(response);
      },
    });
  };

  this.fetchAllTools();

  this.createTools = function () {
    let data = {third_party_tool: {title: self.toolTitle(), content: self.ckEditor.getData()}};
    this.disable_controlls(true);
    $.ajax({
      url: "/" + I18n.locale + "/third_party_tools",
      dataType: 'json',
      method: "post",
      data: data,
      success: function (response) {
        self.disable_controlls(false);
        if (response.errors) {
          self.showStatus(response.errors, "#third_party_tools_error");
        } else {
          self.showStatus(response.success, "#third_party_tools_success");
          self.fetchAllTools();
          self.toolTitle("");
          self.ckEditor.setData("");
        }
      },
    });
  };

  this.updateTool = function () {
    let data = {third_party_tool: this};
    let editor = CKEDITOR.instances[`third_party_tool${this.id}`]
    data.third_party_tool.content = editor.getData();
    self.disable_controlls(true);
    $.ajax({
      url: "/" + I18n.locale + `/third_party_tools/${this.id}`,
      dataType: 'json',
      method: "PUT",
      data: data,
      success: function (response) {
        self.disable_controlls(false);
        if (response.errors) {
          self.showStatus(response.errors, "#third_party_tools_error");
        } else {
          self.showStatus(response.success, "#third_party_tools_success");
          self.fetchAllTools();
        }
      },
    });
  };
  this.deleteTool = function () {
    changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete)
    if (changed == false) {
      return
    }
    self.disable_controlls(true);
    $.ajax({
      url: "/" + I18n.locale + `/third_party_tools/${this.id}`,
      dataType: 'json',
      method: "DELETE",
      success: function (response) {
        self.disable_controlls(false);
        if (response.errors) {
          self.showStatus(response.errors, "#third_party_tools_error");
        } else {
          self.showStatus(response.success, "#third_party_tools_success");
          self.fetchAllTools();
        }
      },
    });
  };

  this.reinitializeCkEditors = function () {
    self.toolsList().forEach((tool) => {
      var editor = CKEDITOR.instances[`third_party_tool${tool.id}`];
      if (editor) {
        editor.destroy(true);
      }
      var element = document.getElementById(`third_party_tool${tool.id}`);
      if (element) {
        let ckEditorElement = CKEDITOR.replace(`third_party_tool${tool.id}`, {
          language: I18n.currentLocale(),
          removePlugins: 'elementspath',
          resize_enabled: false
        });
      }
    })
  }

  this.setSelectedTool = function () {
    self.selectedTool(this)
    $("#third_party_tools_modal").modal();
  }

    $(document).ready(function () {
    var element = document.getElementById('new_third_party_tool');
    if (element) {
      var ckEditorElement = CKEDITOR.replace('new_third_party_tool', {
        language: I18n.currentLocale(),
        removePlugins: 'elementspath',
        resize_enabled: false
      });

      self.ckEditor = ckEditorElement;
    }
  })


}
SharedViews.ThirdPartyTools.prototype = SharedViews;
