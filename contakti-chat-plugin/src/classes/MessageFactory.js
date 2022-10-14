const ChatMessage = function() {

};

ChatMessage.prototype.asJSON = function() {
    return JSON.stringify(this);
};
const ChatMessageFactory = function(options) {
    this.from = options.username;
    this.channel = options.channel;
    this.type = 'message';

};

ChatMessageFactory.prototype.initialise = function() {

}
ChatMessageFactory.prototype.newMessage = function(message, type, chatBot = false, from) {
    var msg = new ChatMessage();
    msg.from = from || this.from;
    msg.channel_id = this.channel;
    msg.type = type || this.type;
    msg.chatbot = chatBot;
    msg.message = message;
    return msg;
};

ChatMessageFactory.prototype.quitMessage = function() {
    var msg = new ChatMessage();
    msg.from = this.from;
    msg.channel_id = this.channel;
    msg.type = 'quit';
    msg.message = 'Quitting.';
    return msg;
};

ChatMessageFactory.prototype.botToHumanSwitchMessage = function() {
    var msg = new ChatMessage();
    msg.from = this.from;
    msg.channel_id = this.channel;
    msg.type = 'botToHuman';
    msg.message = 'Requesting human..';
    return msg;
};


ChatMessageFactory.prototype.fileMessage = function(file_url, file_path) {
    var msg = new ChatMessage();
    msg.from = this.from;
    msg.channel_id = this.channel;
    msg.type = 'file';
    msg.message = file_url;
    msg.file_path = file_path;
    return msg;
};


export default ChatMessageFactory