// Constructor
ContaktiChat.MessageBox = function() {
};

ContaktiChat.MessageBox.prototype.initialise = function() {
  var self = this;

  if(ContaktiChat.serverUrl.indexOf('http') == -1) {
    ContaktiChat.serverUrl = ContaktiChat.serverProtocol + '://' + ContaktiChat.serverUrl;
  }

  self._bindElements();
};

ContaktiChat.MessageBox.prototype.maximize = function() {
  document.getElementById('contakti-msg-box').style.bottom = '0px';
  document.getElementById('contakti-msg-minimize').classList.remove('hide');
    this.minimized = false;
};


ContaktiChat.MessageBox.prototype._bindElements = function() {
    // var close = document.getElementById('contakti-msg-close');
    var self = this;

    self.minimized = false;
    function minimize()
    {
        var chatBoxHeight = document.getElementById('contakti-msg-box').offsetHeight;
        var headerHeight = document.getElementById('contakti-msg-head').offsetHeight;
        document.getElementById('contakti-msg-box').style.bottom = '-' + (chatBoxHeight - headerHeight) +  'px';
        document.getElementById('contakti-msg-minimize').classList.add('hide');
        self.minimized = true;
    }

    minimize();

    document.getElementById('messagebox-date-field').min = new Date().toISOString().split('T')[0]
    // var picker = new Pikaday({
    //     field: document.getElementById('messagebox-datetime-field'),
    //     trigger: document.getElementById('messagebox-datetime-button'),
    //     position: 'bottom left',
    //     reposition: true,
    //     use24hour: true,
    //     minDate: new Date(),
    //     showButtonPanel: true,
    //     autoClose: false,
    //     format: 'DD.MM.YYYY HH.mm',
    //     i18n: PIKADAY_LOCALES[ContaktiChat.locale]
    // });

    // document.getElementById('contakti-msg-close').onclick = function(event) {
    //     if(!self.minimized) {
    //         minimize();
    //         event.stopPropagation();
    //     }
    // };

    document.getElementById('contakti-msg-minimize').onclick = function(event) {
      if(!self.minimized) {
        minimize();
        event.stopPropagation();
      }
    };

    document.getElementById('contakti-msg-box').onclick = function(event) {
        if(self.minimized) {
            self.maximize();
            event.stopPropagation();
        }
    };

    ['onkeydown','onpaste','oncut', 'onchange', 'oninput'].forEach(function(e){
        ['messagebox-callback-number', 'messagebox-date-field', 'messagebox-time-field', 'messagebox-email', 'messagebox-message'].forEach(function(element) {
            document.getElementById(element)[e] = function() {
                var number = document.getElementById('messagebox-callback-number').value;

                var date = document.getElementById('messagebox-date-field').value;
                var time = document.getElementById('messagebox-time-field').value;
                // var datetime = document.getElementById('messagebox-datetime-field-local').value;
                var email = document.getElementById('messagebox-email').value;
                var message = document.getElementById('messagebox-message').value;

                if((number && date) || (email && message)) {
                        document.getElementById('messagebox-send').disabled = false;
                } else {
                    document.getElementById('messagebox-send').disabled = true;
                }
            };
       });
    });

    document.getElementById('messagebox-send').onclick = function() {
        var button = document.getElementById('messagebox-send');
        if(!button.disabled) {
            var number = document.getElementById('messagebox-callback-number').value;
            // var datetime = document.getElementById('messagebox-datetime-field-local').value;

            var date = document.getElementById('messagebox-date-field').value;
            var time = document.getElementById('messagebox-time-field').value;

            var datetime = '';
            if ( date.length > 0 )
            {
              datetime = new Date(`${date}`);
              if ( time.length > 0){
                datetime = new Date(`${date}T${time}`);
              }
            }

            var email = document.getElementById('messagebox-email').value;
            var message = document.getElementById('messagebox-message').value;

            var url = ContaktiChat.serverUrl + '/chat/' + ContaktiChat.serviceChannel + '/create_callback'
            var req = new XMLHttpRequest();
            req.open('POST', url, true);
            req.setRequestHeader('Content-type', 'application/json');
            req.send(JSON.stringify({number: number, datetime: datetime, email: email, message: message}));

            document.getElementById('contakti-user-name').innerHTML = ContaktiChat.translations.user_dashboard.thanks_chat;
            document.getElementById('contakti-msg-body').innerHTML = '<div style="text-align: center; font-size: 110%; padding-top: 3em">'+ContaktiChat.translations.user_dashboard.sentmessage_chat+'</div>'
        }
    };
};
