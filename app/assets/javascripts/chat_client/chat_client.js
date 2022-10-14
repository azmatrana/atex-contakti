// Constructor
localStorage.removeItem('indicator_state')
ContaktiChat.ChatClient = function() {
  this.chatChannel = null;
  this.fayeServer = null;
  this.messageContainer = document.getElementById('contakti-msg-body');
  this.username = '';
  this.email = '';
  this.phone = '';
  this.messageFactory = new ContaktiChat.ChatMessageFactory({ username: this.username, channel: this.channel, email: this.email, phone: this.phone });
  this.quitSent = false;
  this.messageCame = false;
  this.agentPresent = false;
  this.agentsCount = 0;
  this.connectTimeout = 0;
  this.started = false;
  this.replyProducts = [];
};

ContaktiChat.ChatClient.prototype.initialise = function() {
  var self = this;

  if(ContaktiChat.serverUrl.indexOf('http') == -1) {
    ContaktiChat.serverUrl = ContaktiChat.serverProtocol + '://' + ContaktiChat.serverUrl;
  }

  self._bindElements();
  window.onbeforeunload = self._quitChat.bind(self);
};

ContaktiChat.ChatClient.prototype.startChat = function() {
  var self = this;
  if(ContaktiChat.chatWithHuman){
    self.displayNoAgentOnlineScreen();
  }

  var options = "chatbot="+ContaktiChat.chatBotEnabled+"&name="+this.username+"&email="+this.email+"&phone="+this.phone;
  var req = new XMLHttpRequest();
  req.open('GET', ContaktiChat.serverUrl + '/chat/' + ContaktiChat.serviceChannel + '/initiate_chat?'+options, true);
  req.setRequestHeader('Content-type', 'application/json');
  console.log('startChat.....start....', req);
  req.onreadystatechange = this._onStartClientResponse.bind(this, req);
  console.log('startChat.....end....', req);
  req.send();
};

ContaktiChat.ChatClient.prototype.changeFromBotToHumanChat = function(successCallback) {
  var self = this;
  ContaktiChat.chatBotEnabled = false;
  var options = "chatbot="+false+"&name="+this.username+"&email="+this.email+"&phone="+this.phone+"&channel_id=" + encodeURIComponent(this.chatChannel);
  var req = new XMLHttpRequest();
  req.open('GET', ContaktiChat.serverUrl + '/chat/' + ContaktiChat.serviceChannel + '/bot_initiate_human_chat?'+options, true);
  req.setRequestHeader('Content-type', 'application/json');
  console.log('startChat.....start....', req);
  // req.onreadystatechange = this._onStartClientResponse.bind(this, req);
  console.log('startChat.....end....', req);

  req.send();
  ContaktiChat.chatWithHuman = true;
  req.onreadystatechange = function(){
    if (req.readyState === 4){
      let data = JSON.parse(req.responseText)
      successCallback(data);
    }
  }
};

ContaktiChat.ChatClient.prototype._onStartClientResponse = function(req) {
  if(req.readyState != 4)  // 4: request finished and response is ready
    return;
  var self = this;
  if ( ContaktiChat.initialMsg.length > 0){
    this.messageContainer.innerHTML += ("<div class='msg_n'>"+ ContaktiChat.initialMsg +"</div>");
  }
  console.log('onStartClientResponse.........', req);
  var response = JSON.parse(req.responseText);

  if( (!this.agentPresent) && ContaktiChat.chatWithHuman){
      this._setSendDisabled()
  }
  response.callback = this._onMessageReceived.bind(this);
  response.connect = true;
  this.chatChannel = response.channel;
  this.fayeServer = response.server;
  Danthes.sign(response);
  // Set client info in redis to use when client closes or reloads the chat.
  setTimeout(function () {
    const url = ContaktiChat.serverUrl + `/chat/set_client_info?channel_id=${self.chatChannel}`
    fetch(url,{
      "Content-Type": "application/json"
    });
  },2000);

};

ContaktiChat.ChatClient.prototype.setUsername = function(name) {
  if (!name) {
    name = 'Anonymous';
  }
  this.username = name;
  this.messageFactory.from = name;
}

function sendCustomActionMessage(e) {
  window.contaktiChatClient._sendMessage(e.target.innerText);
}

function addProductsInReplyProductsList(product){
  if (window.contaktiChatClient.replyProducts.filter(obj => obj.id === product.id).length > 0) {
    return;
  }
  else{
    window.contaktiChatClient.replyProducts.push(product);
  }
}
function bindClick(id) {
  let cartProduct = window.contaktiChatClient.replyProducts.find(product => product.id == id);
  if(cartProduct) {
    window.contaktiShoppingCart.addToCart(cartProduct);
  }
}
function showProducts(products) {
  let html = '<div id="chat-answer-products-wrapper">';
  products.forEach(product => {
    html += `<div class="answer_product">
                <div class="child1"><strong>${product.title}</strong> </div><div class="child2"><a href="javascript:bindClick(${product.id})" class="add-to-cart-btn" data-product-id="${product.id}"  style="color: ${ContaktiChat.text_color}!important; background-color:${ContaktiChat.color}!important">
              <i class="fa fa-shopping-cart"></i></a></div></div>`;
    addProductsInReplyProductsList(product);
  });

  html += "</div>";
  return html;
}

ContaktiChat.ChatClient.prototype._onMessageReceived = function(envelope) {
  console.log('onMessageReceived.........', envelope);
  var color = envelope.from == this.username ? 'msg_b' : 'msg_a';
  var fromColor = envelope.from == this.username ? 'from_b' : 'from_a';
  var fromTime = envelope.from == this.username ? 'time_b' : 'time_a';
    this.messageCame = true;
  let self = this;

  if(envelope.type == 'message') {
    this.messageContainer.innerHTML += '<div class="'+color+'">' + ChatUtils.replaceURLs(envelope.message).replaceAll("\n", '<br/>') + '</div> ' ;
    if (envelope.products && envelope.products.length){
      this.messageContainer.innerHTML += showProducts(envelope.products);
    }
    if(envelope.action_buttons && envelope.action_buttons.length > 0){
      envelope.action_buttons.forEach((btn_text) =>{
        this.messageContainer.innerHTML += `<br/><button class="action-button" style="background-color: ${ContaktiChat.color}; color: ${ContaktiChat.text_color}" onclick="sendCustomActionMessage(event)">${btn_text}</button><br/>`
      })
      this.messageContainer.innerHTML += "<br/>"
    }
    var timestamp = moment(envelope.timestamp).local().format('D.M.YYYY HH.mm')
    this.messageContainer.innerHTML += '<div class="msg_time ' + fromTime + '">' + timestamp + '</div> ' ;
    this.messageContainer.innerHTML += '<div class="msg_from ' + fromColor + '">' + envelope.from + '</div> ' ;
    var indicators = document.getElementById('contakti-msg-indicator');
    var customActionButton  = document.getElementById('custom_action_button');
    if (envelope.has_custom_action && envelope.custom_action_text ){
      ContaktiChat.ticketMessageTitle = envelope.custom_action_text
      customActionButton.hidden = false;
      customActionButton.innerText = envelope.custom_action_text ;
    }
    if (envelope.from != this.username) {
      indicators.innerText = "";
    }
  } else if(envelope.type == 'file') {
    this.messageContainer.innerHTML += '<div class="'+color+'"><a download target="_blank" href="' + envelope.message.replaceAll("\n", '<br/>') + '">' + envelope.from + ' '+ ContaktiChat.translations.user_dashboard.upload_chat+'</a></div> ' ;
    var timestamp = moment(envelope.timestamp).local().format('D.M.YYYY HH.mm')
    this.messageContainer.innerHTML += '<div class="msg_time ' + fromTime + '">' + timestamp + '</div> ' ;
    this.messageContainer.innerHTML += '<div class="msg_from ' + fromColor + '">' + envelope.from + '</div> ' ;
  } else if(envelope.type == 'bot_message_with_file'){
    let messageHtml = '<div class="'+color+'">'
    messageHtml += ChatUtils.replaceURLs(envelope.message).replaceAll("\n", '<br/>');
    messageHtml += '<br/>';
    envelope.files.forEach((file) => {
      messageHtml += '<a download target="_blank" href="' + file.url + '">' + file.name +'</a><br/>';
    });
    messageHtml += '</div> ' // last line
    this.messageContainer.innerHTML += messageHtml;
    if (envelope.products && envelope.products.length){
      this.messageContainer.innerHTML += showProducts(envelope.products);
    }
    if (envelope.action_buttons && envelope.action_buttons.length > 0){
      envelope.action_buttons.forEach((btn_text) =>{
        this.messageContainer.innerHTML += `<br/><button class="action-button" style="background-color: ${ContaktiChat.color}; color: ${ContaktiChat.text_color}" onclick="sendCustomActionMessage(event)">${btn_text}</button><br/>`
      })
      this.messageContainer.innerHTML += "<br/>";
    }
    var timestamp = moment(envelope.timestamp).local().format('D.M.YYYY HH.mm')
    this.messageContainer.innerHTML += '<div class="msg_time ' + fromTime + '">' + timestamp + '</div> ' ;
    this.messageContainer.innerHTML += '<div class="msg_from ' + fromColor + '">' + envelope.from + '</div> ' ;
    var customActionButton  = document.getElementById('custom_action_button');
    if (envelope.has_custom_action && envelope.custom_action_text ){
      ContaktiChat.ticketMessageTitle = envelope.custom_action_text
      customActionButton.hidden = false;
      customActionButton.innerText = envelope.custom_action_text ;
    }
  }
  else if(envelope.type == 'quit') {
    this.agentCount -= 1;

    this.messageContainer.innerHTML += '<div class="msg_n">' + envelope.from + ' ' + ContaktiChat.translations.user_dashboard.quit_chat+'</div>';

    if(this.agentCount < 1) {
      // Disable send button. Do stuff!
      this.agentPresent = false;
      this._setSendDisabled();
    }
  } else if(envelope.type == 'join') {
    var inputElement = document.getElementById('contakti-chat-text-input');
    if (inputElement.hasAttribute('disabled'))
      inputElement.removeAttribute('disabled');
    this.agentCount += 1;
    if(this.agentPresent) {
      this.messageContainer.innerHTML += '<div class="msg_n">' + envelope.from + ' ' + ContaktiChat.translations.user_dashboard.join_chat+ '</div>';
    } else {
      this.messageContainer.innerHTML += '<div class="msg_a">' + this.welcomeMessage + '</div>';
      var timestamp = moment().local().format('D.M.YYYY HH.mm')
      this.messageContainer.innerHTML += '<div class="msg_time ' + fromTime + '">' + timestamp + '</div> ' ;
      this.messageContainer.innerHTML += '<div class="msg_from ' + fromColor + '">' + envelope.from + '</div> ';
      var details = JSON.parse(envelope.message.replaceAll("\n", '<br/>'));
      var agentName = document.getElementById('contakti-chat-agent-name');
      if(agentName) {
        agentName.innerText = details.name;
      }

      var agentTitle = document.getElementById('contakti-chat-agent-title');
      if(agentTitle) {
        agentTitle.innerText = details.title;
      }

      document.getElementById('contakti-chat-agent-details').style.display = 'block';
    }
    var chatSettingDrowpdown = document.getElementById('chat-setting-dropdown');
    if(chatSettingDrowpdown) {
      document.getElementById('chat-setting-dropdown').style.display = "block";
      document.getElementById('chat-setting-dropdown').classList.add('show-dropdown');
    }
    this.agentPresent = true;
    clearTimeout(this.connectTimeout);
    this._setSendDisabled();
  } else if(envelope.type == 'agent_indicator'){
    var indicators = document.getElementById('contakti-msg-indicator');
    var has_cookies = localStorage.getItem('indicator_state')
    if (!has_cookies) {
      // setCookies
      localStorage.setItem('indicator_state', 'true')
      indicators.innerHTML = envelope.from + ContaktiChat.translations.user_dashboard.typing_text + '<div id="wave"> <span class="dot"></span> <span class="dot"></span> <span class="dot"></span> </div>';
      this.connectTimeout = setTimeout(function() {
        var indicators = document.getElementById('contakti-msg-indicator');
        indicators.innerHTML = '';
        // remove cookie
        localStorage.removeItem('indicator_state')
      }, 5000);
    }
  }
  else if(envelope.type == 'switch_to_human'){
    let default_message_bot_to_human = ContaktiChat.translations.user_dashboard.ask_human_to_help;
    this.messageContainer.innerHTML += '<div class="'+color+'">' + default_message_bot_to_human + '</div> ' ;
    var timestamp = moment(envelope.timestamp).local().format('D.M.YYYY HH.mm')
    this.messageContainer.innerHTML += '<div class="msg_time ' + fromTime + '">' + timestamp + '</div> ' ;
    this.messageContainer.innerHTML += '<div class="msg_from ' + fromColor + '">' + envelope.from + '</div> ' ;
    var indicators = document.getElementById('contakti-msg-indicator');
    if (envelope.from != this.username) {
      indicators.innerText = "";
    }

    let successCallback = function(data){
      ContaktiChat.chatWithHuman = true;
      // if(data.agent_online == false) {
      //   self.displayNoAgentOnlineScreen();
      // }
      // else{
        // self.connectTimeout = setTimeout(function() {
          self.displayNoAgentOnlineScreen();
        // }, 5000);
      // }
    }

    this.changeFromBotToHumanChat(successCallback);
    // var indicators = document.getElementById('contakti-msg-indicator');
    // var has_cookies = localStorage.getItem('indicator_state')
    // if (!has_cookies) {
    //   // setCookies
    //   localStorage.setItem('indicator_state', 'true')
    //   indicators.innerHTML = envelope.from + ContaktiChat.translations.user_dashboard.typing_text + '<div id="wave"> <span class="dot"></span> <span class="dot"></span> <span class="dot"></span> </div>';
    //   this.connectTimeout = setTimeout(function() {
    //     var indicators = document.getElementById('contakti-msg-indicator');
    //     indicators.innerHTML = '';
    //     // remove cookie
    //     localStorage.removeItem('indicator_state')
    //   }, 5000);
    // }
  }
  this.scrollDown();
};

ContaktiChat.ChatClient.prototype._channelUrl = function() {
  return ContaktiChat.serverUrl + this.chatChannel + '/send_msg';
};

ContaktiChat.ChatClient.prototype.scrollDown = function() {
  this.messageContainer.scrollTop = this.messageContainer.scrollHeight;
};


ContaktiChat.ChatClient.prototype.displayNoAgentOnlineScreen = function(timeOut=60000) {
  let self = this;

  this.connectTimeout = setTimeout(function() {
    self.messageContainer.innerHTML += ("<div class='msg_n'>"+ContaktiChat.translations.user_dashboard.chat_not_available+'<a href="#" id="contakti_chat_not_available_link">' + ContaktiChat.translations.user_dashboard.chat_leave_a_message_link + "</a></div>");
    self.scrollDown();
    var elem = document.getElementById('contakti_chat_not_available_link');
    elem.onclick = function() {
      self._quitChat();
      var mainContainer = document.getElementById('contakti-chat-container');
      mainContainer.innerHTML = ContaktiChat.messageBox;
      window.contaktiMessageBox = new ContaktiChat.MessageBox();
      window.contaktiMessageBox.initialise();
      window.contaktiMessageBox.maximize();
    };
  }, timeOut)
};


ContaktiChat.ChatClient.prototype._sendMessage = function(message) {
  var msg = this.messageFactory.newMessage(message);
  var req = new XMLHttpRequest();
  req.open('POST', this._channelUrl(), true);
  req.setRequestHeader('Content-type', 'application/json');
  req.send(msg.asJSON());
  document.getElementById('contakti-chat-text-input').value = '';
};

ContaktiChat.ChatClient.prototype._sendQuitNotify = function() {
  if(this.quitSent) return;
  this.quitSent = true;
  var msg = this.messageFactory.quitMessage();
  var req = new XMLHttpRequest();
  req.open('POST', this._channelUrl(), false); // Synchronous because of onbeforeunload
  req.setRequestHeader('Content-type', 'application/json');
  req.send(msg.asJSON());
  var ret = true ? null : ':D'; // Some browsers need fooling to evaluate onbeforeunload
  return ret;
};


ContaktiChat.ChatClient.prototype._quitChat = function() {
  if(this.agentPresent) {
    this._sendQuitNotify();
  } else {
    if(this.chatChannel) {
      var req = new XMLHttpRequest();
      req.open('GET', ContaktiChat.serverUrl + '/chat/' + ContaktiChat.serviceChannel + '/abort_chat?channel_id=' + encodeURIComponent(this.chatChannel), true);
      req.setRequestHeader('Content-type', 'application/json');
      req.send();
    }
  }
};

ContaktiChat.ChatClient.prototype._channelIndicatorUrl = function() {
  return ContaktiChat.serverUrl + this.chatChannel + "/send_indicator";
};

ContaktiChat.ChatClient.prototype._onKeyIndicator = function() {
  var msg = this.messageFactory.newMessage("Customer typing");
  var req = new XMLHttpRequest();
  req.open('POST', this._channelIndicatorUrl(), true);
  req.setRequestHeader('Access-Control-Allow-Origin', '*');
  req.setRequestHeader('Access-Control-Allow-Methods', 'PUT, POST, GET, DELETE, OPTIONS');
  req.setRequestHeader("Access-Control-Allow-Headers",
  "Origin, X-Requested-With, Content-Type, Accept");
  req.setRequestHeader('Access-Control-Allow-Credentials', 'true');
  req.setRequestHeader('Content-type', 'application/json');
  req.send(msg.asJSON());
};

ContaktiChat.ChatClient.prototype._onKeyPress = function(event) {
  var keyCode = event.keyCode;
  if(keyCode != 13) {
    this._onKeyIndicator();
  }

};

ContaktiChat.ChatClient.prototype._onSendClicked = function(event) {
  var inputElement = document.getElementById('contakti-chat-text-input');
  var text = inputElement.value;
  inputElement.value = '';
  this._setSendDisabled();
  this._sendMessage(text);
};

ContaktiChat.ChatClient.prototype._startChat = function(event) {

    this.setUsername(document.getElementById('contakti-input-name').value);
    this.phone =     document.getElementById('contakti-input-phone').value;
    this.email =     document.getElementById('contakti-input-email').value;

    this.startChat();
    document.getElementById('contakti-user-details').style.display = 'none';
    document.getElementById('contakti-msg-footer').style.display = 'block';
    var sendButton = document.getElementById('contakti-chat-send-btn');
    sendButton.onclick = this._onSendClicked.bind(this);
};

ContaktiChat.ChatClient.prototype._setSendDisabled = function(event) {
    var inputElement = document.getElementById('contakti-chat-text-input');
    // No need to replace '\n' so that multiline messages can also be sent.
    // inputElement.value = inputElement.value.replace(/[\r\n]/, '');
    // inputElement.value = inputElement.value;
    var text = inputElement.value;
    var timeout = null;
    if(text.length == 0 || (!this.agentPresent && ContaktiChat.chatWithHuman)) {
       document.getElementById('contakti-chat-send-btn').className = "disabled";
       // document.getElementById('contakti-chat-send-btn').disabled = true;
       if(!this.agentPresent && ContaktiChat.chatWithHuman){
           var inputElement = document.getElementById('contakti-chat-text-input');
           // inputElement.setAttribute('disabled', true);
       }
    } else {
       document.getElementById('contakti-chat-send-btn').className = "";
       document.getElementById('contakti-chat-send-btn').disabled = false;
    }

    if(event && event.type == 'keydown' & event.keyCode == 13) {
        if(document.getElementById('contakti-chat-send-btn').disabled == false) {
            document.getElementById('contakti-chat-send-btn').click();
        }
    }

    inputElement.onkeyup = function (e) {
      clearTimeout(timeout);
      timeout = setTimeout(function () {
          console.log('Input Value:', text);
      }, 500);
    };
};

ContaktiChat.ChatClient.prototype.maximize = function() {
  document.getElementById('contakti-msg-box').style.bottom = '0px';
  var chatSettingDrowpdown = document.getElementById('chat-setting-dropdown')
  if (chatSettingDrowpdown && document.getElementsByClassName('show-dropdown').length > 0) {
    document.getElementById('chat-setting-dropdown').style.display = "block";
  }
  document.getElementById('contakti-msg-minimize').classList.remove('hide');
  var sendButton = document.getElementById('contakti-chat-send-btn');
  sendButton.onclick = this._onSendClicked.bind(this);
  this.messageContainer = document.getElementById('contakti-msg-body');
  this.minimized = false;
};

ContaktiChat.ChatClient.prototype._bindElements = function() {
    var phoneInput =  document.getElementById('contakti-input-phone');
    var emailInput =  document.getElementById('contakti-input-email');
    var nameInput = document.getElementById('contakti-input-name');
    // var close = document.getElementById('contakti-msg-close');
    var endChat = document.getElementById('contakti-msg-close-chat');
    var self = this;

    ['onkeydown','onpaste','oncut', 'onchange', 'oninput'].forEach(function(e){
        document.getElementById('contakti-chat-text-input')[e] = self._setSendDisabled.bind(self);
    });

    document.getElementById('contakti-chat-text-input').addEventListener("keypress", self._onKeyPress.bind(self), false);

    var cart_hidden = true;
    var minimized = false;
    function minimize()
    {
        if(document.querySelector('.dropdown')){
          document.querySelector('.dropdown').classList.remove("open");
        }
        var chatBoxHeight = document.getElementById('contakti-msg-box').offsetHeight;
        var headerHeight = document.getElementById('contakti-msg-head').offsetHeight;
        document.getElementById('contakti-msg-box').style.bottom = '-' + (chatBoxHeight - headerHeight) +  'px';
        // document.getElementById('contakti_cart_box').style.bottom = '-' + (chatBoxHeight - headerHeight) +  'px';
        var chatSettingDrowpdown = document.getElementById('chat-setting-dropdown')
        if (chatSettingDrowpdown) {
          document.getElementById('chat-setting-dropdown').style.display = "none";
        }
        document.getElementById('contakti-msg-minimize').classList.add('hide');
      document.getElementById('cart_show_button').setAttribute("hidden", true);
      if(!cart_hidden) {
        document.getElementById('contakti_cart_box').style.bottom = '-9999px';
        cart_hidden = true;
      }
        minimized = true;
    }

    function maximize()
    {
        document.getElementById('contakti-msg-box').style.bottom = '0px';
        var chatSettingDrowpdown = document.getElementById('chat-setting-dropdown')
        if (chatSettingDrowpdown) {
          document.getElementById('chat-setting-dropdown').style.display = "block";
        }
        if (ContaktiChat.cartEnabled && ContaktiChat.cartHasProducts) {
          document.getElementById('cart_show_button').removeAttribute("hidden");
        }
       document.getElementById('contakti-msg-minimize').classList.remove('hide');
        minimized = false;
    }

    minimize();
    this._setSendDisabled();

    // document.getElementById('contakti-msg-close').onclick = function(event) {
	   //  self._quitChat();
    //   document.getElementById('contakti-chat-container').innerHTML = '';
    // };

    document.getElementById('contakti-msg-close-chat').onclick = function(event) {
      self._quitChat();
      document.getElementById('contakti-msg-close-chat').style.display = "none";
      document.getElementById('contakti-msg-start-chat').style.display = "block";
      // document.getElementById('contakti-chat-container').innerHTML = '';
      // var mainContainer = document.getElementById('contakti-chat-container');
      // mainContainer.innerHTML = ContaktiChat.chatBox;
      // ContaktiChat.start()
    };
    function startChat(event) {
      document.getElementById('contakti-chat-container').innerHTML = '';
      var mainContainer = document.getElementById('contakti-chat-container');
      mainContainer.innerHTML = ContaktiChat.chatBox;
      document.getElementById('contakti-msg-close-chat').style.display = "block";
      document.getElementById('contakti-msg-start-chat').style.display = "none";
      ContaktiChat.start();
    }

    document.getElementById('contakti-msg-start-chat').onclick = startChat

    document.getElementById('contakti-msg-minimize').onclick = function(event) {
        if(!minimized) {
            minimize();
            event.stopPropagation();
        }
    };
  document.getElementById('cart_show_button').onclick = function (event) {
    if(cart_hidden) {
      document.getElementById('contakti_cart_box').style.bottom = '0px';
      cart_hidden = false;
    }
    else {
      document.getElementById('contakti_cart_box').style.bottom = '-9999px';
      cart_hidden = true;
    }
  }

    function getChatTranscript(){
      var newString = "";
      var parent =  document.querySelector('#contakti-msg-body');
      var msgLength = parent.children.length;
      for(var i=0; i < msgLength; i++){
        var current =  parent.children[i];
        if(current.classList.value == "msg_a" || current.classList.value == "msg_b"){
          if(current.children.length > 0){
            let found_anchor = false;
            var childLength = current.children.length;
            for(var j=0; j < childLength; j++){
              var findTag = current.children[j];
              if(findTag.tagName === "A"){
                console.log(findTag.href,'Linkkkkkkkk');
                newString += '\n' + findTag.href + '\n';
                found_anchor = true;
              }
            }
            if (found_anchor == false)
            {
              newString += '\n' + current.innerText + '\n';
            }
          }else{
            newString += '\n' + current.innerText + '\n';
          }
        }else{
          if(current.id != "contakti-user-details"){
            newString += current.innerText + '\n';
          }
        }
      }

      return newString;
    }

    document.getElementById('download_chat_history').onclick = function(event) {
      var element = document.createElement('a');
      element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(getChatTranscript()));
      element.setAttribute('download', 'chat_history.txt');

      element.style.display = 'none';
      document.body.appendChild(element);

      element.click();

      document.body.removeChild(element);
    }


    document.getElementById('send_chat_history').onclick = function(event){
      var mainContainer = document.getElementById('contakti-chat-container');
      var innerContainer = document.getElementById('contakti-msg-box');
      var dropdown_menu = document.getElementById('chat-setting-dropdown-menu');
      var chatTranscript = getChatTranscript()
      mainContainer.innerHTML = ContaktiChat.sendChatHistoryBox;
      document.getElementById('send-chat-history-message').value = chatTranscript;
      document.getElementById('chat-client-container').value = innerContainer.innerHTML;
      document.getElementById('chat-setting-dropdown-menu').innerHTML = dropdown_menu.innerHTML;
      window.contaktiSendChatHistoryBox = new ContaktiChat.SendChatHistoryBox();
      window.contaktiSendChatHistoryBox.initialise();
      window.contaktiSendChatHistoryBox.maximize();
    }
    document.getElementById('contakti-msg-box').onclick = function(event) {
        if(minimized) {
            if (self.format === 'classic' && !self.started) {
              self._startChat();
              self.started = true;
            }
            maximize();
            event.stopPropagation();
        }
    };

    document.getElementById('contakti-open-file').onclick = function() {
      document.getElementById('contakti-file-upload-input').click();
    };

    /* File Upload */
    document.getElementById('contakti-file-upload-input').onchange = function(event) {
      var formData = new FormData(document.getElementById('contakti-file-upload-form'));

      var req = new XMLHttpRequest();
      req.open('POST', ContaktiChat.serverUrl + '/chat/uploadfile?');

      var done = function(req) {
        if(req.readyState == 4 && req.status == 200) {
           var response = JSON.parse(req.responseText);
           var msg = self.messageFactory.fileMessage(response.file_url, response.file_path);
           var req = new XMLHttpRequest();
           req.open('POST', self._channelUrl() ,true);
           req.setRequestHeader('Content-type', 'application/json');
           req.send(msg.asJSON());
        }
      };

      req.onreadystatechange = done.bind(this, req);

      req.send(formData);
    };

    var detailsSubmit = document.getElementById('contakti-input-details-submit');
    detailsSubmit.onclick = this._startChat.bind(this);

    document.getElementById('custom_action_button').onclick  = function(){
      const task_data = {};
      task_data['channel_id'] = self.chatChannel
      task_data['media_channel_id'] = ContaktiChat.serviceChannel;
      task_data['messages_attributes'] = [];
      task_data['messages_attributes'][0] = {};
      task_data['messages_attributes'][0]['title'] = "";
      task_data['messages_attributes'][0]["channel_type"] = 'chat'
      if (ContaktiChat.ticketMessageTitle.length > 0) {
        task_data['messages_attributes'][0]['title'] = ContaktiChat.ticketMessageTitle;
      }
      task_data['messages_attributes'][0]['to'] = 'Internal';
      task_data['messages_attributes'][0]['from'] = self.username;
      if (self.email.length > 0) task_data['messages_attributes'][0]['from'] = self.email;
      task_data['messages_attributes'][0]['description'] = getChatTranscript();
      task_data['type'] = 'chat';
      const url = ContaktiChat.serverUrl + '/tasks/create_task_from_chat'
      fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(task_data),
      })
        .then(response => response.json())
        .then(data => {
          document.getElementById('custom_action_button').hidden = true;
          self._sendQuitNotify();
          setTimeout(startChat, 3000);

        })
        .catch((error) => {
          console.error('Error:', error);
        });
    }

};

