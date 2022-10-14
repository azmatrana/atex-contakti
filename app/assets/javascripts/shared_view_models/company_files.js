SharedViews.CompanyFileViewModel = function() {
  var self = this;
  this.files = ko.observableArray([]);
  this.uploadedFiles = ko.observableArray([]);
  this.setTimeOut = {};
  this.filesFilter = ko.observable('');

  this.filteredFilesList = ko.computed(function () {
    return self.files().filter(function (obj) {
      return (obj.file_name.toLocaleLowerCase().includes(self.filesFilter().toLocaleLowerCase()));
    });
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

  this.fetchAllFiles = function(){
    $.ajax({
      url: '/' + I18n.locale + "/company_files",
      method: 'GET',
      processData: false,
      contentType: false,
      success: function (resp) {
        self.files.destroyAll()
        resp.forEach((f)=>{
          self.files.push(f);
        })
      },
      error: function (response) {
        alert("errror");
      }
    });

  }

  this.uploadFiles = function (){
    var form = $('#company_files_upload_form');
    var formData = new FormData(form[0]);
    $.ajax({
      url: '/' + I18n.locale + "/company_files",
      method: 'POST',
      processData: false,
      contentType: false,
      data: formData,
      success: function (resp) {
        self.showStatus(resp.success, "#file_success")
        self.fetchAllFiles();
        $('#company_file_input').val('');
      },
      error: function (resp) {
        let errors = $.parseJSON(resp.responseText).errors
        self.showStatus(errors, "#file_error")
      }
    });
  }
  this.deleteFile = function(file_id){
    let changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete)
    if (changed == false) {
      return;
    }
    $.ajax({
      url: '/' + I18n.locale + "/company_files/" + file_id,
      method: 'DELETE',
      success: function (resp) {
        self.showStatus(resp.success, "#file_success")
        self.fetchAllFiles();
      },
      error: function (resp) {
        self.showStatus(resp.errors, "#file_error")
      }
    });
  }
  this.fetchAllFiles();
}
SharedViews.CompanyFileViewModel.prototype = SharedViews;
