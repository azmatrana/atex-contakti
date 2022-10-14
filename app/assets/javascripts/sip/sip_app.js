/* globals SIP,user,moment, Stopwatch */

var ctxSip;

// $(document).ready(function() {
function SipClient(sipCredentials, options={}) {

    var user = {
        //  User Name
        "User" : sipCredentials.user_name,
        //  Password
        "Pass" : sipCredentials.password,
        //  Auth Realm
        "Realm"   : sipCredentials.domain,
        // Display Name
        "Display" : sipCredentials.title,
        // WebSocket URL
        "WSServer"  : sipCredentials.ws_server_url
    }

    ctxSip = {

        config : {
            media : {
                remote : {
                    video: document.getElementById('audioRemote'),
                    audio: document.getElementById('audioRemote')
                }
            },
            peerConnectionOptions : {
                rtcConfiguration : {
                    iceServers : [{urls:"stun:stun.l.google.com:19302"}]
                }
            },
            password        : user.Pass,
            authorizationUser: user.User,
            displayName     : user.Display,
            uri             : user.User +'@'+user.Realm,
            transportOptions: {
                traceSip: true,
                wsServers:  user.WSServer,
            },
            registerExpires : 30,
            ua: {}
        },
        ringtone     : document.getElementById('ringtone'),
        ringbacktone : document.getElementById('ringbacktone'),
        dtmfTone0    : document.getElementById('dtmfTone0'),
        dtmfTone1    : document.getElementById('dtmfTone1'),
        dtmfTone2    : document.getElementById('dtmfTone2'),
        dtmfTone3    : document.getElementById('dtmfTone3'),
        dtmfTone4    : document.getElementById('dtmfTone4'),
        dtmfTone5    : document.getElementById('dtmfTone5'),
        dtmfTone6    : document.getElementById('dtmfTone6'),
        dtmfTone7    : document.getElementById('dtmfTone7'),
        dtmfTone8    : document.getElementById('dtmfTone8'),
        dtmfTone9    : document.getElementById('dtmfTone9'),
        dtmfToneHash : document.getElementById('dtmfToneHash'),
        dtmfToneStar : document.getElementById('dtmfToneStar'),

        Sessions     : [],
        callTimers   : {},
        callActiveID : null,
        callVolume   : 1,
        Stream       : null,

        sourceId     : null,
        sourceType   : null,
        lastCalledNumber: '',

        /**
         * Parses a SIP uri and returns a formatted US phone number.
         *
         * @param  {string} phone number or uri to format
         * @return {string}       formatted number
         */
        formatPhone : function(phone) {

            var num;

            if (phone.indexOf('@')) {
                num =  phone.split('@')[0];
            } else {
                num = phone;
            }

            num = num.toString().replace(/[^0-9]/g, '');

            if (num.length === 10) {
                return '' + num.substr(0, 3) + '' + num.substr(3, 3) + '' + num.substr(6,4);
            } else if (num.length === 12) {
                return '+' + num.substr(0, 3) + '' + num.substr(3, 3) + '' + num.substr(6, 6);
            } else {
                return num;
            }
        },

        // Sound methods
        startRingTone : function() {
            try { ctxSip.ringtone.play(); } catch (e) { }
        },

        stopRingTone : function() {
            try { ctxSip.ringtone.pause(); } catch (e) { }
        },

        startRingbackTone : function() {
            try { ctxSip.ringbacktone.play(); } catch (e) { }
        },

        stopRingbackTone : function() {
            try { ctxSip.ringbacktone.pause(); } catch (e) { }
        },

        // Genereates a rendom string to ID a call
        getUniqueID : function() {
            return Math.random().toString(36).substr(2, 9);
        },

        newSession : function(newSess) {
            newSess.displayName = newSess.remoteIdentity.displayName || newSess.remoteIdentity.uri.user;
            newSess.ctxid       = ctxSip.getUniqueID();
            var status;

            ctxSip.lastCalledNumber = newSess.remoteIdentity.uri.user;
            if (newSess.direction === 'incoming') {
                status = ""+ newSess.displayName;
                ctxSip.startRingTone();

            } else {
                status = "Soitetaan: "+ newSess.displayName;
                ctxSip.startRingbackTone();
            }

            ctxSip.logCall(newSess, 'ringing');

            ctxSip.setCallSessionStatus(status);

            // EVENT CALLBACKS
            var remoteVideo = document.getElementById('audioRemote');
            var localVideo = document.getElementById('audioRemote');



            newSess.on('trackAdded', function() {
                // We need to check the peer connection to determine which track was added

                var pc = newSess.sessionDescriptionHandler.peerConnection;

                // Gets remote tracks
                var remoteStream = new MediaStream();
                pc.getReceivers().forEach(function(receiver) {
                  remoteStream.addTrack(receiver.track);
                });
                remoteVideo.srcObject = remoteStream;
                remoteVideo.play();

              });

            newSess.on('progress',function(e) {
                if (e.direction === 'outgoing') {
                    ctxSip.setCallSessionStatus('');
                }
                ctxSip.saveCallStatus(newSess);
            });

            newSess.on('connecting',function(e) {
                if (e.direction === 'outgoing') {
                    ctxSip.setCallSessionStatus('');
                }
                ctxSip.saveCallStatus(newSess);
            });

            newSess.on('accepted',function(e) {
                // If there is another active call, hold it
                if (ctxSip.callActiveID && ctxSip.callActiveID !== newSess.ctxid) {
                    ctxSip.phoneHoldButtonPressed(ctxSip.callActiveID);
                }
                
                try {
                    // track time of the incoming user number
                    let nameNumber = newSess.displayName;
                    nameNumber = nameNumber.substring(0, nameNumber.indexOf(':'))
                    window.timeTrackerView.startTrackerForContactCustomer(nameNumber)
                }
                catch(err) {
                  console.log("call track error")
                  console.log(err)
                }
                ctxSip.stopRingbackTone();
                ctxSip.stopRingTone();
                ctxSip.setCallSessionStatus('');
                ctxSip.logCall(newSess, 'answered');
                ctxSip.callActiveID = newSess.ctxid;

                ctxSip.saveCallStatus(newSess);
            });

            newSess.on('hold', function(e) {
                ctxSip.callActiveID = null;
                ctxSip.logCall(newSess, 'holding');
                ctxSip.setCallSessionStatus("");
                ctxSip.saveCallStatus(newSess);
            });

            newSess.on('unhold', function(e) {
                ctxSip.logCall(newSess, 'resumed');
                ctxSip.callActiveID = newSess.ctxid;
                ctxSip.setCallSessionStatus("");
                ctxSip.saveCallStatus(newSess);
            });

            newSess.on('muted', function(e) {
                ctxSip.Sessions[newSess.ctxid].isMuted = true;
                ctxSip.setCallSessionStatus("");
                ctxSip.saveCallStatus(newSess);
            });

            newSess.on('unmuted', function(e) {
                ctxSip.Sessions[newSess.ctxid].isMuted = false;
                ctxSip.setCallSessionStatus("");
                ctxSip.saveCallStatus(newSess);
            });

            newSess.on('cancel', function(e) {
                ctxSip.stopRingTone();
                ctxSip.stopRingbackTone();
                ctxSip.setCallSessionStatus("");
                if (this.direction === 'outgoing') {
                    ctxSip.callActiveID = null;
                    newSess             = null;
                    ctxSip.logCall(this, 'ended');
                }
                ctxSip.saveCallStatus(newSess);
            });

            newSess.on('bye', function(e) {
                ctxSip.stopRingTone();
                ctxSip.stopRingbackTone();
                ctxSip.setCallSessionStatus("");
                ctxSip.logCall(newSess, 'ended');
                ctxSip.callActiveID = null;
                newSess             = null;
                ctxSip.saveCallStatus(newSess);
            });

            newSess.on('failed',function(e) {
                ctxSip.stopRingTone();
                ctxSip.stopRingbackTone();
                ctxSip.setCallSessionStatus('');
                ctxSip.saveCallStatus(newSess);
            });

            newSess.on('rejected',function(e) {
                ctxSip.stopRingTone();
                ctxSip.stopRingbackTone();
                ctxSip.setCallSessionStatus('');
                ctxSip.callActiveID = null;
                ctxSip.logCall(this, 'ended');
                ctxSip.saveCallStatus(newSess);
                newSess             = null;
            });

            ctxSip.Sessions[newSess.ctxid] = newSess;
            ctxSip.saveCallStatus(newSess)

        },

        saveCallStatus : (session) =>
        {
            if (session === null)
            {
              ctxSip.callApiToUpdateStatus(false)
            }
            else{
              ctxSip.callApiToUpdateStatus(true)
            }
        },

        callApiToUpdateStatus: function(status=false)
        {
          if (ctxSip.timeout_change_in_call_status) clearTimeout(ctxSip.timeout_change_in_call_status);
          ctxSip.timeout_change_in_call_status = setTimeout(function(){ options.change_in_call_status(status, ctxSip.lastCalledNumber) }, 500);
        },

        // getUser media request refused or device was not present
        getUserMediaFailure : function(e) {
            window.console.error('getUserMedia failed:', e);
            ctxSip.setError(true, '', true);
        },

        getUserMediaSuccess : function(stream) {
             ctxSip.Stream = stream;
        },

        /**
         * sets the ui call status field
         *
         * @param {string} status
         */
        setCallSessionStatus : function(status) {
            $('#txtCallStatus').html(status);
        },

        /**
         * sets the ui connection status field
         *
         * @param {string} status
         */
        setStatus : function(status) {
            $("#txtRegStatus").html(''+status);
        },

        /**
         * logs a call to localstorage
         *
         * @param  {object} session
         * @param  {string} status Enum 'ringing', 'answered', 'ended', 'holding', 'resumed'
         */
        logCall : function(session, status) {

            var log = {
                    clid : session.displayName,
                    uri  : session.remoteIdentity.uri.toString(),
                    id   : session.ctxid,
                    time : new Date().getTime()
                },
                calllog = options.call_logs();

            if (!calllog) { calllog = {}; }

            if (!calllog.hasOwnProperty(session.ctxid)) {
                calllog[log.id] = {
                    id    : log.id,
                    clid  : log.clid,
                    uri   : log.uri,
                    start : log.time,
                    flow  : session.direction
                };
            }

            if (status === 'ended') {
                calllog[log.id].stop = log.time;
            }

            if (status === 'ended' && calllog[log.id].status === 'ringing') {
                calllog[log.id].status = 'missed';
            } else {
                calllog[log.id].status = status;
            }

            options.call_logs(calllog);
            // localStorage.setItem('sipCalls', JSON.stringify(calllog));
            ctxSip.logShow();
            ctxSip.saveCallInApp(calllog[log.id]);
        },

        saveCallInApp: (call) =>
        {
          if (options.save_call_log_in_app)
          {
            callback = function(call_object){
              calllog = options.call_logs();
              if (!calllog) { calllog = {}; }
              if (calllog.hasOwnProperty(call.id)) {
                  calllog[call.id]['caller_name'] = call_object.caller_name;
                  calllog[call.id]['fonnecta_data'] = call_object.fonnecta_data;
              }
              options.call_logs(calllog);
              // localStorage.setItem('sipCalls', JSON.stringify(calllog));

              if (call_object.callable_id && call_object.callable_type == "CampaignItem" )
              {
                window.last_call_campaign_id = call_object.callable_id
              }
              ctxSip.logShow();
            }
            call.source_id = ctxSip.sourceId;
            call.source_type = ctxSip.sourceType;
            ctxSip.clearCallSource();
            options.save_call_log_in_app(call, callback);
          }
        },



        /**
         * adds a ui item to the call log
         *
         * @param  {object} item log item
         */
        logItem : function(item) {

            var callActive = (item.status !== 'ended' && item.status !== 'missed'),
                callLength = (item.status !== 'ended')? '<span id="'+item.id+'"></span>': moment.duration(item.stop - item.start).format("h [hrs], m [min] s [sec]"),
                callClass  = '',
                callIcon,
                i;

            var filter = localStorage.getItem('filter-calls')
            if (filter && filter !== 'all' && !['ringing', 'holding'].includes(item.status) )
            {
              if ( !((item.flow == 'outgoing' && filter === 'outbound' ) ||
                     (item.flow == 'incoming' && filter === 'inbound' ) ||
                      (item.status === 'missed' && filter === 'unanswered' ) ) )
              {
                return
              }
            }

            switch (item.status) {
                case 'ringing'  :
                    callClass = 'list-group-item-ringing';
                    callIcon  = 'fa-bell';
                    break;

                case 'missed'   :
                    callClass = 'list-group-item-missed';
                    if (item.flow === "incoming") { callIcon = 'fa-arrow-down'; }
                    if (item.flow === "outgoing") { callIcon = 'fa-arrow-up'; }
                    break;

                case 'holding'  :
                    callClass = 'list-group-item-warning';
                    callIcon  = 'fa-pause';
                    break;

                case 'answered' :
                case 'resumed'  :
                    callClass = 'list-group-item-aswered';
                    callIcon  = 'fa-phone-square';
                    break;

                case 'ended'  :
                    callClass = 'list-group-item-calls';
                    if (item.flow === "incoming") { callIcon = 'fa-arrow-down'; }
                    if (item.flow === "outgoing") { callIcon = 'fa-arrow-up'; }
                    break;
            }
            let missCallQty = item.missCallQty > 1 ? `<span style='margin-left:3px;'>(${item.missCallQty})</span>` : ''

            i  = '<div class="list-group-calls sip-logitem clearfix '+callClass+'" data-uri="'+item.uri+'" data-sessionid="'+item.id+'">';
            i += '<div class="clearfix"><div class="pull-left">';
            i += '<i class="fa fa-send send-message-to-log" data-contact='+ctxSip.formatPhone(item.uri)+'></i> <i class="fa fa-fw '+callIcon+' fa-fw"></i> <strong>'+ctxSip.formatPhone(item.uri) + missCallQty +'</strong><br>'+moment(item.start).format('DD MMMM YYYY - HH:mm')+'';
            i += '</div>';
            if (item.caller_name)
              i += '<div class="pull-right text-right"><strong>'+item.caller_name+'</strong><br>' + callLength+'</div></div>';
            else
            i += '<div class="pull-right text-right"><strong>'+item.clid+'</strong><br>' + callLength+'</div></div>';

            if (callActive) {
                i += '<div class="btn-group btn-group pull-right">';
                if (item.status === 'ringing' && item.flow === 'incoming') {
                    i += '<button class="btn btn-success btnCall"><i class="fa fa-phone"></i></button>';
                } else {
                    i += '<button class="btn btn-success btnHoldResume"><i class="fa fa-pause"></i></button>';
                    i += '<button class="btn btn-success btnTransfer"><i class="fa fa-random"></i></button>';
                }
                i += '<button class="btn btn-danger btnHangUp"><i class="fa fa-phone"></i></button>';
                i += '</div>';
            }
            i += '</div>';

            $('#sip-logitems #calls-list').append(i);


            // Start call timer on answer
            if (item.status === 'answered') {
                var tEle = document.getElementById(item.id);
                ctxSip.callTimers[item.id] = new Stopwatch(tEle);
                ctxSip.callTimers[item.id].start();
            }

            if (callActive && item.status !== 'ringing') {
                ctxSip.callTimers[item.id].start({startTime : item.start});
            }

            $('#sip-logitems #calls-list').scrollTop(0);
        },

        /**
         * updates the call log ui
         */
        logShow : function() {

            var calllog = options.call_logs(),
                x       = [];
            if (calllog !== null && !_.isEmpty(calllog)) {

                $('#sip-splash').addClass('hide');
                $('#sip-logitems #calls-list').removeClass('hide');

                // empty existing logs
                $('#sip-logitems #calls-list').empty();

                // JS doesn't guarantee property order so
                // create an array with the start time as
                // the key and sort by that.

                // Add start time to array
                $.each(calllog, function(k,v) {
                    x.push(v);
                });

                // sort descending
                x.sort(function(a, b) {
                    return b.start - a.start;
                });

               x = x.reduce((accum, val) => {
                  const dupeIndex = accum.findIndex(arrayItem => (ctxSip.formatPhone(arrayItem.uri) == ctxSip.formatPhone(val.uri) &&
                    arrayItem.status == 'missed' &&
                    arrayItem.flow == 'incoming' &&
                    arrayItem.flow == val.flow &&
                    arrayItem.status == val.status));

                  if (dupeIndex === -1) {
                    // Not found, so initialize.
                    accum.push({
                      missCallQty: 1,
                      ...val
                    });
                  } else {
                    // Found, so increment counter.
                    accum[dupeIndex].missCallQty++;
                  }
                  return accum;
              }, []);

                $.each(x, function(k, v) {
                    ctxSip.logItem(v);
                });

                let lastCall = x[0];
                if (lastCall.status == "answered" && lastCall.caller_name)
                {
                  let caller_details = '';
                  caller_details += `<p> ${lastCall.caller_name}</p>`
                  caller_details += `<p> ${ctxSip.formatPhone(lastCall.uri)}</p>`
                  if (lastCall.fonnecta_data)
                  {
                    caller_details += `<p> ${lastCall.fonnecta_data.street_address}</p>`
                    caller_details += `<p> ${lastCall.fonnecta_data.post_office}</p>`
                    caller_details += `<p> ${lastCall.fonnecta_data.postal_code}</p>`
                    caller_details += `<p> ${lastCall.fonnecta_data.city_name}</p>`
                  }
                  window.callDetailsData = caller_details;
                }

            } else {
                $('#sip-splash').removeClass('hide');
                $('#sip-logitems #calls-list').addClass('hide');
                // $('#sip-logitems').addClass('hide');

            }
        },

        /**
         * removes log items from localstorage and updates the UI
         */
        logClear : function() {
            options.deleteAllLogs()
            // localStorage.removeItem('sipCalls');
            ctxSip.logShow();
        },

        clearCallSource : function() {
          ctxSip.sourceId   = null;
          ctxSip.sourceType = null;
        },

        sipCall : function(target, callOptions={}) {
          ctxSip.clearCallSource();
          if (!_.isEmpty(callOptions) )
          {
            ctxSip.sourceId   = callOptions.sourceId
            ctxSip.sourceType = callOptions.sourceType
          }
          try {
            var s = ctxSip.phone.invite(target, {
              media : {
                remote : {
                  video: document.getElementById('audioRemote'),
                  audio: document.getElementById('audioRemote')
                }
              },
              sessionDescriptionHandlerOptions : {
                constraints : { audio : true, video : false },
                rtcConfiguration : { RTCConstraints : { "optional": [{ 'DtlsSrtpKeyAgreement': 'true'} ]}, stream      : ctxSip.Stream }

              }
            });
            s.direction = 'outgoing';
            ctxSip.newSession(s);

            var remoteVideo = document.getElementById('audioRemote');
            var localVideo = document.getElementById('audioRemote');



            s.on('trackAdded', function() {
              // We need to check the peer connection to determine which track was added

              var pc = s.sessionDescriptionHandler.peerConnection;

              // Gets remote tracks
              var remoteStream = new MediaStream();
              pc.getReceivers().forEach(function(receiver) {
                remoteStream.addTrack(receiver.track);
              });
              remoteVideo.srcObject = remoteStream;
              remoteVideo.play();
            });


          } catch(e) {
            throw(e);
          }
        },

        sipTransfer : function(sessionid) {

            var s      = ctxSip.Sessions[sessionid],
                target = window.prompt('Syötä numero johon puhelu siirretään.', '');

            ctxSip.setCallSessionStatus('');
            s.refer(target);
        },

        sipHangUp : function(sessionid) {

            var s = ctxSip.Sessions[sessionid];
            // s.terminate();
            if (!s) {
                return;
            } else if (s.startTime) {
                s.bye();
            } else if (s.reject) {
                s.reject();
            } else if (s.cancel) {
                s.cancel();
            }

        },

        sipSendDTMF : function(digit) {
          if (digit == '#')
          {
            try { eval(`ctxSip.dtmfToneHash`).play() } catch(e) { }
          }
          else if (digit == '*')
          {
            try { eval(`ctxSip.dtmfToneStar`).play() } catch(e) { }
          }
          else
          {
            try { eval(`ctxSip.dtmfTone${digit}`).play() } catch(e) { }
          }

          var a = ctxSip.callActiveID;
          if (a) {
              var s = ctxSip.Sessions[a];
              s.dtmf(digit);
          }
        },

        phoneCallButtonPressed : function(sessionid) {
            ctxSip.clearCallSource();
            var s      = ctxSip.Sessions[sessionid],
                target = $("#numDisplay").val().trim();
            if (!s) {

                $("#numDisplay").val("");
                ctxSip.sipCall(target);

            } else if (s.accept && !s.startTime) {

                s.accept({
                    media : {
                        remote : {
                            video: document.getElementById('audioRemote'),
                            audio: document.getElementById('audioRemote')
                        }
                    },
                    sessionDescriptionHandlerOptions : {
                        constraints : { audio : true, video : false },
                        rtcConfiguration : { RTCConstraints : { "optional": [{ 'DtlsSrtpKeyAgreement': 'true'} ]}, stream      : ctxSip.Stream }

                    }
                });
            }
        },

		phoneMuteButtonPressed : function (sessionid) {

            var s = ctxSip.Sessions[sessionid];

            if (!s.isMuted) {
                s.mute();
            } else {
                s.unmute();
            }
        },

        phoneHoldButtonPressed : function(sessionid) {

			var s = ctxSip.Sessions[sessionid];
			var direction = s.sessionDescriptionHandler.getDirection();

			if (direction === 'sendrecv') {
				console.log('');
				s.hold();
			} else {
				console.log('');
				s.unhold();
			}
        },


        setError : function(err, title, msg, closable=true) {

            // Show modal if err = true
            if (err === true) {
                $("#mdlError p").html(msg);
                $("#mdlError").modal('show');

                if (closable) {
                    var b = '<button type="button" class="close" data-dismiss="modal">&times;</button>';
                    $("#mdlError .modal-header").find('button').remove();
                    $("#mdlError .modal-header").prepend(b);
                    $("#mdlError .modal-title").html(title);
                    $("#mdlError").modal({ keyboard : true });
                } else {
                    $("#mdlError .modal-header").find('button').remove();
                    $("#mdlError .modal-title").html(title);
                    $("#mdlError").modal({ keyboard : false });
                }
             //   $('#numDisplay').prop('disabled', 'disabled');
            } else {
                $('#numDisplay').removeProp('disabled');
                $("#mdlError").modal('hide');
            }
        },

        /**
         * Tests for a capable browser, return bool, and shows an
         * error modal on fail.
         */
        hasWebRTC : function() {

            if (navigator.webkitGetUserMedia) {
                return true;
            } else if (navigator.mozGetUserMedia) {
                return true;
            } else if (navigator.getUserMedia) {
                return true;
            } else {
                ctxSip.setError(true, 'Käyttämäsi selain ei tule WebRTC toiminnetta.');
                window.console.error("");
                return false;
            }
        }
    };



    // Throw an error if the browser can't hack it.
    if (!ctxSip.hasWebRTC()) {
        return true;
    }

    ctxSip.phone = new SIP.UA(ctxSip.config);

    localStorage.setItem('filter-calls', 'all');
    ctxSip.phone.on('connected', function(e) {
        ctxSip.setStatus("Connected");
        ctxSip.setError(false)
    });

    ctxSip.phone.on('disconnected', function(e) {
        ctxSip.setStatus("");

        // disable phone
        ctxSip.setError(true, '');

    });

    ctxSip.phone.on('registered', function(e) {
        // alert('registered phone')
        ctxSip.setError(false)
        var closeEditorWarning = function() {
            return '';
        };

        var closePhone = function() {
            // stop the phone on unload
            localStorage.removeItem('ctxPhone');
            ctxSip.phone.stop();
        };


        // window.onbeforeunload = closeEditorWarning; // for displaying "Changes you made may not be saved" pop-up window
        window.onunload       = closePhone;

        // This key is set to prevent multiple windows.
        localStorage.setItem('ctxPhone', 'true');

        $("#mldError").modal('hide');
        ctxSip.setStatus("");


        // Get the userMedia and cache the stream
    //    if (SIP.WebRTC.isSupported()) {
    //        SIP.WebRTC.getUserMedia({ audio : true, video : false }, ctxSip.getUserMediaSuccess, ctxSip.getUserMediaFailure);
    //    }
    });

    ctxSip.phone.on('registrationFailed', function(e) {
        // ctxSip.setError(false, '', "registrationFailed");
        ctxSip.setStatus("");
        options.change_in_call_status(false)
    });

    ctxSip.phone.on('unregistered', function(e) {
        // ctxSip.setError(false, '', "unregistered");
        ctxSip.setStatus("");
        options.change_in_call_status(false)
    });

    window.ctxSip = ctxSip;

    ctxSip.phone.on('invite',

    function (incomingSession) {

        var s = incomingSession;

        s.direction = 'incoming';
       ctxSip.newSession(s);


    },);

    // Auto-focus number input on backspace.
    $('#sipClient').keydown(function(event) {
        if (event.which === 8) {
            $('#numDisplay').focus();
        }
    });

    $('#numDisplay').keypress(function(e) {
        // Enter pressed? so Dial.
        if (e.which === 13) {
            ctxSip.phoneCallButtonPressed();
        }
    });


    $('#phoneIcon').click(function(event) {
        // Enter pressed? so Dial.
        event.preventDefault();
        ctxSip.phoneCallButtonPressed();
    });


    $('.digit').click(function(event) {
        event.preventDefault();
        var num = $('#numDisplay').val(),
            dig = $(this).data('digit');

        $('#numDisplay').val(num+dig);
        ctxSip.sipSendDTMF(String(dig));
        return false;
    });

    $('#phoneUI .dropdown-menu').click(function(e) {
        e.preventDefault();
    });

    $('#phoneUI').delegate('.btnCall', 'click', function(event) {
        ctxSip.phoneCallButtonPressed();
        // to close the dropdown
        return true;
    });

    $('.sipLogClear').click(function(event) {
        event.preventDefault();
        ctxSip.logClear();
    });

    $('.filter-calls').click(function(event) {
        localStorage.setItem('filter-calls', event.target.dataset.filterCalls);
        $(".btn-filter").removeClass("active")
        $(event.target).addClass("active")
        ctxSip.logShow();
    });

    $('#sip-logitems').delegate('.sip-logitem .btnCall', 'click', function(event) {
        var sessionid = $(this).closest('.sip-logitem').data('sessionid');
        ctxSip.phoneCallButtonPressed(sessionid);
        return false;
    });

    $('#sip-logitems').delegate('.sip-logitem .btnHoldResume', 'click', function(event) {
        var sessionid = $(this).closest('.sip-logitem').data('sessionid');
        ctxSip.phoneHoldButtonPressed(sessionid);
        return false;
    });

    $('#sip-logitems').delegate('.sip-logitem .btnHangUp', 'click', function(event) {
        var sessionid = $(this).closest('.sip-logitem').data('sessionid');
        ctxSip.sipHangUp(sessionid);
        return false;
    });

    $('#sip-logitems').delegate('.sip-logitem .btnTransfer', 'click', function(event) {
        var sessionid = $(this).closest('.sip-logitem').data('sessionid');
        ctxSip.sipTransfer(sessionid);
        return false;
    });

    $('#sip-logitems').delegate('.sip-logitem .btnMute', 'click', function(event) {
        var sessionid = $(this).closest('.sip-logitem').data('sessionid');
        ctxSip.phoneMuteButtonPressed(sessionid);
        return false;
    });

    $('#sip-logitems').delegate('.send-message-to-log', 'click', function(event) {
        event.preventDefault();
        var number = $(this).data('contact');
        $(".sms-tab").click();
        $("#new_sms_link").click();
        $("#reply_from").val(number);
    });

    $('#sip-logitems').delegate('.sip-logitem', 'dblclick', function(event) {
        event.preventDefault();

        var uri = $(this).data('uri');
        $('#numDisplay').val(uri);
        ctxSip.phoneCallButtonPressed();
    });

    $('#sldVolume').on('change', function() {

        var v      = $(this).val() / 100,
            // player = $('audio').get()[0],
            btn    = $('#btnVol'),
            icon   = $('#btnVol').find('i'),
            active = ctxSip.callActiveID;

        // Set the object and media stream volumes
        if (ctxSip.Sessions[active]) {
            ctxSip.Sessions[active].player.volume = v;
            ctxSip.callVolume                     = v;
        }

        // Set the others
        $('audio').each(function() {
            $(this).get()[0].volume = v;
        });

        if (v < 0.1) {
            btn.removeClass(function (index, css) {
                   return (css.match (/(^|\s)btn\S+/g) || []).join(' ');
                })
                .addClass('btn btn-sm btn-danger');
            icon.removeClass().addClass('fa fa-fw fa-volume-off');
        } else if (v < 0.8) {
            btn.removeClass(function (index, css) {
                   return (css.match (/(^|\s)btn\S+/g) || []).join(' ');
               }).addClass('btn btn-sm btn-info');
            icon.removeClass().addClass('fa fa-fw fa-volume-down');
        } else {
            btn.removeClass(function (index, css) {
                   return (css.match (/(^|\s)btn\S+/g) || []).join(' ');
               }).addClass('btn btn-sm btn-primary');
            icon.removeClass().addClass('fa fa-fw fa-volume-up');
        }
        return false;
    });

    // Hide the spalsh after 3 secs.
    setTimeout(function() {
        ctxSip.logShow();
    }, 3000);


    /**
     * Stopwatch object used for call timers
     *
     * @param {dom element} elem
     * @param {[object]} options
     */
    var Stopwatch = function(elem, options) {

        // private functions
        function createTimer() {
            return document.createElement("span");
        }

        var timer = createTimer(),
            offset,
            clock,
            interval;

        // default options
        options           = options || {};
        options.delay     = options.delay || 1000;
        options.startTime = options.startTime || Date.now();

        // append elements
        elem.appendChild(timer);

        function start() {
            if (!interval) {
                offset   = options.startTime;
                interval = setInterval(update, options.delay);
            }
        }

        function stop() {
            if (interval) {
                clearInterval(interval);
                interval = null;
            }
        }

        function reset() {
            clock = 0;
            render();
        }

        function update() {
            clock += delta();
            render();
        }

        function render() {
            timer.innerHTML = moment(clock).format('mm:ss');
        }

        function delta() {
            var now = Date.now(),
                d   = now - offset;

            offset = now;
            return d;
        }

        // initialize
        reset();

        // public API
        this.start = start; //function() { start; }
        this.stop  = stop; //function() { stop; }
    };

};
