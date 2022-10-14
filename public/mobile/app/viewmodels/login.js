define([
  "durandal/app",
  "plugins/router",
  "knockout",
  "api",
  "appdata"
], function (app,
             router,
             ko,
             api,
             appdata) {
  return {
    activate: function () {
      if (api.currentUser) {
        router.navigate("tasks", {replace: true, trigger: true});
        return;
      }

      app.trigger("menu:toggle", false);
    },
    email: ko.observable(),
    password: ko.observable(),
    remember_me: ko.observable(true),
    submitting: ko.observable(false),
    submitLogin: function () {
      var self = this;

      this.submitting(true);
      console.log(this.remember_me());
      api
        .login(this.email(), this.password(), this.remember_me())
        .always(function () {
          self.submitting(false);
        })
        .done(function () {
          //app.showMessage(this.email() + ":" + this.password());
          appdata.loadData();
          router.navigate("tasks", {replace: true, trigger: true});
        });

      return false;
    }
  };
});
