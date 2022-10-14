

ContaktiChat.ChatMessageFactory = function(options) {
  this.from = options.username;
  this.channel = options.channel;
  this.type = 'message';
};

ContaktiChat.ChatMessageFactory.prototype.newMessage = function(message, type) {
  var msg = new ContaktiChat.ChatMessage();
  msg.from = this.from;
  msg.channel_id = this.channel;
  msg.type = type || this.type;
  msg.chatbot = !ContaktiChat.chatWithHuman;
  msg.message = message;
  return msg;
};

ContaktiChat.ChatMessageFactory.prototype.quitMessage = function() {
  var msg = new ContaktiChat.ChatMessage();
  msg.from = this.from;
  msg.channel_id = this.channel;
  msg.type = 'quit';
  msg.message = 'Quitting.';
  return msg;
};

ContaktiChat.ChatMessageFactory.prototype.botToHumanSwitchMessage = function() {
  var msg = new ContaktiChat.ChatMessage();
  msg.from = this.from;
  msg.channel_id = this.channel;
  msg.type = 'botToHuman';
  msg.message = 'Requesting human..';
  return msg;
};


ContaktiChat.ChatMessageFactory.prototype.fileMessage = function(file_url, file_path) {
  var msg = new ContaktiChat.ChatMessage();
  msg.from = this.from;
  msg.channel_id = this.channel;
  msg.type = 'file';
  msg.message = file_url;
  msg.file_path = file_path;
  return msg;
};

ContaktiChat.ChatMessage = function() {

};

ContaktiChat.ChatMessage.prototype.asJSON = function() {
  return JSON.stringify(this);
};
