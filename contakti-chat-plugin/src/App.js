import React, { Component } from 'react';
import 'bootstrap/dist/css/bootstrap.min.css';
// import 'bootstrap/dist/css/bootstrap.min.css';

import './App.scss';
import './components/chat_plugin/ChatPlugin'
import ChatPlugin from './components/chat_plugin/ChatPlugin';


class App extends Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  render() {
    return (
      <ChatPlugin />
    );
  }
}

export default App;

