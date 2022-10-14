import React, { Component } from 'react';
import Api from '../../classes/Api';
import Text from '../modules/utils/Text';
class CallBackBox extends Component {
  constructor(props) {
    super(props);
    this.state = {
      phone: "",
      date: "",
      time: "",
      email: "",
      message: "",
      callBackSent: false

    }
  }

  createCallBack = () => {
    let number = this.state.phone
    let date = this.state.date
    let time = this.state.time
    let datetime = '';
    if (date.length > 0) {
      datetime = new Date(`${date}`);
      if (time.length > 0) {
        datetime = new Date(`${date}T${time}`);
      }
    }
    let email = this.state.email
    let message = this.state.message
    let url = '/chat/' + this.props.contaktiChat.serviceChannel + '/create_callback'
    new Api().post(url, { number: number, datetime: datetime, email: email, message: message });
    document.getElementById('contakti-user-name').innerHTML = this.props.contaktiChat.translations.user_dashboard.thanks_chat;
    this.setState({callBackSent: true})
  }


  handleChange = (event, key) => {
    let state = this.state;
    let inputName = event.target.name;
    state[inputName] = event.target.value;
    this.setState({ ...state });
  }
  render() {
    return (
      <div className="call_back_box h-100">
      { this.state.callBackSent? (<div style={{textAlign: "center", fontSize: "110%", paddingTop: "3em"}}> <Text text={this.props.contaktiChat.translations.user_dashboard.sentmessage_chat} /> </div>) : (
      <form id="contakti-user-details" onSubmit={this.createCallBack} className="h-100 flex-column justify-content-between d-flex">
        <div className="row">
          <div className="col-12 pb-2">
            <label>{this.props.contaktiChat.translations.user_dashboard.callback_chat}</label>
          </div>

          <div className="col-12 pb-2">
            <div>
              <div className="small-label pb-2">{this.props.contaktiChat.translations.user_dashboard.cbnumber_chat}</div>
              <input type="text" onChange={this.handleChange} placeholder={this.props.contaktiChat.translations.user_dashboard.cbnumber_chat} name="phone" className="form-control callback-control" value={this.state.phone} id="messagebox-callback-number" required={!(this.state.email.length > 0)} />
            </div>
            <div style={{clear: "both"}}></div>
          </div>

          <div className="col-12">
            <div className="small-label pb-2">{this.props.contaktiChat.translations.user_dashboard.time_chat}</div>
            <div style={{clear: "both"}}></div>

            <div style={{width: "50%", float: "left", boxSizing: "border-box",  paddingRight: "20px"}}>
              <input type="date" id="messagebox-date-field" name="date" value={this.state.date} onChange={this.handleChange} />
            </div>

            <div style={{width: "50%", float: "left", boxSizing: "border-box",  paddingRight: "20px"}}>
              <input type="time" id="messagebox-time-field" name="time" value={this.state.time} onChange={this.handleChange} />
            </div>


            <div style={{clear: "both"}}></div>
          </div>
          <div className="col-12 pb-2">
            <label>{this.props.contaktiChat.translations.user_dashboard.message_chat}</label>
            <input type="email" name="email" value={this.state.email} onChange={this.handleChange} placeholder={this.props.contaktiChat.translations.user_dashboard.messageemail_chat} className="form-control callback-control" id="messagebox-email" required={!(this.state.phone.length > 0)} />
            <br />
            <textarea name="message" value={this.state.message} onChange={this.handleChange} placeholder={this.props.contaktiChat.translations.user_dashboard.messagemsg_chat} className="form-control" rows="8" id="messagebox-message"></textarea>

          </div>
        </div>
          <div className="footer-sec">
            <div className="send-button-container pull-left">
              <button  type="submit" id="messagebox-send" className={`send ${(this.state.phone.length > 0 || this.state.email.length > 0)  ? "" : "disabled"}`} style={{backgroundColor: this.props.contaktiChat.color }} ><span className="fa fa-send"></span></button>
            </div>
            <div className="pull-right">
              Powered by <a href="http://contakti.com" target="_blank" rel="noreferrer" style={{position: "relative"}}>contakti.com</a>
              <div className="send-button-container pull-left">

              </div>
            </div>
          </div>
      </form>
      )}
      </div>

    );
  }
}

export default CallBackBox;