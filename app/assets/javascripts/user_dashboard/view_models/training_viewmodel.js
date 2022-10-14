Views.TrainingViewModel = function () {
  var self = this;
  this.rowspan = ko.observable(2);
  this.intents = ko.observableArray([]);
  this.questionFilter = ko.observable("");
  this.answerFilter = ko.observable("");
  this.intentFilter = ko.observable("");
  this.entityFilter = ko.observable("");
  this.entityName = ko.observable("");
  this.keyWordText = ko.observable("");
  this.new_intent_text = ko.observable("");
  this.selected_intent_id = ko.observable(null)
  this.new_question = ko.observable("");
  this.new_intent = ko.observable(null);
  this.new_answer = ko.observable("");
  this.selected_answer_intent = ko.observable("");
  this.disable_controlls = ko.observable(true);
  this.answers_query = ko.observable("");
  this.questionTemplatesFilter = ko.observable("");

  this.questionsList = ko.observableArray([]);
  this.answersList = ko.observableArray([]);
  this.synonymsList = ko.observableArray([]);
  this.entitiesList = ko.observableArray([]);
  this.questionTemplatesList = ko.observableArray([]);
  this.answerFile = ko.observable(null);

  this.createdEntity = ko.observable(null);
  this.lastKeywordId = 2;

  this.delete_answer_id = ko.observable();
  this.setTimeOut = {}
  this.customActionFlag = ko.observable(false);
  this.customActionText = ko.observable('');
  this.answerButtons = ko.observableArray([]);
  this.selectedProduct = ko.observable(null);
  this.selectedProductsDataArray = ko.observableArray([]);
  this.selectedAnswer = ko.observable(null)
  this.selectedProductsArray = ko.computed(function () {
    return self.selectedProductsDataArray().map((p) => {
      return p.id
    })
  })

  this.answerImages = ko.observableArray([]);
  this.selectedProduct.subscribe(function(newProduct){
    if(!newProduct || self.selectedProductsArray().includes(newProduct.id) ){
      return
    }
    self.selectedProductsDataArray.push(newProduct);
    self.selectedProduct(null);
  })

  this.filteredQuestionsList = ko.computed(function () {
    return self.questionsList().filter(function (obj) {
      return (obj.text.toLocaleLowerCase().includes(self.questionFilter().toLocaleLowerCase()));
    }).sort(function(a,b) {
      var x = a.intent.text.toLowerCase();
      var y = b.intent.text.toLowerCase();
      return x < y ? -1 : x > y ? 1 : 0;
    });
  })

  this.filteredAnswersList = ko.computed(function () {
    return self.answersList().filter(function (obj) {
      return (obj.text.toLocaleLowerCase().includes(self.answerFilter().toLocaleLowerCase()));
    }).sort(function(a,b) {
      var x = a.intent.text.toLowerCase();
      var y = b.intent.text.toLowerCase();
      return x < y ? -1 : x > y ? 1 : 0;
    });
  })

  this.sortedIntents = ko.computed(function () {
    return self.intents().sort(function(a,b) {
      var x = a.text.toLowerCase();
      var y = b.text.toLowerCase();
      return x < y ? -1 : x > y ? 1 : 0;
    });
  });

  this.filteredIntentsList = ko.computed(function () {
    return self.intents().filter(function (obj) {
      return (obj.text.toLocaleLowerCase().includes(self.intentFilter().toLocaleLowerCase()));
    }).sort(function(a,b) {
      var x = a.text.toLowerCase();
      var y = b.text.toLowerCase();
      return x < y ? -1 : x > y ? 1 : 0;
    });
  });

  this.filteredQuestionTemplatesList = ko.computed(function () {
    return self.questionTemplatesList().filter(function (obj) {
      return (obj.text.toLocaleLowerCase().includes(self.questionTemplatesFilter().toLocaleLowerCase()));
    }).sort(function(a,b) {
      var x = a.text.toLowerCase();
      var y = b.text.toLowerCase();
      return x < y ? -1 : x > y ? 1 : 0;
    });
  });

  var ckEditorElement = CKEDITOR.replace('answer_create', {
    language: I18n.currentLocale(),
    removePlugins: 'elementspath',
    resize_enabled: false
  });


  this.fetchAllIntents = function () {
    self.disable_controlls(true)
    $.ajax({
      url: '/intents',
      dataType: 'json',
      success: function (data) {
        self.intents.destroyAll()
        _.forEach(data, function (intent) {
          self.intents.push(intent);
        });
        self.disable_controlls(false)
      }
    });
  }

  this.fetchQuestionsList = function () {
    self.disable_controlls(true)
    $.ajax({
      url: '/questions',
      dataType: 'json',
      success: function (data) {
        self.questionsList.destroyAll()
        _.forEach(data, function (question) {
          self.questionsList.push(question);
        });
        self.disable_controlls(false)
      }
    });
  }

  this.fetchAnswersList = function () {
    self.disable_controlls(true)
    $.ajax({
      url: '/answers',
      dataType: 'json',
      success: function (data) {
        self.answersList.removeAll()
        _.forEach(data, function (answer) {
          _.forEach(answer.images, function (image) {
            image._destroy = ko.observable(false);
          })
           _.forEach(answer.answer_buttons, function (btn) {
            btn._destroy = ko.observable(false);
          })

          self.answersList.push(answer);
        });
        self.disable_controlls(false)
      }
    });
  }


  this.initTokenFieldForSynonyms = function () {
    $('.synonyms').tokenfield({
      autocomplete: {
        source: [],
        delay: 100,
      },
      createTokensOnBlur: true,
      showAutocompleteOnFocus: true
    })
  }


  this.fetchEntitiesList = function () {
    self.disable_controlls(true)
    $.ajax({
      url: '/entities',
      dataType: 'json',
      success: function (data) {
        self.entitiesList.destroyAll()
        _.forEach(data, function (entity) {
          entity["key_words"] = ko.observableArray(entity.key_words)
          _.forEach(entity["key_words"](), function (keyword) {
              keyword.synonyms = keyword.synonyms.join();
            }
          )
          self.entitiesList.push(entity);
        });
        self.disable_controlls(false);
        self.initTokenFieldForSynonyms();
      }
    });
  }

  this.fetchQuestionsList();
  this.fetchAnswersList();
  this.fetchAllIntents();
  this.fetchEntitiesList();
  this.showSuccess = function (success, selector) {
    $(selector).addClass("hide")
    clearTimeout(self.setTimeOut[selector]);
    if (success) {
      $(selector).removeClass("hide");
      $(selector).text(success);
      self.setTimeOut[selector] = setTimeout(function () {
        $(selector).addClass("hide")
      }, 5000);

    }
  };
  this.showErrors = function (error, selector) {
    $(selector).addClass("hide");
    clearTimeout(self.setTimeOut[selector]);
    if (error && error.length > 0) {
      $(selector).removeClass("hide");
      $(selector).text(error);
      self.setTimeOut[selector] = setTimeout(function () {
        $(selector).addClass("hide");
      }, 5000);
    }
  }

  this.createNewIntent = function () {
    const intent_data = {text: self.new_intent_text()};
    self.disable_controlls(true)
    $.ajax({
      url: '/' + I18n.locale + '/intents',
      dataType: 'json',
      method: "post",
      data: intent_data,
      success: function (response) {
        if (response.errors) {
          self.showErrors(response.errors, "#data_warning_alert");
        } else {
          self.showSuccess(response.success, "#data_saved_alert");
          self.new_intent_text('');
          if (!response.present_already) {
            self.intents.push(response.data);
          }
          self.selected_intent_id(response.data.id);
        }
        self.disable_controlls(false)
      }
    });
  }

  this.createQuestion = function () {
    if (!self.selected_intent_id()) {
      self.showErrors(window.I18n.translations[window.I18n.locale].user_dashboard.training.no_intent_selected, "#data_warning_alert")
    } else {
      const question_data = {
        text: self.new_question(),
        intent_attributes: {intent_id: self.selected_intent_id()}
      };
      self.disable_controlls(true)
      $.ajax({
        url: '/' + I18n.locale + '/questions',
        dataType: 'json',
        method: "post",
        data: question_data,
        success: function (response) {
          if (response.errors) {
            self.showErrors(response.errors, "#data_warning_alert");

          } else {
            self.showSuccess(response.success, "#data_saved_alert");
            self.fetchQuestionsList()
            self.new_question('');
            self.selected_intent_id(null);
          }
          self.disable_controlls(false)
        }
      });
    }
  }

  this.createAnswer = function () {
    let answerId = self.selectedAnswer();
    let formParentElSelector = answerId ? "#answer_edit" : "#answer_create"
    let answer_images_input  = formParentElSelector + "_images_input";
    let answer_success_div   = formParentElSelector + "_success";
    let answer_warning_div     = formParentElSelector + "_warning";

    const answer_images = $(answer_images_input)[0].files;
    var data = new FormData();
    if(self.selectedAnswer()){
      data.append(`answer[id]`, answerId);
    }
    let index = 0;
    $.each(self.answerImages(), function (i, img) {
        data.append(`answer[images_attributes][${i}][id]`, img.id);
        data.append(`answer[images_attributes][${i}][_destroy]`, img._destroy());
        index = i;
    });
    $.each(answer_images, function (j, img) {
      data.append(`answer[images_attributes][${index + 1 + j}][file]`, img);
    });
    data.append("answer[text]", ckEditorElement.getData());
    data.append("answer[intent_id]", self.selected_answer_intent());
    data.append( "answer[has_custom_action]", self.customActionFlag() );
    data.append( "answer[custom_action_text]", self.customActionText() );
    $.each(self.answerButtons(), function (i, answerButton) {
      data.append(`answer[answer_buttons_attributes][][text]`, answerButton["text"]);
      data.append(`answer[answer_buttons_attributes][][hyper_link]`, answerButton["hyper_link"]);
      data.append(`answer[answer_buttons_attributes][][_destroy]`, answerButton._destroy());
      if(answerButton.id){
        data.append(`answer[answer_buttons_attributes][][id]`, answerButton.id);
      }
    });
    $.each(self.selectedProductsArray(), function (i, product) {
      data.append( "answer[product_ids][]", product );
    });
    if (self.answerFile()) {
      data.append("answer[company_file_ids][]", self.answerFile().id);
    }

    self.disable_controlls(true)
    $.ajax({
      url: '/' + I18n.locale + '/answers/create_or_update',
      type: 'POST',
      contentType: false,
      processData: false,
      data: data,
      success: function (response) {
        if (response.errors) {
          self.showErrors(response.errors, answer_warning_div);
        } else {
          self.showSuccess(response.success, answer_success_div);
          console.log(data);
          self.fetchAnswersList();
          self.clearVariables()
        }
        self.disable_controlls(false)
      }
    });
  }

  this.deleteQuestion = function (questionId) {
    changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete)
    if (changed == false) {
      return
    }
    self.disable_controlls(true);
    $.ajax({
      url: '/' + I18n.locale + '/questions/' + questionId,
      type: 'DELETE',
      success: function (response) {
        if (response.errors) {
          self.showErrors(response.errors, "#question_delete_error");
        } else {
          console.log(response);
          self.showSuccess(response.success, "#question_delete_success");
        }
        self.disable_controlls(false)
        self.fetchQuestionsList()
        self.fetchAllIntents()
        self.fetchAnswersList()
      }
    });

  }

  this.deleteAnswer = function (answerId) {
    changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete)
    if (changed == false) {
      return
    }
    self.disable_controlls(true)
    $.ajax({
      url: '/' + I18n.locale + '/answers/' + answerId,
      type: 'DELETE',
      success: function (response) {
        if (response.errors) {
          self.showErrors(response.errors, "#answer_delete_error");
        } else {
          console.log(response);
          self.showSuccess(response.success, "#answer_delete_success");
        }
        self.disable_controlls(false)
        self.fetchAnswersList()
      }
    });
  }
  this.addFileToAnswer = function(file){
    self.answerFile(file);
  }
  this.removeFileFromCreateAnswer = function(){
    self.answerFile(null);
  }

  this.showFilesModal = function(answerId){
    window.userDashboardApp.viewModels.selectCompanyFilesModal.showModal({afterAddFile: self.addFileToAnswer})
  }


  this.deleteIntent = function (intentId) {
    changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete)
    if (changed == false) {
      return
    }
    self.disable_controlls(true);
    $.ajax({
      url: '/' + I18n.locale + '/intents/' + intentId,
      type: 'DELETE',
      success: function (response) {
        if (response.errors) {
          self.showErrors(response.errors, "#intent_delete_error");
        } else {
          console.log(response);
          self.showSuccess(response.success, "#intent_delete_success");
        }
        self.disable_controlls(false)
        self.fetchAnswersList();
        self.fetchAllIntents();
        self.fetchQuestionsList();
      }
    });
  }
  this.createEntity = function () {
    const entity_data = {
      name: self.entityName()
    };
    self.disable_controlls(true);
    $.ajax({
      url: '/' + I18n.locale + '/entities',
      dataType: 'json',
      method: "post",
      data: entity_data,
      success: function (response) {
        if (response.errors) {
          self.showErrors(response.errors, "#entity_error");
          self.entityName('');
          self.entityFilter('');
        } else {
          self.showSuccess(response.success, "#entity_success");
          console.log(response.data);
          self.fetchEntitiesList();
        }
        self.disable_controlls(false);
      }
    });

  }

  this.saveEntity = function (data) {
    const key_words_array = data.key_words().map(k => {
      return {keyword: k.keyword, synonyms: k.synonyms}
    })// deep copy synonyms data
    const entity = {
      id: data.id,
      name: data.name,
      key_words: [...key_words_array]
    }
    let valid = true;
    if (entity.key_words) {
      entity.key_words.forEach(k => {
        if (k.keyword.length > 1) {
          k.synonyms = k.synonyms.split(",");
        } else {
          valid = false;
          self.showErrors(window.I18n.translations[window.I18n.locale].user_dashboard.training.keyword_empty, "#entity_error")
        }
      })
      if (valid === false) {
        return;
      }
      self.disable_controlls(true);
      $.ajax({
        url: '/' + I18n.locale + '/entities/' + data.id,
        dataType: 'json',
        method: 'PATCH',
        data: entity,
        success: function (response) {
          if (response.errors) {
            self.showErrors(response.errors, "#entity_error");
          } else {
            self.fetchEntitiesList();
            self.showSuccess(response.success, "#entity_success");
            console.log(response.data);
          }
          self.disable_controlls(false);
        }
      });
    } else {
      self.showErrors(window.I18n.translations[window.I18n.locale].user_dashboard.training.no_keyword, "#entity_error")
    }
  }

  this.addKeyWord = function (item, event) {
    let id = item.id;
    self.lastKeywordId++;
    let key_word = {id: self.lastKeywordId, keyword: "", synonyms: ""};
    item.key_words.push(key_word);
    self.initTokenFieldForSynonyms();
  }

  this.deleteEntity = function(entityId){
    changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete)
    if (changed == false) {
      return;
    }
    self.disable_controlls(true);
    $.ajax({
      url: '/' + I18n.locale + '/entities/' + entityId,
      type: 'DELETE',
      success: function (response) {
        if (response.errors) {
          self.showErrors(response.errors, "#entity_error");
        } else {
          self.showSuccess(response.success, "#entity_success");
        }
        self.disable_controlls(false);
        self.fetchEntitiesList();
      }
    });
  }

  this.fetchQuestionTemplates = function(){
    self.disable_controlls(true)
    $.ajax({
      url: '/question_templates',
      dataType: 'json',
      success: function (data) {
        self.questionTemplatesList.destroyAll()
        _.forEach(data, function (template) {
          template.intent_id = ko.observable(null);
          self.questionTemplatesList.push(template);
        });
        self.disable_controlls(false)
      }
    });
  }
  this.fetchQuestionTemplates();

  this.deleteQuestionTemplate = function (templateId){
   let changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete)
    if (changed === false) {
      return;
    }
    self.disable_controlls(true)
    $.ajax({
      url: '/' + I18n.locale + '/question_templates/' + templateId,
      type: 'DELETE',
      success: function (response) {
        if (response.errors) {
          self.showErrors(response.errors, "#template_delete_error");
        } else {
          self.showSuccess(response.success, "#template_delete_success");
        }
        self.disable_controlls(false);
        self.fetchQuestionTemplates();
      }
    });
  }

  this.subscribeToUnderstandings = function(){
    $.ajax({
      url: '/question_templates/subscribe_to_danthes',
      method: 'get',
      success: function (sub) {
          Danthes.sign(_.extend(sub, {
            callback: function(data){
              data.intent_id = ko.observable(null);
              self.questionTemplatesList.push(data);
            },
            connect: true
          }));
      }
    })
  }

  this.subscribeToUnderstandings();

   this.deleteAllQuestionTemplates = function(){
     let changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete);
     if (changed === false) {
       return;
     }
     self.disable_controlls(true)
     $.ajax({
       url: '/' + I18n.locale + '/question_templates/destroy_all',
       type: 'DELETE',
       success: function (response) {
         if (response.errors) {
           self.questionTemplatesFilter("");
           self.showErrors(response.errors, "#template_delete_error");
         } else {
           self.showSuccess(response.success, "#template_delete_success");
         }
         self.disable_controlls(false);
         self.fetchQuestionTemplates();
       }
     });
   }

   this.addAnswerButton = function (){
     self.answerButtons.push({text: "", hyper_link: "", _destroy: ko.observable(false)});
   }
  this.removeAnswerButton = function () {
     this._destroy(true)
    // self.answerButtons.remove(this);
  }

  this.removeProduct = function(){
    self.selectedProductsDataArray.remove(this);
  }

  this.saveQuestionTemplate = function () {
    if (!this.intent_id()) {
      self.showErrors(window.I18n.translations[window.I18n.locale].user_dashboard.training.intent_empty, "#template_delete_error")
    } else {
      const understanding_data = {
        id: this.id,
        intent_id: this.intent_id()
      };
      self.disable_controlls(true)
      $.ajax({
        url: '/' + I18n.locale + '/question_templates/create_question_from_template',
        dataType: 'json',
        method: "post",
        data: understanding_data,
        success: function (response) {
          if (response.errors) {
            self.showErrors(response.errors, "#template_delete_error");

          } else {
            self.showSuccess(response.success, "#template_delete_success");
            self.fetchQuestionsList()
            self.fetchQuestionTemplates()
          }
          self.disable_controlls(false)
        }
      });
    }
  }

  this.selectAnswerForEdit = function () {
    var editor = CKEDITOR.instances["answer_edit"];
    if (editor) {
      editor.destroy(true);
    }
    ckEditorElement = CKEDITOR.replace('answer_edit', {
      language: I18n.currentLocale(),
      removePlugins: 'elementspath',
      resize_enabled: false
    });
    self.selectedAnswer(this.id);
    self.selected_answer_intent(this.intent.id);
    self.customActionFlag(this.has_custom_action);
    self.customActionText(this.custom_action_text);
    self.answerButtons(this.answer_buttons);
    self.answerFile(this.company_files[0]);
    self.selectedProductsDataArray(this.products);
    self.selectedProduct(null);
    self.answerImages(this.images);
    ckEditorElement.setData(this.text);
    $("#answer_edit_modal").modal();
  }

  this.removeImageFromAnswer = function () {
    this._destroy(true);
  }

  this.clearVariables = function () {
    let formParentElSelector = self.selectedAnswer() ? "#answer_edit" : "#answer_create"
    let answer_images_input  = formParentElSelector + "_images_input";
    self.selectedAnswer(null);
    self.selected_answer_intent(null);
    self.new_answer('');
    self.customActionFlag(false);
    self.customActionText("");
    self.answerButtons([]);
    self.answerFile(null);
    self.selectedProductsDataArray([]);
    self.selectedProduct(null);
    self.answerImages([]);
    $(answer_images_input).val("");
    ckEditorElement.setData("");
    var editor = CKEDITOR.instances["answer_create"];
    if (editor) {
      editor.destroy(true);
    }
    ckEditorElement = CKEDITOR.replace('answer_create', {
      language: I18n.currentLocale(),
      removePlugins: 'elementspath',
      resize_enabled: false
    });
  }

  $(document).ready(function () {
    window.addEventListener("load", self.initTokenFieldForSynonyms);
    $('#answer_edit_modal').on('hide.bs.modal', function () {
      self.clearVariables();
    })
  });
};

Views.TrainingViewModel.prototype = Views;
