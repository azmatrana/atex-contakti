import React, { Component } from 'react';
import Api from '../../classes/Api';
class SendChatHistory extends Component {

    constructor(props) {
        super(props);
        this.state = {
            email: "",
            chat_history: ""
        }
    }
    componentDidMount() {
        this.setState({ chat_history: this.props.transcript });
    }

    handleChange = (event, key) => {
        let state = this.state;
        let inputName = event.target.name;
        state[inputName] = event.target.value;
        this.setState({ ...state });
    }

    sendEmail = () => {
        let email = this.state.email;
        let message = this.state.chat_history;
        var url = 'chat/' + this.props.contaktiChat.serviceChannel + '/send_email_chat_history';
        let data = { email: email, message: message };
        new Api().post(url, data);
        this.props.quitChat();
    }

    cancel = async () => {
       await this.props.quitChat();
        this.props.startChat();
    }

    render() {
        const translations = this.props.contaktiChat.translations.user_dashboard
        const color = this.props.bgColor
        return (
            <div id="contakti-user-details" className="flex-column justify-content-between d-flex pt-2 px-1">
                <div>
                  <label>{translations.send_chat_history_title}</label>
                  <input type="email" name="email" onChange={this.handleChange} value={this.state.email} placeholder={translations.messageemail_chat} className="form-control callback-control" id="send-chat-history-email" />
                  <br /><br />
                  <textarea placeholder={translations.messagemsg_chat} className="form-control sendchat--history" rows="4" id="send-chat-history-message" name="chat_history" onChange={this.handleChange} value={this.state.chat_history} ></textarea>
                  <br />
                  <input type="hidden" id="chat-client-container" name="chat-client-container" />
                </div>
                <div className="pb-2">
                  <div className="send-button-container pull-left">
                      <button id="send-chat-history-send" className="send" style={{ backgroundColor: color, margin: "5px" }}    onClick={this.sendEmail}>{translations.messagesend_chat}  </button>
                      <span></span>
                      <button id="send-chat-history-cancel" className="send" style={{ backgroundColor: color, margin: "5px" }}  onClick={this.cancel} >{translations.messagesend_cancel}</button>
                  </div>
                  <div className="pull-right">
                      Powered by <a href="http://contakti.com" target="_blank" rel="noreferrer" style={{ position: "relative" }}>contakti.com</a>
                      <div className="send-button-container pull-left">

                      </div>
                  </div>
                </div>
            </div>);
    }
}

export default SendChatHistory;