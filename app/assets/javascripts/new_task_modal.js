
$(document).ready(function () {

    /**
     * Makes requests to server for Service channels agents emails
     */
    var agentsSearchingRequest = new QueryThrottler(
        {
            timeout: 350,
            query: function (keyword, q_url) {
                return $.ajax({
                    url: q_url,
                    data: {q: keyword},
                    dataType: 'json'
                })
            },
            beforeSend: function () {
                newTaskModalViewModel.loadingState('loading');
            },
            done: function (data) {
                newTaskModalViewModel.agentsInModal([]);
                _.forEach(data, function (res, key) {
                    newTaskModalViewModel.agentsInModal.push(new AgentsResult(res));
                });
                newTaskModalViewModel.agentsInModal.sort( function(left, right) {
                    return left.email.toLowerCase() == right.email.toLowerCase()
                        ? 0
                        : (left.email.toLowerCase() < right.email.toLowerCase() ? -1 : 1);
                });
            }
        });

    /**
     * This class populates data from server response
     * @param data email string
     * @constructor make email property from email string
     */
    function AgentsResult(data) {
        var self = this;
        this.email = data;
    }

    /**
     * KnockoutJS model
     */
    function NewTaskModalViewModel() {
        var self = this;
        this.loadingState = ko.observable('select');
        this.agents_by_service_channel_id_query_url = "/tasks/get_agents_by_service_channel_id";
        this.allEmailsCheckbox = ko.observable(false);
        this.emailsToSend = ko.observable(''); // Hidden field
        this.chosenAgents = ko.observableArray([]);
        this.agentsInModal = ko.observableArray([]);
        this.mediaChannel = ko.observable('');
        this.showCallFields = ko.observable(false);
        this.showEmailFields = ko.observable(false);
        this.templateText = ko.observable();
        this.companyFiles = ko.observableArray([]);
        this.isSoftfoneTicket = ko.observable(false);

        $('#afterStopButton').on('click', function() {
            self.isSoftfoneTicket(true);
        })

        this.replaceMessageTextBodyWith = function(text=''){
          CKEDITOR.instances['task_messages_attributes_0_description'].setData('');
          setTimeout(function(){
            CKEDITOR.instances['task_messages_attributes_0_description'].setData(text);
          }, 100)
        }

        this.setTextFromTemplate = function(){
          this.replaceMessageTextBodyWith(this.templateText())
        }

        self.emailCheckboxClicked = function(checkbox, event) {
            event.target.checked ?
                self.chosenAgents.push(checkbox) :
                self.chosenAgents.remove(checkbox);

            return true; // For default behaviour in browser
        };

        /**
         * Remove all from arrays: chosenAgents and agentsInModal,
         * make hidden emailToSend field blank and set loadingState
         */
        self.resetAgents = function() {
            self.chosenAgents.removeAll();
            self.agentsInModal.removeAll();
            self.emailsToSend('');
            self.loadingState('select');
        };

        /**
         * Listen if allEmailsCheckbox is checked.
         * Put all agentsInModal to chosenAgents if checked. Remove all otherwise
         */
        self.allEmailsCheckbox.subscribe(function(updated) {
            updated ?
                self.chosenAgents(self.agentsInModal.slice(0)) :
                self.chosenAgents([]);
        });

        /**
         * Listen to chosenAgents and populate hidden string on change
         */
        self.chosenAgents.subscribe(function() {
            self.emailsToSend("");
            if (self.chosenAgents().length > 0) {
                var finalString= "";
                var agents_len = self.chosenAgents().length;

                for (var index = 0; index < agents_len; index++) {
                    var agent = self.chosenAgents()[index];
                    finalString += agent.email;
                    if (index != agents_len - 1)
                        finalString += ", ";
                }
                self.emailsToSend(finalString);
            }
        });

        this.addCompanyFile = function (file) {
            self.companyFiles.push(file);
        }
        
        this.removeCompanyFile = function () {
            self.companyFiles.remove(this);
        }
        this.showFilesModal = function () {
            window.userDashboardApp.viewModels.selectCompanyFilesModal.showModal({afterAddFile: self.addCompanyFile})
        }
        
        this.clearCompanyFiles = function () {
            self.companyFiles([]);
        }
          
        $('#new_task_modal').on('hide.bs.modal', function () {
            self.isSoftfoneTicket(false);
            self.clearCompanyFiles();
        })
    }

    var newTaskModalViewModel = new NewTaskModalViewModel();
    window.newTaskModal = newTaskModalViewModel;

    // Put jquery on change for updating agents in NewTaskModalViewModel when service channel changed
    $('#task_service_channel_id').on('change', function(event) {
        media_channel = $('#task_media_channel_id', event.target.form)
        if (media_channel === undefined || media_channel[0].value !== 'MediaChannel::Internal') {
            newTaskModalViewModel.resetAgents(); // Reset agents if service channel changed
            var value = $('#task_service_channel_id').find(":selected").val();
            if (value) {
                agentsSearchingRequest.query(value, newTaskModalViewModel.agents_by_service_channel_id_query_url);
                $('#task_media_channel_id').prop('disabled', false);
                $('#task_assigned_to_user_id').prop('disabled', false);
            } else {
                $('#task_media_channel_id').prop('disabled', true);
                $('#task_assigned_to_user_id').prop('disabled', true);
            }
        }
    });
    $('#task_media_channel_id').on('change', function() {
        newTaskModalViewModel.resetAgents(); // Reset agents if media channel changed
        switch($('#task_media_channel_id').val()) {
          case 'MediaChannel::Call':
            newTaskModalViewModel.showCallFields(true);
            newTaskModalViewModel.showEmailFields(false);
            break;
          case 'MediaChannel::Email':
            newTaskModalViewModel.showCallFields(false);
            newTaskModalViewModel.showEmailFields(true);
            break;
          case 'MediaChannel::WebForm':
            newTaskModalViewModel.showCallFields(false);
            newTaskModalViewModel.showEmailFields(true);
            break;
          default:
            newTaskModalViewModel.showCallFields(false);
            newTaskModalViewModel.showEmailFields(false);
        };
    });

});
