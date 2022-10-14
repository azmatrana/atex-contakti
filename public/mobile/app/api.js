define([
  "jquery",
  "durandal/app",
  "danthes",
  "models/user",
  "i18next"
], function ($,
             app,
             Danthes,
             User,
             i18n) {
  function Api() {
    $.support.cors = true;
    this.baseUrl = "/api/v1";
    this.skipErrorHandling = false;
    this.loadSession();
  }

  Api.prototype.resetSession = function (skip) {
    this.skipErrorHandling = true;
    var self = this;
    if (skip) {
      self.currentUser = null;
      try {
        window.localStorage.removeItem("current_user");
      } catch (e) {
      }
    } else {
      this.destroy("/sessions/" + this.currentUser.id);
      self.currentUser = null;
      try {
        window.localStorage.removeItem("current_user");
      } catch (e) {
      }
    }
  };

  Api.prototype.loadSession = function () {
    try {
      this.currentUser = new User(JSON.parse(window.localStorage.getItem("current_user")));
    } catch (e) {
      this.currentUser = null;
    }
  };

  Api.prototype.saveSession = function () {
    if (this.currentUser) {
      try {
        var userData = this.currentUser.getData();
        userData.media_channels = this.currentUser.mediaChannels;
        userData.service_channels = this.currentUser.serviceChannels;
        window.localStorage.setItem("current_user", JSON.stringify(userData));
      } catch (e) {
      }
    }
  };

  Api.prototype.beforeSend = function (jqXHR, settings) {
    if (this.currentUser) {
      jqXHR.setRequestHeader("X-Auth-Email", this.currentUser.email);
      jqXHR.setRequestHeader("X-Auth-Token", this.currentUser.token);
    }
  };

  Api.prototype.request = function (method, path, data) {
    this.stopConnectionCheck();
    var requestObject = {
      url: this.baseUrl + path,
      type: method,
      crossDomain: true,
      data: data || {},
      beforeSend: this.beforeSend.bind(this),
      success: this.onAjaxSuccess.bind(this),
      error: this.onAjaxError.bind(this),
      fail: this.onAjaxError.bind(this)
    };

    if (data && data.constructor.name === 'FormData') {
      requestObject['contentType'] = false;
      requestObject['processData'] = false;
      requestObject['cache'] = false;
      requestObject['enctype'] = 'multipart/form-data';

      this.formDataFileFix(data);
      requestObject['data'] = data;
    } else {
      requestObject['dataType'] = 'json';
    }
    return $.ajax(requestObject);
  };

  Api.prototype.onAjaxSuccess = function () {
    this.startConnectionCheck();
  };

  Api.prototype.onAjaxError = function (xhr, textStatus, errorThrown) {
    // console.log("Ajax error in api!");
    // console.log(a.statusText + ": " + a.state());
    if (this.skipErrorHandling) {
      return;
    }
    var self = this;
    xhr.statusCode({
      0: function () {
        // The connection is offline, cannot connect to the backend
        self.setApplicationOffline();
      },
      401: function () {
        // The backend session has most likely ended, unless it's
        // login request where this part is skipped
        if (self.currentUser) {
          self.resetSession(false);
          self.setApplicationOffline();
        }
      }
    });
  };

  Api.prototype.setApplicationOffline = function () {
    this.stopConnectionCheck();
    app.trigger("api:offline", false);
  };

  Api.prototype.startConnectionCheck = function () {
    // Check the connection every 5 minutes
    var self = this;
    var interval = 300000;
    this.stopConnectionCheck();
    this.connectionCheck = setTimeout(function () {
      self.checkSession().success(function () {
        self.startConnectionCheck();
      }).error(function () {
        self.setApplicationOffline();
      });
    }, interval);
  };

  Api.prototype.stopConnectionCheck = function () {
    clearTimeout(this.connectionCheck);
  };

  Api.prototype.checkSession = function () {
    return this.get('/sessions/check');
  };

  Api.prototype.get = function (path, data) {
    return this.request("GET", path, data);
  };

  Api.prototype.post = function (path, data) {
    return this.request("POST", path, data);
  };

  Api.prototype.patch = function (path, data) {
    return this.request("PATCH", path, data);
  };

  Api.prototype.put = function (path, data) {
    return this.request("PUT", path, data);
  };

  Api.prototype.destroy = function (path, data) {
    return this.request("DELETE", path, data);
  };

  Api.prototype.login = function (email, password, remember_me) {
    var self = this;
    this.skipErrorHandling = true;

    return this.post(
      "/sessions",
      {
        user: {
          email: email,
          password: password,
          remember_me: remember_me
        }
      }
    ).then(function (user) {
      self.skipErrorHandling = false;
      self.currentUser = new User($.extend({email: email}, user));
      self.saveSession();
      return user;
    }).fail(function () {
      //console.log("Sign in failed", Array.prototype.slice.call(arguments));
    });
  };

  Api.prototype.reloadUserData = function () {
    var self = this;

    return this.get('/users').success(function (userData) {
      self.currentUser = new User($.extend({email: self.currentUser.email}, userData));
      self.saveSession();
    });
  };

  Api.prototype.updateUser = function (user, additionalData) {
    var self = this;
    var userData = user.getData();
    delete userData.id;
    delete userData.token;

    userData.password = additionalData.password;
    userData.password_confirmation = additionalData.passwordConfirmation;

    return this.put('/users/' + user.id, userData);
  };

  Api.prototype.tasks = function () {
    if (!this.currentUser)
      throw "Invalid operation: not signed in";

    return this.get("/tasks");
  };

  Api.prototype.readyTasks = function (offset) {
    if (!offset) {
      offset = 0;
    }
    if (!this.currentUser) {
      throw "Invalid operation: not signed in";
    }

    return this.get("/tasks/ready_tasks", {offset: offset});
  };

  Api.prototype.mediaChannels = function () {
    if (!this.currentUser)
      throw "Invalid operation: not signed in";

    return this.get("/media_channels");
  };

  Api.prototype.serviceChannels = function () {
    if (!this.currentUser)
      throw "Invalid operation: not signed in";

    return this.get("/service_channels");
  };

  Api.prototype.task_messages = function (taskId) {
    if (!this.currentUser)
      throw "Invalid operation: not signed in";

    return this.get("/tasks/" + taskId + "/messages");
  };

  Api.prototype.danthesSubscribeTasks = function (callback) {
    var self = this;
    Danthes.addOutgoingProperties({user_id: this.currentUser.id});
    $.each(this.currentUser.mediaChannels, function () {
      self
        .get('/tasks/danthes/' + this.id)
        .success(function (subscription) {
          Danthes.sign($.extend(subscription, {
            callback: function (data) {
              callback(data);
            },
            connect: true,
          }));
        });
    });
  };

  Api.prototype.danthesSubscribeUser = function (userId, callback) {

  };

  Api.prototype.tagList = function () {
    return this.get('/tags/company');
  };

  Api.prototype.formDataFileFix = function(formData) {
    try {
      if (formData.keys) {
        var formKeysToBeRemoved = [];
        for (var key of formData.keys()) {
          if (key.match(/\[\]/)) {
            // var files = formData.get(key);
            // var files1 = formData.getAll(key);
          } else {
            var fileName = null || formData.get(key)['name'];
            var fileSize = null || formData.get(key)['size'];
            if (fileName != null && fileSize != null && fileName == '' && fileSize == 0) {
              formKeysToBeRemoved.push(key);
            }
          }
        }
        for (var i = 0; i < formKeysToBeRemoved.length; i++) {
          formData.delete(formKeysToBeRemoved[i]);
        }
      }
    }
    catch(err) {
      console.log(err.message);
    }
  };

  return new Api();
});
