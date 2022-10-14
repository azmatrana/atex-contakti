// Constructor
ContaktiChat.SendChatHistoryBox = function() {
};

ContaktiChat.SendChatHistoryBox.prototype.initialise = function() {
  var self = this;

  if(ContaktiChat.serverUrl.indexOf('http') == -1) {
    ContaktiChat.serverUrl = ContaktiChat.serverProtocol + '://' + ContaktiChat.serverUrl;
  }

  self._bindElements();
};

ContaktiChat.SendChatHistoryBox.prototype.maximize = function() {
    document.getElementById('contakti-msg-box').style.bottom = '0px';
  var chatSettingDrowpdown = document.getElementById('chat-setting-dropdown')
  if (chatSettingDrowpdown) {
    document.getElementById('chat-setting-dropdown').style.display = "block";
  }
  document.getElementById('contakti-msg-minimize').classList.remove('hide');
    this.minimized = false;
};


ContaktiChat.SendChatHistoryBox.prototype._bindElements = function() {
    // var close = document.getElementById('contakti-msg-close');
    var self = this;

    self.minimized = false;
    function minimize()
    {
        var chatBoxHeight = document.getElementById('contakti-msg-box').offsetHeight;
        var headerHeight = document.getElementById('contakti-msg-head').offsetHeight;
        document.getElementById('contakti-msg-box').style.bottom = '-' + (chatBoxHeight - headerHeight) +  'px';
        var chatSettingDrowpdown = document.getElementById('chat-setting-dropdown')
        if (chatSettingDrowpdown) {
          document.getElementById('chat-setting-dropdown').style.display = "none";
        }
        document.getElementById('contakti-msg-minimize').classList.add('hide');
        self.minimized = true;
    }

    minimize();

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
        ['send-chat-history-email', 'send-chat-history-message'].forEach(function(element) {
            document.getElementById(element)[e] = function() {
                var email = document.getElementById('send-chat-history-email').value;
                var message = document.getElementById('send-chat-history-message').value;

                if(email && message) {
                        document.getElementById('send-chat-history-send').disabled = false;
                } else {
                    document.getElementById('send-chat-history-send').disabled = true;
                }
            };
       });
    });

    document.getElementById('send-chat-history-send').onclick = function() {
        var button = document.getElementById('send-chat-history-send');
        if(!button.disabled) {
            var email = document.getElementById('send-chat-history-email').value;
            var message = document.getElementById('send-chat-history-message').value;

            var url = ContaktiChat.serverUrl + '/chat/' + ContaktiChat.serviceChannel + '/send_email_chat_history'
            var req = new XMLHttpRequest();
            req.open('POST', url, true);
            req.setRequestHeader('Content-type', 'application/json');
            req.send(JSON.stringify({email: email, message: message}));
            // if(window.contaktiChatClient.agentPresent) {
            //   if(window.contaktiChatClient.quitSent) return;
            //   window.contaktiChatClient.quitSent = true;
            //   var msg = window.contaktiChatClient.messageFactory.quitMessage();
            //   var http_req = new XMLHttpRequest();
            //   http_req.open('POST', window.contaktiChatClient._channelUrl(), false);
            //   http_req.setRequestHeader('Content-type', 'application/json');
            //   http_req.send(msg.asJSON());
            // } else {
            //   if(window.contaktiChatClient.chatChannel) {
            //     var http_req = new XMLHttpRequest();
            //     http_req.open('GET', ContaktiChat.serverUrl + '/chat/' + ContaktiChat.serviceChannel + '/abort_chat?channel_id=' + encodeURIComponent(window.contaktiChatClient.chatChannel), true);
            //     http_req.setRequestHeader('Content-type', 'application/json');
            //     http_req.send();
            //   }
            // }

            var container = document.getElementById('chat-client-container').value;
            var dropdown_menu = document.getElementById('chat-setting-dropdown-menu');
            var mainContainer = document.getElementById('contakti-chat-container');
            mainContainer.innerHTML = ContaktiChat.chatBox;
            document.getElementById('contakti-msg-box').innerHTML = container;
            document.getElementById('chat-setting-dropdown-menu').innerHTML = dropdown_menu.innerHTML;
            window.contaktiChatClient.initialise();
            window.contaktiChatClient.maximize();
            // document.getElementById('contakti-user-name').innerHTML = ContaktiChat.translations.user_dashboard.thanks_chat;
            // document.getElementById('contakti-msg-body').innerHTML = '<div style="text-align: center; font-size: 110%; padding-top: 3em">'+ContaktiChat.translations.user_dashboard.chat_history_send+'</div>'
        }
    };

    document.getElementById('send-chat-history-cancel').onclick = function(event) {
      // debugger;
        // var message = document.getElementById('send-chat-history-message').value;
        var container = document.getElementById('chat-client-container').value;
        var dropdown_menu = document.getElementById('chat-setting-dropdown-menu');
        // ContaktiChat.ChatClient.prototype._quitChat();
        var mainContainer = document.getElementById('contakti-chat-container');
        mainContainer.innerHTML = ContaktiChat.chatBox;
        // ContaktiChat.start()
        // window.contaktiChatClient = new ContaktiChat.ChatClient();
        document.getElementById('contakti-msg-box').innerHTML = container;
        document.getElementById('chat-setting-dropdown-menu').innerHTML = dropdown_menu.innerHTML;
        window.contaktiChatClient.initialise();

        window.contaktiChatClient.maximize();
    }

    document.getElementById('download_chat_history').onclick = function(event) {
      var newString = document.getElementById('send-chat-history-message').value
      var element = document.createElement('a');
      element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(newString));
      element.setAttribute('download', 'chat_history.txt');

      element.style.display = 'none';
      document.body.appendChild(element);

      element.click();

      document.body.removeChild(element);
    }

    document.getElementById('send_chat_history').onclick = function(event){
    }

    document.getElementById('contakti-msg-close-chat').onclick = function(event) {
      // debugger;
      if(window.contaktiChatClient.agentPresent) {
        if(window.contaktiChatClient.quitSent) return;
        window.contaktiChatClient.quitSent = true;
        var msg = window.contaktiChatClient.messageFactory.quitMessage();
        var http_req = new XMLHttpRequest();
        http_req.open('POST', window.contaktiChatClient._channelUrl(), false);
        http_req.setRequestHeader('Content-type', 'application/json');
        http_req.send(msg.asJSON());
      } else {
        if(window.contaktiChatClient.chatChannel) {
          var http_req = new XMLHttpRequest();
          http_req.open('GET', ContaktiChat.serverUrl + '/chat/' + ContaktiChat.serviceChannel + '/abort_chat?channel_id=' + encodeURIComponent(window.contaktiChatClient.chatChannel), true);
          http_req.setRequestHeader('Content-type', 'application/json');
          http_req.send();
        }
      }
      document.getElementById('contakti-msg-close-chat').style.display = "none";
      document.getElementById('contakti-msg-start-chat').style.display = "block";
      // document.getElementById('contakti-chat-container').innerHTML = '';
      // var mainContainer = document.getElementById('contakti-chat-container');
      // mainContainer.innerHTML = ContaktiChat.chatBox;
      // ContaktiChat.start()
    };

    document.getElementById('contakti-msg-start-chat').onclick = function(event) {
      document.getElementById('contakti-chat-container').innerHTML = '';
      var mainContainer = document.getElementById('contakti-chat-container');
      mainContainer.innerHTML = ContaktiChat.chatBox;
      document.getElementById('contakti-msg-close-chat').style.display = "block";
      document.getElementById('contakti-msg-start-chat').style.display = "none";
      ContaktiChat.start();
    }

};
