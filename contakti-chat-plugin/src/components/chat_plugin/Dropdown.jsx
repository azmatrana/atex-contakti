import React, { Component } from 'react';

class Dropdown extends Component {
  constructor(props) {
    super(props);
    this.state = {
      expanded: false,
      showSendEmail: true,
      showStart: false,
      showEndChat: true,
    }
  }


  // document.onclick = (event){
  // 	if(!event.target.classList.contains('dropdown-toggle') && !event.target.classList.contains('fa-cog')){
  // 		if(document.querySelector('.dropdown')){
  // 			document.querySelector('.dropdown').classList.remove("open");
  // 		}
  // 	}
  // }

  toggle_dropdown = (e) => {
    // ele.parentElement.classList.remove("close-force");
    // e.target.parentNode.classList.toggle("open");
    this.setState({ expanded: !this.state.expanded });
  }
   mouseover = (e) => {
    e.target.style.color = this.props.styleObj.color;
    e.target.style.backgroundColor = this.props.styleObj.backgroundColor;
  }
  mouseout = (e) => {
    e.target.style.color = this.props.styleObj.backgroundColor;
    e.target.style.backgroundColor = this.props.styleObj.color;
  }

  end = () => {
    this.props.quit();
    this.setState({showEndChat: false});
  }

  sendchatHistory = () =>{
    this.toggle_dropdown();
    this.props.sendChatHistory();
    this.setState({showSendEmail: false, showStart: true});
  }

  startChat =  async() =>{
    this.setState({showStart: false});
    await this.props.quit();
    await this.props.startChat();
  }

  downloadChat = () => {
    this.props.downloadChatHistory();
  }


  // mouseoverdownload(e) {
  //   var x = document.getElementById("download_chat_history");
  //   x.style.color = document.getElementById('contakti-user-name').style.color;
  //   x.style.backgroundColor = document.getElementById('contakti-msg-head').style.backgroundColor;
  // }

  // mouseoutdownload(e) {
  //   var x = document.getElementById("download_chat_history");
  //   x.style.color = document.getElementById('contakti-msg-head').style.backgroundColor;
  //   x.style.backgroundColor = document.getElementById('contakti-user-name').style.color;
  // }

  // mouseoversend(e) {
  //   var y = document.getElementById("send_chat_history");
  //   y.style.color = document.getElementById('contakti-user-name').style.color;
  //   y.style.backgroundColor = document.getElementById('contakti-msg-head').style.backgroundColor;
  // }

  // mouseoutsend(e) {
  //   var y = document.getElementById("send_chat_history");
  //   y.style.color = document.getElementById('contakti-msg-head').style.backgroundColor;
  //   y.style.backgroundColor = document.getElementById('contakti-user-name').style.color;
  // }

  // mouseovercancel(e) {
  //   var z = document.getElementById("contakti-msg-close-chat");
  //   z.style.color = document.getElementById('contakti-user-name').style.color;
  //   z.style.backgroundColor = document.getElementById('contakti-msg-head').style.backgroundColor;
  // }

  // mouseoutcancel(e) {
  //   var z = document.getElementById("contakti-msg-close-chat");
  //   z.style.color = document.getElementById('contakti-msg-head').style.backgroundColor;
  //   z.style.backgroundColor = document.getElementById('contakti-user-name').style.color;
  // }

  // mouseoverstart(e) {
  //   var z = document.getElementById("contakti-msg-start-chat");
  //   z.style.color = document.getElementById('contakti-user-name').style.color;
  //   z.style.backgroundColor = document.getElementById('contakti-msg-head').style.backgroundColor;
  // }

  // mouseoutstart(e) {
  //   var z = document.getElementById("contakti-msg-start-chat");
  //   z.style.color = document.getElementById('contakti-msg-head').style.backgroundColor;
  //   z.style.backgroundColor = document.getElementById('contakti-user-name').style.color;
  // }





  render() {
    const {translations} = this.props
    return (
      <div className="dropdown chat-setting d--inline-block" id="chat-setting-dropdown" >
        <button
         style={{ color: this.props.styleObj.color }}
          className="dropdown-toggle"
          onClick={this.toggle_dropdown}
        >
          <i className="fa fa-cog"></i></button>

        <ul className="chatsetting-dropdown-menu" hidden={this.state.expanded ? false : true } id="chat-setting-dropdown-menu">
          <li>
            <a id="download_chat_history" style={{color: this.props.styleObj.backgroundColor, backgroundColor: this.props.styleObj.color }} onClick={this.downloadChat}  onMouseOver={this.mouseover} onMouseOut={this.mouseout}>
             {translations.user_dashboard.download_txt_file}
            </a>
          </li>
          <li>
            <a id="send_chat_history" style={{ display:this.state.showSendEmail? "block": "none", color: this.props.styleObj.backgroundColor, backgroundColor: this.props.styleObj.color }} onClick={this.sendchatHistory} onMouseOver={this.mouseover} onMouseOut={this.mouseout}>
            {translations.user_dashboard.send_to_email}
            </a>
          </li>
          <li>
            <a id="contakti-msg-close-chat" onClick={this.end} style={{ display:this.state.showEndChat? "block": "none" , color: this.props.styleObj.backgroundColor, backgroundColor: this.props.styleObj.color }} onMouseOver={this.mouseover} onMouseOut={this.mouseout}>
            {translations.user_dashboard.end_chat}
            </a>
            <a id="contakti-msg-start-chat" style={{ display:this.state.showStart? "block": "none", color: this.props.styleObj.backgroundColor, backgroundColor: this.props.styleObj.color }} onClick={this.startChat} onMouseOver={this.mouseover} onMouseOut={this.mouseout}>
            {translations.user_dashboard.start_new_chat}
            </a>
          </li>
        </ul>
      </div>
    );
  }
}

export default Dropdown;