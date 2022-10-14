

function CompletedCall(incoming, remote, duration) {
  var self = this;

  this.remote = remote;
  this.incoming = incoming;
  this.duration = duration;
  this.user_id = window.UserDashboard.currentUserId;
}
