(function() {
  var Danthes,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  window.Danthes = Danthes = (function() {
    function Danthes() {}

    Danthes.debug = false;

    Danthes.debugMessage = function(message) {
      if (this.debug) {
        return console.log(message);
      }
    };

    Danthes.reset = function() {
      this.incomingProperties = {};
      this.outgoingProperties = {};
      this.connecting = false;
      this.fayeClient = null;
      this.fayeCallbacks = [];
      this.subscriptions = {};
      this.server = null;
      this.disables = [];
      this.connectionSettings = {
        timeout: 120,
        retry: 5,
        endpoints: {}
      };
    };

    Danthes.addIncomingProperties = function(properties) {
      var key, _results;
      if (typeof properties === "object") {
        _results = [];
        for (key in properties) {
          _results.push(Danthes.incomingProperties[key] = properties[key]);
        }
        return _results;
      }
    };

    Danthes.addOutgoingProperties = function(properties) {
      var key, _results;
      if (typeof properties === "object") {
        _results = [];
        for (key in properties) {
          _results.push(Danthes.outgoingProperties[key] = properties[key]);
        }
        return _results;
      }
    };

    Danthes.removeIncomingProperty = function(property) {
      if (typeof property === "string") {
        return delete Danthes.incomingProperties[property];
      }
    };

    Danthes.removeOutgoingProperty = function(property) {
      if (typeof property === "string") {
        return delete Danthes.outgoingProperties[property];
      }
    };

    Danthes.getIncomingPropertues = function() {
      return Danthes.incomingProperties;
    };

    Danthes.getOutgoingProperties = function() {
      return Danthes.outgoingProperties;
    };

    Danthes.clearIncomingProperties = function() {
      return Danthes.incomingProperties = {};
    };

    Danthes.clearOutgoingProperties = function() {
      return Danthes.outgoingProperties = {};
    };

    Danthes.faye = function(callback) {
      var complete, script;
      if (Danthes.fayeClient != null) {
        return callback(Danthes.fayeClient);
      } else {
        Danthes.fayeCallbacks.push(callback);
        if (Danthes.server && !Danthes.connecting) {
          Danthes.connecting = true;
          if (typeof Faye === "undefined" || Faye === null) {
            script = document.createElement('script');
            script.type = 'text/javascript';
            script.src = "" + Danthes.server + "/client.js";
            script.id = "faye-connection-script";
            complete = false;
            script.onload = script.onreadystatechange = function() {
              if (!complete && (!script.readyState || script.readyState === "loaded" || script.readyState === "complete")) {
                complete = true;
                script.onload = script.onreadystatechange = null;
                Danthes.debugMessage('connect to faye after script loaded');
                return Danthes.connectToFaye();
              }
            };
            Danthes.debugMessage('faye script init');
            return document.documentElement.appendChild(script);
          }
        } else {
          Danthes.debugMessage('faye already inited');
          return Danthes.connectToFaye();
        }
      }
    };

    Danthes.fayeExtension = {
      incoming: function(message, callback) {
        var key;
        for (key in Danthes.incomingProperties) {
          message[key] = Danthes.incomingProperties[key];
        }
        Danthes.debugMessage("incoming message " + (JSON.stringify(message)));
        return callback(message);
      },
      outgoing: function(message, callback) {
        var key, subscription;
        if (message.channel === "/meta/subscribe") {
          subscription = Danthes.subscriptions[message.subscription]['opts'];
          if (message.ext == null) {
            message.ext = {};
          }
          message.ext.danthes_signature = subscription.signature;
          message.ext.danthes_timestamp = subscription.timestamp;
        }
        for (key in Danthes.outgoingProperties) {
          message[key] = Danthes.outgoingProperties[key];
        }
        Danthes.debugMessage("outgoing message " + (JSON.stringify(message)));
        return callback(message);
      }
    };

    Danthes.connectToFaye = function() {
      var callback, key, _i, _j, _len, _len1, _ref, _ref1, _results;
      if (this.server && (typeof Faye !== "undefined" && Faye !== null)) {
        this.debugMessage('trying to connect faye');
        this.fayeClient = new Faye.Client(this.server, this.connectionSettings);
        this.fayeClient.addExtension(this.fayeExtension);
        _ref = this.disables;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          key = _ref[_i];
          this.fayeClient.disable(key);
        }
        this.debugMessage('faye connected');
        _ref1 = this.fayeCallbacks;
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          callback = _ref1[_j];
          _results.push(callback(this.fayeClient));
        }
        return _results;
      }
    };

    Danthes.sign = function(options) {
      var channel;
      this.debugMessage('sign to faye');
      if (!this.server) {
        this.server = options.server;
      }
      channel = options.channel;
      if (this.subscriptions[channel] == null) {
        this.subscriptions[channel] = {};
        if (options['callback'] != null) {
          this.subscriptions[channel]['callback'] = options['callback'];
        }
        this.subscriptions[channel]['opts'] = {
          signature: options['signature'],
          timestamp: options['timestamp']
        };
        if ((options['connect'] != null) || (options['error'] != null)) {
          return this.activateChannel(channel, options);
        }
      }
    };

    Danthes.activateChannel = function(channel, options) {
      if (options == null) {
        options = {};
      }
      if (this.subscriptions[channel]['activated']) {
        return true;
      }
      return this.faye((function(_this) {
        return function(faye) {
          var subscription;
          subscription = faye.subscribe(channel, function(message) {
            return _this.handleResponse(message);
          });
          if (subscription != null) {
            _this.subscriptions[channel]['sub'] = subscription;
            subscription.callback(function() {
              if (typeof options['connect'] === "function") {
                options['connect'](subscription);
              }
              return _this.debugMessage("subscription for " + channel + " is active now");
            });
            subscription.errback(function(error) {
              if (typeof options['error'] === "function") {
                options['error'](subscription, error);
              }
              return _this.debugMessage("error for " + channel + ": " + error.message);
            });
            return _this.subscriptions[channel]['activated'] = true;
          }
        };
      })(this));
    };

    Danthes.handleResponse = function(message) {
      var callback, channel;
      if (message["eval"]) {
        eval(message["eval"]);
      }
      channel = message.channel;
      if (this.subscriptions[channel] == null) {
        return;
      }
      if (callback = this.subscriptions[channel]['callback']) {
        return callback(message.data, channel);
      }
    };

    Danthes.disableTransport = function(transport) {
      if (transport !== 'websocket' && transport !== 'long-polling' && transport !== 'callback-polling' && transport !== 'in-process') {
        return;
      }
      if (__indexOf.call(this.disables, transport) < 0) {
        this.disables.push(transport);
        this.debugMessage("" + transport + " faye transport will be disabled");
      }
      return true;
    };

    Danthes.subscribe = function(channel, callback, options) {
      if (options == null) {
        options = {};
      }
      this.debugMessage("subscribing to " + channel);
      if (this.subscriptions[channel] != null) {
        this.activateChannel(channel, options);
        this.subscriptions[channel]['callback'] = callback;
      } else {
        this.debugMessage("Cannot subscribe on channel '" + channel + "'. You need sign to channel first.");
        return false;
      }
      return true;
    };

    Danthes.unsubscribe = function(channel, fullUnsubscribe) {
      if (fullUnsubscribe == null) {
        fullUnsubscribe = false;
      }
      this.debugMessage("unsubscribing from " + channel);
      if (this.subscriptions[channel] && this.subscriptions[channel]['activated']) {
        this.subscriptions[channel]['sub'].cancel();
        if (fullUnsubscribe) {
          return delete this.subscriptions[channel];
        } else {
          delete this.subscriptions[channel]['activated'];
          return delete this.subscriptions[channel]['sub'];
        }
      }
    };

    Danthes.unsubscribeAll = function() {
      var channel, _, _ref, _results;
      _ref = this.subscriptions;
      _results = [];
      for (channel in _ref) {
        _ = _ref[channel];
        _results.push(this.unsubscribe(channel));
      }
      return _results;
    };

    return Danthes;

  })();

  window.Danthes.reset();

}).call(this);
