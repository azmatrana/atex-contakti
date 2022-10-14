import React, { Component } from 'react';
import ChatMessageFactory from '../../classes/MessageFactory';
import Message from './Message';
import Api from '../../classes/Api';
import moment from 'moment';
import SendChatHistory from '../others/SendChatHistory';
import _ from 'lodash';
import Text from '../modules/utils/Text';
import ChatUtils from '../../classes/ChatUtils';
class ChatBox extends Component {
  constructor(props) {
    super(props);
    this.state = {
      chatChannel: null,
      fayeServer: null,
      messageContainer: document.getElementById('chat_area'),
      username: '',
      email: '',
      phone: '',
      messageFactory: new ChatMessageFactory({ username: this.username, channel: this.chatChannel, email: this.email, phone: this.phone }),
      quitSent: false,
      messageCame: false,
      agentPresent: false,
      agentsCount: 0,
      connectTimeout: 0,
      started: false,
      messages: [],
      messagEnvelopes: [],
      contaktiChat: {},
      showDetailInput: true,
      showChat: false,
      newMessage: "",
      disableChatSendDisabled: false,
      disableMessageInput: false,
      showNoAgentOnline: false,
      agentName: "",
      showSendChatHistoryFlag: false,
      chat_transcript: "",
      showCustomActionButtion: false,
      customActionButtionText: "",
      uploadedFileUrls: [],
      orderCreated: false,
      orderCheckoutMethod: "",
      msgAttempts: 1
    }
  }
  componentDidMount() {
    if (!this.props.contaktiChat || (this.props.contaktiChat && Object.keys(this.props.contaktiChat).length === 0)) {
      return;
    }
    let chat = this.props.contaktiChat

    this.setState({ messageContainer: document.getElementById('chat_area') });
    this.setState({ contaktiChat: chat }, async () => {
      if (this.state.contaktiChat.chat_settings.format !== "inquiry" || this.state.contaktiChat.chat_settings.chat_inquiry_fields.length === 0) {
        await this.startChat();
      }
      // window.onbeforeunload = this.quitChat;
    });
    this.setSendDisabled();
  }

  onStartClientResponse = (response) => {
    if ((!this.state.agentPresent) && this.state.contaktiChat.chatWithHuman) {
      this.setSendDisabled()
    }

    response.callback = this.onMessageReceived;
    response.connect = true;

    this.setState({ chatChannel: response.channel });
    this.setState({ fayeServer: response.server });
    window.Danthes.sign(response);
    // Set client info in redis to use when client closes or reloads the chat.
    setTimeout(() => {
      const url = this.state.contaktiChat.serverUrl + `/chat/set_client_info?channel_id=${this.state.chatChannel}`
      fetch(url, {
        "Content-Type": "application/json"
      });
    }, 2000);

  };



  displayNoAgentOnlineScreen = (timeOut = 60000) => {
    let contakti_chat = this.state.contaktiChat;
    if (contakti_chat.agents_online == false && contakti_chat.chatWithHuman == true)
    {
      this.props.showNoAgentOnlineScreen();
    }
    else{
      this.setState({
        connectTimeout: setTimeout(() => {
          this.scrollDown();
          this.setState({ showNoAgentOnline: true });
          this.quitChat();
        }, timeOut)
      });
    }

  };

  successCallback = (data) => {
    let contakti_chat = this.state.contaktiChat;
    if (data.agent_online == false)
    {
      this.displayNoAgentOnlineScreen(0);
    }
    else
    {
      contakti_chat.chatWithHuman = true;
      contakti_chat.chatBotEnabled = false;
      this.setState({ contaktiChat: contakti_chat }, () => {
        this.setSendDisabled();
        this.displayNoAgentOnlineScreen();
      });
    }
  }
  onMessageReceived = (envelope) => {
    if (envelope.type === 'indicator') {
      return
    }
    //TODO indicators
    var indicators = document.getElementById('contakti-msg-indicator');
    this.setState({ messageCame: true, msgAttempts: 1 });
    if (envelope.type === 'agent_indicator') {
      indicators = document.getElementById('contakti-msg-indicator');
      var has_cookies = localStorage.getItem('indicator_state')
      if (!has_cookies) {
        // setCookies
        localStorage.setItem('indicator_state', 'true')
        indicators.innerHTML = envelope.from + this.state.contaktiChat.translations.user_dashboard.typing_text + '<div id="wave"> <span class="dot"></span> <span class="dot"></span> <span class="dot"></span> </div>';
        this.setState({
          connectTimeout: setTimeout(function () {
            var indicators = document.getElementById('contakti-msg-indicator');
            indicators.innerHTML = '';
            // remove cookie
            localStorage.removeItem('indicator_state')
          }, 5000)
        });
      }
    }
    else {
      if (envelope.type === 'quit') {
        this.setState({ agentsCount: this.state.agentsCount - 1 });
        envelope.message = `${envelope.from} ${this.state.contaktiChat.translations.user_dashboard.quit_chat}`;
        if (this.state.agentsCount < 1) {
          // Disable send button. Do stuff!
          this.setState({ agentPresent: false });
          this.setSendDisabled();
        }
      }
      else if (envelope.type === 'join') {
        this.setState({ agentsCount: this.state.agentsCount + 1 });
        if (this.state.agentPresent) {
          envelope.message = `${envelope.from} ${this.state.contaktiChat.translations.user_dashboard.join_chat}`;
        } else {
          envelope.message = `${envelope.from} ${this.state.contaktiChat.chat_settings.welcome_message}`;
        }
        this.setState({ agentPresent: true, agentName: envelope.from });
        clearTimeout(this.state.connectTimeout);
        this.setSendDisabled();
      }
      else if (envelope.type === 'switch_to_human') {
        envelope.message = `${this.state.contaktiChat.translations.user_dashboard.ask_human_to_help}`;
        if (envelope.from !== this.username) {
          indicators.innerText = "";
        }
        this.changeFromBotToHumanChat(this.successCallback);
      }

      else if (envelope.type === 'retry') {
        let {msgAttempts} = this.state
        msgAttempts += 1;
        this.setState({ msgAttempts });
        envelope.message = `${this.state.contaktiChat.translations.user_dashboard.retry_message}`;
        if (envelope.from !== this.username) {
          indicators.innerText = "";
        }
      }

      let { messages, chat_transcript } = this.state;
      if (envelope) messages.push(envelope);
      chat_transcript = this.getChatTranscript();
      this.setState({messages, chat_transcript })
      if (envelope.has_custom_action && envelope.custom_action_text) {
        this.setState({ showCustomActionButtion: true, customActionButtionText: envelope.custom_action_text });
      }
      if (envelope.from !== this.state.username) {
        indicators.innerText = "";
      }

    }
    this.scrollDown();
  };




  changeFromBotToHumanChat = async (successCallback) => {

    let client_data = [];
    if (this.state.contaktiChat.chat_settings.format === 'inquiry') {
      client_data = this.state.contaktiChat.chat_settings.chat_inquiry_fields.map(field => {
        return { label: field.title, value: this.state[_.camelCase(field.title)] }
      })
    }
    else {
      client_data = [
        { label: "Name", value: this.state.username }
      ]
    }
    let params = {
      chatbot: false,
      channel_id: this.state.chatChannel,
      name: this.state.username,
      email: this.state.email,
      phone: this.state.phone,
      chat_display_fields: client_data,
      is_ad_finland_company: this.state.contaktiChat.is_ad_finland
        }
    // var options = "chatbot=" + false + "&name=" + this.state.username + "&email=" + this.state.email + "&phone=" + this.state.phone + "&channel_id=" + encodeURIComponent(this.state.chatChannel);
    let route = `/chat/${this.state.contaktiChat.serviceChannel}/bot_initiate_human_chat`;
    let res = await new Api().post(route, params);
    successCallback(res);
  }


  setUsername(name) {
    if (!name) {
      name = 'Anonymous';
    }
    this.setState({ username: name });
    let msgFactory = this.state.messageFactory
    msgFactory.from = name;
    this.setState({ messageFactory: msgFactory });
  };

  sendCustomActionMessage = (e) => {
    this.sendMessage(e.target.innerText);
  }

  sendMessage = (msg_text = "") => {
    if (msg_text.length === 0) {
      msg_text = this.state.newMessage;
    }
    if (msg_text.length > 0) {
      var msg = this.state.messageFactory.newMessage(msg_text, null, this.state.contaktiChat.chatBotEnabled);
      msg.attempts = this.state.msgAttempts;
      let route = this._channelUrl();
      new Api().post(route, msg);
      this.setState({ newMessage: "" })
    }
  };



  _channelUrl = () => {
    return this.state.chatChannel + '/send_msg';
  };

  scrollDown = () => {
    if (this.messagesListContainer) {
      this.messagesListContainer.lastChild.lastChild.scrollIntoView({ behavior: "smooth", block: "start", inline: "nearest" });
    }
  };

  sendQuitNotify = () => {
    if (this.state.quitSent) return;
    this.setState({ quitSent: true });
    var msg = this.state.messageFactory.quitMessage();
    let route = this._channelUrl();
    new Api().post(route, msg);
    var ret = true ? null : ':D'; // Some browsers need fooling to evaluate onbeforeunload
    return ret;
  };

  quitChat = async () => {
    if (this.state.agentPresent) {
      this.sendQuitNotify();
    } else {
      if (this.state.chatChannel) {
        let route = `/chat/${this.state.contaktiChat.serviceChannel}/abort_chat?channel_id=${encodeURIComponent(this.state.chatChannel)}`;
        await new Api().get(route);
      }
    }
  };
  _channelIndicatorUrl = () => {

    return this.state.chatChannel + "/send_indicator";
  };

  onKeyIndicator = () => {
    var msg = this.state.messageFactory.newMessage("Customer typing");
    let route = this._channelIndicatorUrl();
    new Api().post(route, msg);
  };

  onKeyPress = (event) => {
    var keyCode = event.keyCode;
    if (keyCode !== 13) {
      this.onKeyIndicator();
    }

  };

  onSendClicked = (event) => {
    this.setSendDisabled();
    this.sendMessage();
  };

  startChat = async (e) => {
    if (e) {
      e.preventDefault();
    }
    let name = "Anonymous";
    if (this.state.contaktiChat.chat_settings.format === 'inquiry') {
      name = this.state[_.camelCase(this.state.contaktiChat.chat_settings.chat_inquiry_fields[0]?.title)]
    }
    this.setState({
      showDetailInput: false,
      showChat: true,
      username: this.state.username.length > 0 ? this.state.username : name,
      messageFactory: new ChatMessageFactory({
        username: this.state.username.length > 0 ? this.state.username : name,
        channel: this.state.chatChannel,
        email: this.state.email,
        phone: this.state.phone
      })
    });
    this.props.toggleDropDown(true);
    if (this.state.contaktiChat.chatWithHuman) {
      this.displayNoAgentOnlineScreen();
    }
    let client_data = [];
    if (this.state.contaktiChat.chat_settings.format === 'inquiry') {
      client_data = this.state.contaktiChat.chat_settings.chat_inquiry_fields.map(field => {
        return { label: field.title, value: this.state[_.camelCase(field.title)] }
      })
    }
    else {
      client_data = [
        { label: "Name", value: name }
      ]
    }
    let params = {
      chatbot: this.state.contaktiChat.chatBotEnabled,
      name: name,
      email: this.state.email,
      phone: this.state.phone,
      chat_display_fields: client_data,
      is_ad_finland_company: this.state.contaktiChat.is_ad_finland
    }

    let route = `chat/${this.state.contaktiChat.serviceChannel}/initiate_chat`;
    let res = await new Api().post(route, params);

    if (this.state.contaktiChat.initialMsg.length > 0) {
      var msg = this.state.messageFactory.newMessage(this.state.contaktiChat.initialMsg, "initial", this.state.contaktiChat.chatBotEnabled, this.state.contaktiChat.chat_settings.bot_alias);
      if (this.state.contaktiChat.chatBotEnabled && this.state.contaktiChat.chat_settings.enable_initial_buttons) {
        msg.action_buttons = this.state.contaktiChat.chat_settings.chat_initial_buttons.map(btn => {return{ text: btn.title}});
      }
      let moment1 = moment;
      msg.timestamp = moment1().local().format();
      let msgs = this.state.messages
      msgs.push(msg);
      this.setState({ messages: msgs });
    }
    this.props.setChatStarted();
    this.onStartClientResponse(res);
  };

  setSendDisabled = (event) => {
    if (!this.state.agentPresent && this.state.contaktiChat?.chatWithHuman) {
      this.setState({ disableChatSendDisabled: true })
      if (!this.state.agentPresent && this.state.contaktiChat?.chatWithHuman) {
        this.setState({ disableChatSendDisabled: true })

      }
    } else {
      this.setState({ disableChatSendDisabled: false })
    }
  };

  maximize() {
    document.getElementById('contakti-msg-box').style.bottom = '0px';
    var chatSettingDrowpdown = document.getElementById('chat-setting-dropdown')
    if (chatSettingDrowpdown && document.getElementsByClassName('show-dropdown').length > 0) {
      document.getElementById('chat-setting-dropdown').style.display = "block";
    }
    document.getElementById('contakti-msg-minimize').classList.remove('hide');
    var sendButton = document.getElementById('contakti-chat-send-btn');
    sendButton.onclick = this._onSendClicked.bind(this);
    this.setState({ messageContainer: document.getElementById('contakti-msg-body') });
    this.setState({ minimized: false });
  };

  updateUserDetail = () => {
  }

  handleChange = (event, key) => {
    let state = this.state;
    let inputName = event.target.name;
    state[inputName] = event.target.value;
    this.setState({ ...state });
  }
  uploadFile = () => {
    this.fileInput.click();
  }
  handleFileChange = async (e) => {
    // const fileData = e.target.files[0];

    let file = e.target.files[0];


    var formdata = new FormData();
    formdata.append("upload", file, file.name);

    let response = await new Api().postFile('chat/uploadfile', formdata);
    this.state.uploadedFileUrls.push(response.file_url)
    var msg = this.state.messageFactory.fileMessage(response.file_url, response.file_path);
    let route = this._channelUrl();
    new Api().post(route, msg);

  }

  showSendChatHistory = () => {
    this.setState({ showSendChatHistoryFlag: true });
  }
  getChatTranscript = () => {
    let transcript = "";
    this.state.messages.forEach(message => {
      let chatUtils = ChatUtils
      if(message && message.message){
      transcript += chatUtils.convertHtmlToText(message?.message)
      transcript += '\n'
      }
      if (message && message.files) {
        message.files.forEach(file => {
          transcript += file.url;
          transcript += '\n'
        })
      }
      if (message && message.action_buttons) {
        message.action_buttons.forEach(btn => {
          transcript += btn.text;
          if(btn.hyper_link && btn.hyper_link.length > 0 ){
            transcript +=  `( ${btn.hyper_link} )`
          }
          transcript += '\n';
        })
      }
      if (message && message.type !== 'quit') {
        let _moment = moment;
        transcript += _moment(message.timestamp ? message.timestamp : []).local().format('D.M.YYYY HH.mm')
        transcript += '\n';
        transcript += message.from;
        transcript += '\n';
      }
      transcript += '\n';
    })
    return transcript;
  }

  downloadChat = () => {
    this.fileDownload.click();
  }

  createTicket = async (isFromCart = false, products = [], priceWithoutTaxes="", taxes="", shipment_charges="", sum = "", title="" ) => {
    const task_data = {};
    task_data['channel_id'] = this.state.chatChannel
    task_data['media_channel_id'] = this.state.contaktiChat.serviceChannel;
    task_data['messages_attributes'] = [];
    task_data['messages_attributes'][0] = {};
    task_data['messages_attributes'][0]['title'] = title;
    task_data['messages_attributes'][0]["channel_type"] = 'chat';
    if (this.state.customActionButtionText.length > 0 && title.length === 0) {
      task_data['messages_attributes'][0]['title'] = this.state.customActionButtionText;
    }
    task_data['messages_attributes'][0]['to'] = 'Internal';
    task_data['messages_attributes'][0]['from'] = this.state.username;
    task_data['user_uploaded_file_urls'] = this.state.uploadedFileUrls;
    if (this.state.email.length > 0) task_data['messages_attributes'][0]['from'] = this.state.email;
    let transcript = "";
    if (this.state.contaktiChat.chat_settings.format === 'inquiry') {
      this.state.contaktiChat.chat_settings.chat_inquiry_fields.forEach(field => {
        transcript += `${field.title} : ${this.state[_.camelCase(field.title)]}\n`;
      })
    }
    else {
      transcript += `${this.state.contaktiChat.translations.service_channels.name} : ${this.state.username}\n`;
    }
    transcript += `\n`;
    if(this.state.newMessage.length > 0){
      var msg = this.state.messageFactory.newMessage(this.state.newMessage);
      let {messages} = this.state;
      messages.push(msg);
    }
    transcript += this.getChatTranscript();
    if (isFromCart === true) {
      
			const cartTranslations = this.state.contaktiChat.translations.user_dashboard.shopping_cart;

			transcript += `${cartTranslations.order_details}: \n`;
      
			products.forEach((product) => {
				transcript += `${product.title}&nbsp&nbsp&nbsp&nbsp&nbsp${product.quantity}-${cartTranslations.items}&nbsp&nbsp&nbsp&nbsp&nbsp${cartTranslations.price}: ${ChatUtils.displayPrice(product.price)}${this.state.contaktiChat.currency} ${product.with_vat ? cartTranslations.including : cartTranslations.excluding} ${product.vat?.vat_percentage || 0}% ${cartTranslations.vat}\n`;
      });
      
			transcript += `\n${cartTranslations.price_without_taxes}: ${ChatUtils.displayPrice(priceWithoutTaxes)}${this.state.contaktiChat.currency}\n`; 
			transcript += `${cartTranslations.taxes}: ${ChatUtils.displayPrice(taxes)}${this.state.contaktiChat.currency}\n`;   
			transcript += `${cartTranslations.shipment_charges}: ${ChatUtils.displayPrice(shipment_charges)}${this.state.contaktiChat.currency}\n`;
			transcript += `${cartTranslations.total}: ${ChatUtils.displayPrice(sum)}${this.state.contaktiChat.currency}\n`;
    }
    else {
			task_data["is_from_chatbot_custom_action_button"] = true;
		}

    task_data['messages_attributes'][0]['description'] = transcript;
    task_data['type'] = 'chat';
    const url = 'tasks/create_task_from_chat'
    this.props.setPluginDisabledState(true);
    let createdTask = await new Api().post(url, task_data);
    this.setState( { showCustomActionButtion: false, customActionButtionText: "" } );
    if (!isFromCart) {
			this.props.setPluginDisabledState(false);
			this.props.quit();
		}
    this.quitChat();


    return createdTask.id;
  }

  createOrder = async (task_id = null, customerId = null, products = [], checkout_method = "", shipment_method={}, sum="" ) => {
    let data = {};
    data['customer_id'] = customerId;
    data['checkout_method'] = checkout_method;
    data['shipment_method_id'] = shipment_method.id;
    data['task_id'] = task_id;
    data['currency'] = this.state.contaktiChat.currency;
    data['total'] = sum;
    data['order_products_attributes'] = [];
    data['inquiry_fields_data'] = [];
    data['service_channel_id'] = this.state.contaktiChat.serviceChannel;

    if (this.state.contaktiChat.chat_settings.format === 'inquiry') {
      data['inquiry_fields_data'] = this.state.contaktiChat.chat_settings.chat_inquiry_fields.map(field => {
        return { label: field.title, value: this.state[_.camelCase(field.title)] }
      })
    }

    products.forEach( async (product) => {
      let p = {
				chatbot_product_id: product.id,
				quantity: product.quantity,
				currency: this.state.contaktiChat.currency,
				price: product.price,
				with_vat: product.with_vat,
				vat_percentage: (product.vat && product.vat.vat_percentage) || 0,
			};
      data['order_products_attributes'].push(p);
    })
    await new Api().post( 'orders', data )

    this.setState({ orderCheckoutMethod: checkout_method });
  }

  setOrderCreated = () => {
    this.setState({ orderCreated:  true});
  }

  render() {
    if (!this.state.contaktiChat) {
      return null;
    }
    const { contaktiChat, disableChatSendDisabled } = this.state;
    const { messages } = this.state;

    let inquiryData = [];
    if (contaktiChat.chat_settings?.format === 'inquiry') {
      contaktiChat.chat_settings.chat_inquiry_fields.forEach((field, index) => {
        if (index > 0) {
          inquiryData.push(this.state[_.camelCase(field.title)]);
        }
      })
    }

    let order_success_msg = this.state.orderCheckoutMethod == "checkout_paytrail" ? this.props.contaktiChat.translations.user_dashboard.shopping_cart.note_for_order_payment : this.props.contaktiChat.translations.user_dashboard.shopping_cart.thanks_for_order

    return (

      <div id="contakti-msg-container" className="msg_wrap h-100">
        { this.state.orderCreated ?
          <div className="text-center h-100 d-flex flex-column mx-2 pt-5">
            <Text text={ order_success_msg } />
          </div>
          :
          (
            <div>
        <div id="contakti-chat-agent-details" className="msg_agent" style={{ display: this.state.agentName === "" ? "none" : "block", color: this.props.contaktiChat.text_color, backgroundColor: this.props.contaktiChat.color }}>
          <div className="msg_agent_name" id="contakti-chat-agent-name">{this.state.agentName}</div>
        </div>
        {
          contaktiChat?.chat_settings?.format === "inquiry" && contaktiChat?.chat_settings.chat_inquiry_fields.length > 0 ?
            <div id="contakti-user-details" className="h-100 px-1" style={{ display: this.state.showDetailInput ? 'block' : 'none' }} >
              <form className="flex-column justify-content-between d-flex h-100" onSubmit={async (event) => { await this.startChat(event); }}>
                <div style={{ maxHeight: "330px", overflow: "auto", marginTop: "115px" }} >
                  {contaktiChat?.chat_settings.chat_inquiry_fields.map((field, index) => {
                    return (<div key={`inquiry-fields-${index}`}><label>{field.title}</label>
                      <input type={field.input_type} required className="form-control-start" value={this.state[_.camelCase(field.title)] || ""} name={_.camelCase(field.title)} onChange={this.handleChange} id="contakti-input-name" />
                    </div>
                    )
                  })}
                </div>
                <div style={{ textAlign: 'center', marginBottom: "20px" }} >
                  <div>
                    <input type="submit" id="contakti-input-details-submit" className="btn btn-default btn-block" value={contaktiChat.translations.user_dashboard.start_chat} style={{ backgroundColor: this.props.contaktiChat.color, color: this.props.contaktiChat.text_color }} />
                  </div>
                  <div >
                    Powered by <a href="http://contakti.com" target="_blank" rel="noreferrer">contakti.com</a>
                  </div>
                </div>
              </form>
            </div>
            : null
        }
        {this.state.showSendChatHistoryFlag ? (<SendChatHistory contaktiChat={contaktiChat} bgColor={contaktiChat.color} transcript={this.state.chat_transcript} quitChat={() => { this.props.quit(); this.quitChat(); }} startChat={() => this.props.startChat()} />) : (
          <div className={this.state.showDetailInput === false ? '' : 'd-none'}>

            <div id="contakti-msg-body" className="msg_bodyclient">
              {contaktiChat?.chat_settings?.format === "inquiry" && contaktiChat?.chat_settings.chat_inquiry_fields.length > 0 ? (
                null
              ) : ""}
              <div style={{ display: this.state.showChat ? 'block' : 'none' }} id="chat_area" ref={(el) => { this.messagesListContainer = el; }}>
                {
                  this.state.showNoAgentOnline ? (
                    <div className="msg_n">{contaktiChat.translations.user_dashboard.chat_not_available}<a href="#" onClick={this.props.showNoAgentOnlineScreen} id="contakti_chat_not_available_link"> {contaktiChat.translations.user_dashboard.chat_leave_a_message_link}</a></div>
                  ) : (

                    <div>
                      {
                        messages.map((message, index) => {
                          return (
                            <Message key={index}
                              envelope={message}
                              handleProductShow={this.props.handleProductShow}
                              bgClass={message.from === this.state.username ? 'msg_b' : 'msg_a'}
                              userName={this.state.username}
                              sendCustomActionMessage={this.sendCustomActionMessage}
                              addToCart={(product) => { this.props.addToCart(product) }}
                              contaktiChat={contaktiChat}
                              userInfo={inquiryData}
                            />
                          );

                        })
                      }
                    </div>

                  )}
              </div>
            </div>
            <div id="contakti-msg-indicator" className="msg_indictor"> </div>
            <div id="contakti-msg-footer" className="msg_footer" style={{ display: this.state.showChat ? 'block' : 'none' }}>
              <div className="block-row">
                <div className="input-block">
                  <textarea
                    id="contakti-chat-text-input"
                    value={this.state.newMessage}
                    disabled={disableChatSendDisabled}
                    name='newMessage'
                    onChange={this.handleChange}
                    className="msg_input form-control"
                    placeholder={contaktiChat?.translations?.user_dashboard.type_message}
                    onKeyPress={(event) => {
                      if (event.charCode === 13) {
                        event.preventDefault();
                        this.onSendClicked();
                      }
                      else {
                        this.onKeyPress(event);
                      }
                    }}
                    disabled={this.state.disableChatSendDisabled ? true : false}
                    rows="3" />
                </div>
                <div className="button-block">
                  <a
                    className={`contakti-chat-send-btn ${this.state.newMessage.length > 0 ? "" : "disabled"}`}
                    onClick={this.onSendClicked}
                    style={{ backgroundColor: this.props.contaktiChat.color, color: this.props.contaktiChat.text_color }}>
                    <span className="fa fa-send"></span>
                  </a>
                </div>
              </div>
              <div className="block-row mb-1">
                <div className="pull-left">
                  <button id="custom_action_button" onClick={() => this.createTicket()} style={{ visibility: this.state.showCustomActionButtion ? 'visible' : 'hidden' }}> {this.state.customActionButtionText}</button>
                </div>
              </div>
              <div className="block-row mb-10">
                <div className="pull-left">
                  <a onClick={this.uploadFile} id="contakti-open-file">{contaktiChat.translations?.user_dashboard.attachment_chat}</a>
                </div>
                <div className="pull-right">
                  Powered by <a href="http://contakti.com" target="_blank" rel="noreferrer" style={{ marginRight: '10px' }}>contakti.com</a>
                </div>
              </div>
              <form id="contakti-file-upload-form" style={{ display: 'none' }}>
                <input type="file" id="contakti-file-upload-input" ref={instance => { this.fileInput = instance; }} name="upload" onChange={this.handleFileChange} />
              </form>
            </div>
          </div>
        )}
        </div>
        )}

        <a ref={instance => { this.fileDownload = instance; }} style={{ display: "none" }} href={`data:text/plain;charset=utf-8,${encodeURIComponent(this.state.chat_transcript)}`} download="chat_history.txt"></a>
      </div>
    );
  }
}

export default ChatBox;
