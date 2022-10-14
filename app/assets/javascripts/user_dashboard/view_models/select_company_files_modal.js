Views.SelectCompanyFilesViewModel = function(){
  let self = this;
  this.afterAddCallback = null;
  this.files = ko.observableArray([]);
  this.filesFilter = ko.observable('');

  this.filteredFilesList = ko.computed(function () {
    return self.files().filter(function (obj) {
      return (obj.file_name.toLocaleLowerCase().includes(self.filesFilter().toLocaleLowerCase()));
    });
  })

  this.showModal = function(options= {}){
    $("#file_select_modal_dialog").modal();
    if (options.afterAddFile){
      self.afterAddCallback = options.afterAddFile;
    }
    else{
      self.afterAddCallback = null;
    }
  }

  this.addFile = function(file){
    if (self.afterAddCallback)
    {
      $("#file_select_modal_dialog").modal('hide');
      self.afterAddCallback(file)
    }
  }

  this.getAllFiles = function(){
    $.ajax({
      url: '/' + I18n.locale + "/company_files",
      method: 'GET',
      contentType: 'application/json',
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
  this.getAllFiles();
}
Views.SelectCompanyFilesViewModel.prototype = Views;
